import 'package:flutter/material.dart';
import '../services/health_sync_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final sync = const HealthSyncService();
  bool busy = false;
  String message = 'Not connected';

  Future<void> connect() async {
    setState(() { busy = true; message = 'Requesting health permissions…'; });
    try {
      final ok = await sync.connectAndSync();
      if (!mounted) return;
      setState(() => message = ok
          ? 'Connected and synced today’s health data.'
          : 'Permission was not granted.');
    } catch (e) {
      if (!mounted) return;
      setState(() => message = 'Health sync failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.health_and_safety_outlined, size: 56),
          const SizedBox(height: 16),
          const Text('Connect your health data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Fitness AI reads the minimum data needed for your dashboard. '
            'You can grant or revoke access through your device health settings.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Health Connect'),
              subtitle: Text(message),
              trailing: FilledButton(
                onPressed: busy ? null : connect,
                child: Text(busy ? '…' : 'Connect'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
