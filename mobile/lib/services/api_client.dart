import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;

  const ApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000',
        );

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<String> login(String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/api/auth/login'), headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode != 200) throw ApiException(_message(response));
    return (jsonDecode(response.body) as Map<String, dynamic>)['access_token'] as String;
  }

  Future<String> register(String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/api/auth/register'), headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode != 200) throw ApiException(_message(response));
    return (jsonDecode(response.body) as Map<String, dynamic>)['access_token'] as String;
  }

  Future<Map<String, dynamic>> getProfile(String token) => _get('/api/users/me', token);
  Future<Map<String, dynamic>> getDashboard(String token) => _get('/api/dashboard', token);
  Future<Map<String, dynamic>> getRecommendations(String token) => _get('/api/ai/recommendations', token);
  Future<Map<String, dynamic>> getTrends(String token, {int days = 28}) => _get('/api/analytics/trends?days=$days', token);
  Future<Map<String, dynamic>> getWorkoutPlan(String token) => _get('/api/analytics/workout-plan', token);
  Future<Map<String, dynamic>> getPersonalization(String token) => _get('/api/analytics/personalization', token);
  Future<Map<String, dynamic>> getProgress(String token) => _get('/api/analytics/progress', token);

  Future<void> syncHealthData(String token, Map<String, dynamic> payload) async {
    final response = await http.post(Uri.parse('$baseUrl/api/health-data/sync'), headers: _headers(token), body: jsonEncode(payload));
    if (response.statusCode != 200) throw ApiException(_message(response));
  }

  Future<Map<String, dynamic>> chat(String token, String message) async {
    final response = await http.post(Uri.parse('$baseUrl/api/ai/chat'), headers: _headers(token), body: jsonEncode({'message': message}));
    if (response.statusCode != 200) throw ApiException(_message(response));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(String path, String token) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers(token));
    if (response.statusCode != 200) throw ApiException(_message(response));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _message(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) return body['detail'].toString();
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
