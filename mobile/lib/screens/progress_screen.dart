import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/session.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final api = const ApiClient();
  final session = const Session();
  Map<String, dynamic>? data;
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
      final result = await api.getTrends(token);
      if (mounted) setState(() => data = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final averages = (data?['averages'] as Map?)?.cast<String, dynamic>() ?? {};
    final change = (data?['recent_vs_previous'] as Map?)?.cast<String, dynamic>() ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: error != null
          ? Center(child: Text(error!))
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        '28-day trends',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      _Metric(
                        title: 'Average steps',
                        value: '${averages['steps'] ?? 0}',
                        change: change['steps'],
                      ),
                      _Metric(
                        title: 'Average active minutes',
                        value: '${averages['active_minutes'] ?? 0}',
                        change: change['active_minutes'],
                      ),
                      _Metric(
                        title: 'Average sleep',
                        value: '${averages['sleep_hours'] ?? 0} h',
                        change: change['sleep_hours'],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Changes compare the latest 7 days with the preceding 7 days. '
                        'They describe recorded data; they are not predictions.',
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final dynamic change;

  const _Metric({
    required this.title,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final numeric = change is num ? change.toDouble() : 0.0;
    final sign = numeric > 0 ? '+' : '';
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('$sign${numeric.toStringAsFixed(1)} vs prior week'),
          ],
        ),
      ),
    );
  }
}
