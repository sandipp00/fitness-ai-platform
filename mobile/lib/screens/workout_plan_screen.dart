import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/session.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final api = const ApiClient();
  final session = const Session();
  Map<String, dynamic>? plan;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final token = await session.getToken();
      if (token == null) throw Exception('Session expired');
      final result = await api.getWorkoutPlan(token);
      if (mounted) setState(() => plan = result['plan'] as Map<String, dynamic>);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = (plan?['sessions'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive workout plan')),
      body: error != null
          ? Center(child: Text(error!))
          : plan == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${plan!['goal']} · ${plan!['strategy']}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(plan!['reason']?.toString() ?? ''),
                    const SizedBox(height: 16),
                    for (final item in sessions.cast<Map<String, dynamic>>())
                      Card(
                        child: ListTile(
                          title: Text('${item['day']} · ${item['type']}'),
                          subtitle: Text(
                            '${item['minutes']} min · ${item['intensity']}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(plan!['safety']?.toString() ?? ''),
                  ],
                ),
    );
  }
}
