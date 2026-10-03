import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

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
    if (error != null) {
      return _Shell(title: 'Statistics', child: Center(child: Text(error!)));
    }
    if (data == null) {
      return const _Shell(
        title: 'Statistics',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final averages = (data!['averages'] as Map?)?.cast<String, dynamic>() ?? {};
    final change = (data!['recent_vs_previous'] as Map?)?.cast<String, dynamic>() ?? {};
    final series = (data!['series'] as List?)?.cast<Map>() ?? const [];

    return _Shell(
      title: 'Statistics',
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            const _Pills(),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average steps',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${averages['steps'] ?? 0}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '28 days',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Chart(series: series),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent workout',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    icon: Icons.favorite_rounded,
                    title: 'Active time',
                    value: '${averages['active_minutes'] ?? 0} min',
                    change: change['active_minutes'],
                    accent: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tile(
                    icon: Icons.nightlight_round,
                    title: 'Sleep',
                    value: '${averages['sleep_hours'] ?? 0} h',
                    change: change['sleep_hours'],
                    accent: AppColors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const GlassCard(
              padding: EdgeInsets.all(15),
              radius: 20,
              child: Text(
                'Changes compare the latest 7 days with the preceding 7 days. '
                'They describe recorded data and are not predictions.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  final String title;
  final Widget child;
  const _Shell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          Icon(Icons.more_horiz_rounded),
          SizedBox(width: 18),
        ],
      ),
      body: child,
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['Steps', 'Calories', 'Regularity'].map((label) {
        final selected = label == 'Steps';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.white.withOpacity(.38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(.75)),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Chart extends StatelessWidget {
  final List<Map> series;
  const _Chart({required this.series});

  @override
  Widget build(BuildContext context) {
    final recent = series.length > 7 ? series.sublist(series.length - 7) : series;
    final values = recent.map((x) => (x['steps'] as num?)?.toDouble() ?? 0).toList();
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final height = 18 + (values[index] / maxValue) * 100;
          final selected = index == values.length - 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _dayLabel(recent[index]['day']),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _dayLabel(dynamic raw) {
    if (raw == null) return '';
    final text = raw.toString();
    return text.length >= 5 ? text.substring(8, 10) : text;
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final dynamic change;
  final Color accent;

  const _Tile({
    required this.icon,
    required this.title,
    required this.value,
    required this.change,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final numeric = change is num ? change.toDouble() : 0.0;
    final sign = numeric > 0 ? '+' : '';
    return GlassCard(
      padding: const EdgeInsets.all(15),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$sign${numeric.toStringAsFixed(1)} vs prior',
            style: TextStyle(
              color: numeric >= 0 ? AppColors.success : Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
