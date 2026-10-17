import 'package:flutter/foundation.dart';

/// Build-time configuration, supplied with `--dart-define`.
class AppConfig {
  const AppConfig._();

  static const appName = 'Kinetiq';

  /// Backend base URL. Release builds must use https.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Public URL of the hosted privacy policy (shown in-app and on the store).
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

  /// Contact address for privacy and support requests.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  /// Returns a human-readable problem if this build is misconfigured.
  static String? configurationError({bool releaseMode = kReleaseMode, String baseUrl = apiBaseUrl}) {
    if (releaseMode && !baseUrl.startsWith('https://')) {
      return 'This build was made without a secure API address. '
          'Rebuild with --dart-define=API_BASE_URL=https://your-api.example';
    }
    return null;
  }
}
