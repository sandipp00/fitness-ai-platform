import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config.dart';
import 'services/api_client.dart';
import 'services/background_sync.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'services/launch_actions.dart';
import 'services/session.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configError = AppConfig.configurationError();
  if (configError != null) {
    runApp(ConfigErrorApp(message: configError));
    return;
  }

  await Session.removeLegacyToken();
  final signedIn = await const Session().isSignedIn();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await const BackgroundSync().initialize();
  }
  if (signedIn) unawaited(ApiClient.shared.syncTimezone());

  final launchAction = await LaunchActions.initialAction();
  runApp(KinetiqApp(
    isSignedIn: signedIn,
    showPrivacyPolicy: LaunchActions.isPrivacyAction(launchAction),
  ));
}

class KinetiqApp extends StatefulWidget {
  final bool isSignedIn;
  final bool showPrivacyPolicy;

  const KinetiqApp({super.key, required this.isSignedIn, this.showPrivacyPolicy = false});

  @override
  State<KinetiqApp> createState() => _KinetiqAppState();
}

class _KinetiqAppState extends State<KinetiqApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final _subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(ApiClient.sessionExpired.listen((_) => _returnToSignIn()));
    _subscriptions.add(LaunchActions.actions.listen((action) {
      if (LaunchActions.isPrivacyAction(action)) _showPrivacyPolicy();
    }));
    if (widget.showPrivacyPolicy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyPolicy());
    }
  }

  void _returnToSignIn() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(notice: 'Your session expired. Please sign in again.'),
      ),
      (_) => false,
    );
  }

  void _showPrivacyPolicy() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: buildAppTheme(),
      home: widget.isSignedIn ? const DashboardScreen() : const AuthScreen(),
    );
  }
}

/// Shown instead of the app when a release build is misconfigured.
class ConfigErrorApp extends StatelessWidget {
  final String message;

  const ConfigErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
