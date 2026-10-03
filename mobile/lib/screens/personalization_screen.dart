import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          Icon(Icons.edit_outlined),
          SizedBox(width: 18),
        ],
      ),
      body: error != null
          ? Center(child: Text(error!))
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    _ProfileHeader(data: data!),
                    const SizedBox(height: 20),
                    const _Title('Account settings'),
                    const SizedBox(height: 10),
                    _Setting(icon: Icons.person_outline_rounded, title: 'Personal information'),
                    _Setting(icon: Icons.notifications_none_rounded, title: 'Reminders'),
                    const SizedBox(height: 16),
                    const _Title('Personalization'),
                    const SizedBox(height: 10),
                    _Setting(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Readiness signal',
                      trailing: '${data!['readiness']}%',
                    ),
                    _Setting(
                      icon: Icons.track_changes_rounded,
                      title: 'Adherence signal',
                      trailing: '${data!['adherence_probability']}%',
                    ),
                    _Setting(
                      icon: Icons.fitness_center_rounded,
                      title: 'Recommended level',
                      trailing: data!['recommended_level'].toString(),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      radius: 22,
                      child: Text(
                        data!['explanation'].toString(),
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Model: ${data!['model_version']}',
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Personalization signals are engineering outputs, not medical measurements.',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 10),
                    ),
                  ],
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfileHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 28,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 42),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your Fitness Profile',
            style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personalized from your activity data',
            style: TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Readiness', value: '${data['readiness']}%')),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'Adherence', value: '${data['adherence_probability']}%')),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'Level', value: data['recommended_level'].toString())),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800),
      );
}

class _Setting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const _Setting({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        radius: 19,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText, size: 19),
          ],
        ),
      ),
    );
  }
}
