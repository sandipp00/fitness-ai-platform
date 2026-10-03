import 'package:flutter/material.dart';
import 'services/background_sync.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/session.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await Session().getToken();
  runApp(FitnessAiApp(isSignedIn: token != null));
}

class FitnessAiApp extends StatelessWidget {
  final bool isSignedIn;

  const FitnessAiApp({super.key, required this.isSignedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness AI',
      theme: buildAppTheme(),
      home: isSignedIn ? const DashboardScreen() : const AuthScreen(),
    );
  }
}
