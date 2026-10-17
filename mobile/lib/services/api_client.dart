import 'dart:async';
import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'session.dart';

/// Talks to the Kinetiq API and owns the session tokens.
///
/// Access tokens are refreshed automatically. When the refresh token is no
/// longer accepted the session is cleared and [sessionExpired] fires so the
/// app can return to the sign-in screen.
class ApiClient {
  final String baseUrl;
  final Session session;
  final http.Client _http;
  final Duration timeout;

  ApiClient({
    String? baseUrl,
    Session? session,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        session = session ?? const Session(),
        _http = httpClient ?? http.Client();

  static final ApiClient shared = ApiClient();

  static final _sessionExpired = StreamController<void>.broadcast();
  static Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<bool>? _refreshing;

  // --- auth ------------------------------------------------------------

  Future<void> login(String email, String password) =>
      _authenticate('/api/auth/login', email, password);

  Future<void> register(String email, String password) =>
      _authenticate('/api/auth/register', email, password);

  Future<void> logout() => session.clear();

  /// Revokes every token issued to this account, on all devices.
  Future<void> logoutEverywhere() async {
    await _send('POST', '/api/auth/logout-all', expected: 204);
    await session.clear();
  }

  Future<void> deleteAccount(String password) async {
    await _send('DELETE', '/api/users/me', body: {'password': password}, expected: 204);
    await session.clear();
  }

  Future<void> _authenticate(String path, String email, String password) async {
    final response = await _send('POST', path, body: {'email': email, 'password': password}, auth: false);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await session.save(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
    );
    unawaited(syncTimezone());
  }

  /// Tells the API the device timezone so "today" matches the user's day.
  Future<void> syncTimezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      await updateTimezone(zone.identifier);
    } catch (_) {
      // Best effort: the server falls back to UTC.
    }
  }

  // --- data ------------------------------------------------------------

  Future<Map<String, dynamic>> getProfile() => _getJson('/api/users/me');
  Future<Map<String, dynamic>> getDashboard() => _getJson('/api/dashboard');
  Future<Map<String, dynamic>> getRecommendations() => _getJson('/api/ai/recommendations');
  Future<Map<String, dynamic>> getTrends({int days = 28}) => _getJson('/api/analytics/trends?days=$days');
  Future<Map<String, dynamic>> getWorkoutPlan() => _getJson('/api/analytics/workout-plan');
  Future<Map<String, dynamic>> getPersonalization() => _getJson('/api/analytics/personalization');

  Future<void> updateTimezone(String timezone) async {
    await _send('PUT', '/api/users/me/timezone', body: {'timezone': timezone});
  }

  Future<void> syncHealthData(Map<String, dynamic> payload) async {
    await _send('POST', '/api/health-data/sync', body: payload);
  }

  Future<Map<String, dynamic>> chat(String message) async {
    final response = await _send('POST', '/api/ai/chat', body: {'message': message});
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // --- transport -------------------------------------------------------

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _send('GET', path);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    int expected = 200,
  }) async {
    String? token;
    if (auth) {
      token = await session.getAccessToken() ?? await _refreshOrExpire();
    }

    var response = await _raw(method, path, body, token);
    if (auth && response.statusCode == 401) {
      token = await _refreshOrExpire();
      response = await _raw(method, path, body, token);
      if (response.statusCode == 401) {
        await _expire();
      }
    }
    if (response.statusCode != expected) throw ApiException(errorMessage(response));
    return response;
  }

  Future<String> _refreshOrExpire() async {
    // Share one refresh between concurrent requests.
    final ok = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    final token = ok ? await session.getAccessToken() : null;
    return token ?? await _expire();
  }

  Future<bool> _refresh() async {
    final refreshToken = await session.getRefreshToken();
    if (refreshToken == null) return false;
    final response = await _raw('POST', '/api/auth/refresh', {'refresh_token': refreshToken}, null);
    if (response.statusCode != 200) return false;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await session.save(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
    );
    return true;
  }

  Future<Never> _expire() async {
    await session.clear();
    _sessionExpired.add(null);
    throw const SessionExpiredException();
  }

  Future<http.Response> _raw(String method, String path, Object? body, String? token) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Kinetiq is taking too long to respond. Please try again.');
    } on http.ClientException {
      throw const ApiException("Can't reach Kinetiq. Check your internet connection and try again.");
    }
  }

  /// Turns an error response into a message suitable for the UI.
  static String errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final detail = body['detail'];
        if (detail is String) return detail;
        // FastAPI validation errors: [{"loc": [...], "msg": "..."}]
        if (detail is List && detail.isNotEmpty && detail.first is Map) {
          final first = detail.first as Map;
          final field = (first['loc'] is List && (first['loc'] as List).isNotEmpty)
              ? (first['loc'] as List).last.toString()
              : null;
          final msg = first['msg']?.toString().replaceFirst('Value error, ', '') ?? 'Invalid input';
          return field == null ? msg : '${_capitalize(field)}: $msg';
        }
      }
    } catch (_) {}
    if (response.statusCode >= 500) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    return 'Request failed (${response.statusCode})';
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class SessionExpiredException extends ApiException {
  const SessionExpiredException() : super('Your session has expired. Please sign in again.');
}
