import 'package:flutter/material.dart';
import '../services/health_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

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
    setState(() {
      busy = true;
      message = 'Requesting health permissions…';
    });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Health',
          style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: const [
          Icon(Icons.settings_outlined),
          SizedBox(width: 18),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(18),
            radius: 27,
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 29),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect your health data',
                        style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Sync Health Connect to get personalized insights.',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : connect,
              icon: Icon(busy ? Icons.sync : Icons.link_rounded),
              label: Text(busy ? 'Syncing…' : 'Connect Health App'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(15),
            radius: 20,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Today's health data",
            style: TextStyle(color: AppColors.text, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _HealthRow(
            icon: Icons.directions_walk_rounded,
            title: 'Steps',
            subtitle: 'Synced from Health Connect',
            accent: AppColors.success,
          ),
          const _HealthRow(
            icon: Icons.nightlight_round,
            title: 'Sleep',
            subtitle: 'Synced from Health Connect',
            accent: AppColors.purple,
          ),
          const _HealthRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Active energy',
            subtitle: 'Synced from Health Connect',
            accent: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _HealthRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withOpacity(.13), shape: BoxShape.circle),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
