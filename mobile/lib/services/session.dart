import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where tokens are persisted. Swappable so tests can use memory.
abstract class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain (iOS) / Keystore-backed encrypted storage (Android).
class SecureTokenStore implements TokenStore {
  static const _storage = FlutterSecureStorage();

  const SecureTokenStore();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemoryTokenStore implements TokenStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class Session {
  final TokenStore store;

  const Session({this.store = const SecureTokenStore()});

  static const accessKey = 'access_token';
  static const refreshKey = 'refresh_token';

  Future<String?> getAccessToken() => store.read(accessKey);

  Future<String?> getRefreshToken() => store.read(refreshKey);

  Future<bool> isSignedIn() async => (await getRefreshToken()) != null;

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await store.write(accessKey, accessToken);
    await store.write(refreshKey, refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) => store.write(accessKey, accessToken);

  Future<void> clear() async {
    await store.delete(accessKey);
    await store.delete(refreshKey);
  }

  /// Older builds kept a short-lived access token in plain SharedPreferences.
  /// Remove it; it cannot be refreshed, so the user signs in once more.
  static Future<void> removeLegacyToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessKey);
  }
}
