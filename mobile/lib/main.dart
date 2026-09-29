import 'package:flutter/material.dart';
import 'services/background_sync.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/session.dart';

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
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF16A34A));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      home: isSignedIn ? const DashboardScreen() : const AuthScreen(),
    );
  }
}
