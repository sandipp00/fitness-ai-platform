import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
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
      final result = await api.getRecommendations(token);
      if (mounted) setState(() => data = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendations =
        (data?['recommendations'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('AI recommendations')),
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
                        'Personalized coaching',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Recommendations are generated from your latest '
                        'activity, sleep, recovery and goal data.',
                      ),
                      const SizedBox(height: 20),
                      _ScoreRow(data: data!['scores'] as Map<String, dynamic>),
                      const SizedBox(height: 20),
                      for (final item in recommendations)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.auto_awesome),
                            title: Text(item['title']?.toString() ?? ''),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(item['message']?.toString() ?? ''),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        data?['disclaimer']?.toString() ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ScoreRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Score(label: 'Activity', value: data['activity']),
        _Score(label: 'Sleep', value: data['sleep']),
        _Score(label: 'Recovery', value: data['recovery']),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  final String label;
  final dynamic value;

  const _Score({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(
                '${value ?? 0}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
