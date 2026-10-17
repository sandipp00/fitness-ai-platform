import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reports the Android intent action the app was opened with, so Health
/// Connect's "why does this app need access?" links can show the privacy policy.
class LaunchActions {
  static const _channel = MethodChannel('kinetiq/launch');
  static final _actions = StreamController<String>.broadcast();

  static const _privacyActions = {
    'androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE',
    'android.intent.action.VIEW_PERMISSION_USAGE',
  };

  static bool isPrivacyAction(String? action) => _privacyActions.contains(action);

  static Stream<String> get actions => _actions.stream;

  static Future<String?> initialAction() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewAction' && call.arguments is String) {
        _actions.add(call.arguments as String);
      }
    });
    try {
      return await _channel.invokeMethod<String>('getLaunchAction');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
