import 'package:flutter/material.dart';
import '../services/health_connect_service.dart';
import '../services/health_sync_service.dart';
import 'privacy_policy_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final sync = HealthSyncService();
  bool busy = false;
  String message = 'Not connected';
  NormalizedHealthData? latest;

  @override
  void initState() {
    super.initState();
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final last = await HealthSyncService.lastSync();
    if (last != null && mounted) {
      setState(() => message = 'Last synced ${_formatTime(last)}.');
    }
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    return sameDay ? 'today at $hh:$mm' : 'on ${local.day}/${local.month} at $hh:$mm';
  }

  Future<bool> _ensureConsent() async {
    if (await HealthSyncService.hasConsent()) return true;
    if (!mounted) return false;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share health data with Kinetiq?'),
        content: const SingleChildScrollView(
          child: Text(
            'Kinetiq will read your daily steps, active minutes, active calories, distance '
            'and sleep duration, and upload these daily totals to your Kinetiq account to '
            'calculate your scores, trends and plans.\n\n'
            'Kinetiq never writes to your health app and never sells your data. You can '
            'revoke access in your health app settings and delete your data from '
            'Account & privacy at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            child: const Text('Privacy policy'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Agree')),
        ],
      ),
    );
    if (agreed == true) await HealthSyncService.setConsent(true);
    return agreed == true;
  }

  Future<void> connect() async {
    if (!await _ensureConsent()) return;
    if (!mounted) return;
    setState(() {
      busy = true;
      message = 'Requesting health permissions…';
    });
    try {
      final (result, data) = await sync.connectAndSync();
      if (!mounted) return;
      switch (result) {
        case ConnectResult.synced:
          setState(() {
            latest = data;
            message = 'Connected. Synced today’s data; Kinetiq will keep it updated hourly.';
          });
          break;
        case ConnectResult.permissionDenied:
          setState(() => message =
              'Permission was not granted. Allow access to steps, exercise, distance, calories '
              'and sleep in your health app settings, then try again.');
          break;
        case ConnectResult.needsInstall:
          setState(() => message = 'Health Connect needs to be installed or updated first.');
          await sync.health.installHealthConnect();
          break;
        case ConnectResult.unavailable:
          setState(() => message = 'Health data is not available on this device.');
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => message = 'Health sync failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = latest;
    final source = sync.health.isAndroid ? 'Health Connect' : 'Apple Health';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Health',
          style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800),
        ),
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
          _HealthRow(
            icon: Icons.directions_walk_rounded,
            title: 'Steps',
            subtitle: d == null ? 'Synced from $source' : '${d.steps} steps · ${d.distanceKm.toStringAsFixed(1)} km',
            accent: AppColors.success,
          ),
          _HealthRow(
            icon: Icons.timer_outlined,
            title: 'Active time',
            subtitle: d == null ? 'Synced from $source' : '${d.activeMinutes} min',
            accent: AppColors.blue,
          ),
          _HealthRow(
            icon: Icons.nightlight_round,
            title: 'Sleep',
            subtitle: d == null ? 'Synced from $source' : '${d.sleepHours.toStringAsFixed(1)} h last night',
            accent: AppColors.purple,
          ),
          _HealthRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Active energy',
            subtitle: d == null ? 'Synced from $source' : '${d.caloriesBurned.round()} kcal',
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
              decoration: BoxDecoration(color: accent.withValues(alpha: .13), shape: BoxShape.circle),
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
