import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/session.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
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
      final result = await api.getPersonalization(token);
      if (mounted) setState(() => data = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalization')),
      body: error != null
          ? Center(child: Text(error!))
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Your adaptive profile',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 18),
                    _Metric(
                      title: 'Readiness signal',
                      value: '${data!['readiness']}%',
                    ),
                    _Metric(
                      title: 'Adherence signal',
                      value: '${data!['adherence_probability']}%',
                    ),
                    _Metric(
                      title: 'Recommended level',
                      value: data!['recommended_level'].toString(),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(data!['explanation'].toString()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Model: ${data!['model_version']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a behavioral personalization signal, not a '
                      'medical measurement or prediction of health outcomes.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
