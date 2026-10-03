import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../widgets/metric_card.dart';
import 'health_screen.dart';
import 'recommendations_screen.dart';
import 'coach_screen.dart';
import 'progress_screen.dart';
import 'workout_plan_screen.dart';
import 'personalization_screen.dart';
import 'auth_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = const ApiClient();
  final session = Session();
  DashboardData? data;
  String? error;
  bool loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    final token = await session.getToken();
    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    try {
      final json = await api.getDashboard(token);
      if (!mounted) return;
      setState(() => data = DashboardData.fromJson(json));
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0EE),
      appBar: _selectedIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fitness AI'),
            Text('Your health snapshot for today', style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout_outlined)),
        ],
      ) : null,
      body: _selectedPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'Coach'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
        ],
      ),
    );
  }

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 1:
        return const HealthScreen();
      case 2:
        return const WorkoutPlanScreen();
      case 3:
        return const CoachScreen();
      case 4:
        return const ProgressScreen();
      default:
        return _dashboardContent();
    }
  }

  Widget _dashboardContent() {
    final d = data;
    return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (loading && d == null) const LinearProgressIndicator(),
            if (error != null) _ErrorCard(message: error!, onRetry: load),
            if (d != null) ...[
              _RecoveryCard(value: d.recovery),
              const SizedBox(height: 20),
              const Text('Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35,
                ),
                children: [
                  MetricCard(icon: Icons.directions_walk, label: 'Steps', value: '${d.steps}', target: '10,000'),
                  MetricCard(icon: Icons.local_fire_department, label: 'Calories', value: '${d.caloriesBurned.round()}', target: 'kcal'),
                  MetricCard(icon: Icons.timer_outlined, label: 'Active', value: '${d.activeMinutes}', target: 'min'),
                  MetricCard(icon: Icons.water_drop_outlined, label: 'Water', value: d.waterLiters.toStringAsFixed(1), target: 'L'),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recovery & sleep', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      Text('Recovery  ${d.recovery.toStringAsFixed(0)}%'),
                      Text('Sleep      ${d.sleepHours.toStringAsFixed(1)} h'),
                      Text('Workouts   ${d.workoutsToday} today'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today’s recommendations', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ...d.recommendations.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const Text('•  '), Expanded(child: Text(r))],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
  }
}

class _RecoveryCard extends StatelessWidget {
  final double value;
  const _RecoveryCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = value.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B4D45), Color(0xFF176B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B4D45).withOpacity(.18), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recovery', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: percent / 100, minHeight: 8, backgroundColor: Colors.white24, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Could not load your dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
