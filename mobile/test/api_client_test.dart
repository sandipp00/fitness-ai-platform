import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kinetiq/services/api_client.dart';
import 'package:kinetiq/services/session.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryTokenStore store;
  late Session session;

  setUp(() {
    store = MemoryTokenStore();
    session = Session(store: store);
  });

  ApiClient client(MockClientHandler handler) =>
      ApiClient(baseUrl: 'https://api.test', session: session, httpClient: MockClient(handler));

  test('login stores both tokens', () async {
    final api = client((request) async {
      if (request.url.path == '/api/auth/login') {
        return _json({'access_token': 'a1', 'refresh_token': 'r1', 'token_type': 'bearer', 'expires_in': 1800});
      }
      return _json({}, 200); // timezone sync
    });

    await api.login('me@example.com', 'password123');
    expect(await session.getAccessToken(), 'a1');
    expect(await session.getRefreshToken(), 'r1');
  });

  test('expired access token is refreshed and the request retried', () async {
    await session.save(accessToken: 'old', refreshToken: 'r1');
    final seen = <String>[];
    final api = client((request) async {
      seen.add('${request.url.path} ${request.headers['Authorization'] ?? ''}');
      if (request.url.path == '/api/auth/refresh') {
        expect(jsonDecode(request.body), {'refresh_token': 'r1'});
        return _json({'access_token': 'new', 'refresh_token': 'r2', 'expires_in': 1800});
      }
      if (request.headers['Authorization'] == 'Bearer old') return _json({'detail': 'Invalid token'}, 401);
      return _json({'scores': {}});
    });

    final result = await api.getDashboard();
    expect(result, {'scores': {}});
    expect(seen, [
      '/api/dashboard Bearer old',
      '/api/auth/refresh ',
      '/api/dashboard Bearer new',
    ]);
    expect(await session.getRefreshToken(), 'r2');
  });

  test('concurrent 401s share a single refresh', () async {
    await session.save(accessToken: 'old', refreshToken: 'r1');
    var refreshes = 0;
    final api = client((request) async {
      if (request.url.path == '/api/auth/refresh') {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _json({'access_token': 'new', 'refresh_token': 'r2', 'expires_in': 1800});
      }
      if (request.headers['Authorization'] == 'Bearer old') return _json({'detail': 'Invalid token'}, 401);
      return _json({});
    });

    await Future.wait([api.getDashboard(), api.getTrends(), api.getProfile()]);
    expect(refreshes, 1);
  });

  test('rejected refresh clears the session and signals expiry', () async {
    await session.save(accessToken: 'old', refreshToken: 'revoked');
    final api = client((request) async => _json({'detail': 'Invalid token'}, 401));
    final expired = expectLater(ApiClient.sessionExpired.first, completes);

    await expectLater(api.getDashboard(), throwsA(isA<SessionExpiredException>()));
    await expired;
    expect(await session.isSignedIn(), isFalse);
  });

  test('validation errors become readable messages', () {
    final response = _json({
      'detail': [
        {'loc': ['body', 'password'], 'msg': 'String should have at least 8 characters', 'type': 'string_too_short'}
      ]
    }, 422);
    expect(ApiClient.errorMessage(response), 'Password: String should have at least 8 characters');
  });

  test('server errors do not leak raw bodies', () {
    expect(ApiClient.errorMessage(http.Response('<html>oops</html>', 502)),
        'Something went wrong on our side. Please try again in a moment.');
    expect(ApiClient.errorMessage(_json({'detail': 'Email already registered'}, 409)), 'Email already registered');
  });

  test('network failures are reported as connectivity errors', () async {
    await session.save(accessToken: 'a', refreshToken: 'r');
    final api = client((request) async => throw http.ClientException('Connection refused'));
    await expectLater(
      api.getDashboard(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains("Can't reach Kinetiq"))),
    );
  });

  test('requests time out instead of hanging', () async {
    await session.save(accessToken: 'a', refreshToken: 'r');
    final api = ApiClient(
      baseUrl: 'https://api.test',
      session: session,
      timeout: const Duration(milliseconds: 20),
      httpClient: MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return _json({});
      }),
    );
    await expectLater(
      api.getDashboard(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('too long'))),
    );
  });

  test('account deletion sends the password and signs out', () async {
    await session.save(accessToken: 'a', refreshToken: 'r');
    late http.Request sent;
    final api = client((request) async {
      sent = request;
      return http.Response('', 204);
    });

    await api.deleteAccount('password123');
    expect(sent.method, 'DELETE');
    expect(sent.url.path, '/api/users/me');
    expect(jsonDecode(sent.body), {'password': 'password123'});
    expect(await session.isSignedIn(), isFalse);
  });
}
