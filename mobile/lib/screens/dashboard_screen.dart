import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/stat_card.dart';
import 'auth_screen.dart';
import 'coach_screen.dart';
import 'health_screen.dart';
import 'personalization_screen.dart';
import 'progress_screen.dart';
import 'recommendations_screen.dart';
import 'workout_plan_screen.dart';

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
    setState(() {
      loading = true;
      error = null;
    });

    final token = await session.getToken();
    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
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
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: _selectedIndex == 0 ? _homeAppBar() : null,
      body: _selectedPage(),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  PreferredSizeWidget _homeAppBar() {
    return AppBar(
      toolbarHeight: 76,
      titleSpacing: 20,
      title: const Row(
        children: [
          _BrandMark(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Here is your health snapshot',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') logout();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'logout', child: Text('Log out')),
          ],
          icon: const Icon(Icons.more_horiz_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _selectedPage() {
    switch (_selectedIndex) {
      case 1:
        return const HealthScreen();
      case 2:
        return const ProgressScreen();
      case 3:
        return const CoachScreen();
      case 4:
        return const PersonalizationScreen();
      default:
        return _homeContent();
    }
  }

  Widget _homeContent() {
    final d = data;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            radius: 22,
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.mutedText),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search workouts, health data...',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (loading && d == null)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (error != null)
            _ErrorCard(message: error!, onRetry: load),
          if (d != null) ...[
            _RecoveryHero(value: d.recovery),
            const SizedBox(height: 24),
            _SectionHeader(
              title: "Today's stats",
              action: 'View more',
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  icon: Icons.directions_walk_rounded,
                  label: 'Steps',
                  value: '${d.steps}',
                  unit: 'steps',
                  accent: AppColors.success,
                ),
                StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Calories',
                  value: '${d.caloriesBurned.round()}',
                  unit: 'kcal',
                  accent: AppColors.orange,
                ),
                StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Active time',
                  value: '${d.activeMinutes}',
                  unit: 'min',
                  accent: AppColors.blue,
                ),
                StatCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Water',
                  value: d.waterLiters.toStringAsFixed(1),
                  unit: 'L',
                  accent: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: "Today's workout",
              action: 'View more',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutPlanScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _WorkoutCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutPlanScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Recovery & sleep',
              action: 'Details',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  _CircularMetric(
                    value: d.recovery,
                    label: 'Recovery',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          icon: Icons.nightlight_round,
                          title: 'Sleep',
                          value: '${d.sleepHours.toStringAsFixed(1)} h',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.fitness_center_rounded,
                          title: 'Workouts',
                          value: '${d.workoutsToday} today',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (d.recommendations.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(
                title: "Today's recommendations",
                action: 'View all',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecommendationsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...d.recommendations.take(3).map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(15),
                    radius: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.mint.withOpacity(.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220C5A50),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _RecoveryHero extends StatelessWidget {
  final double value;

  const _RecoveryHero({required this.value});

  @override
  Widget build(BuildContext context) {
    final percent = value.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24073E38),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recovery',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  percent >= 70
                      ? 'Good recovery today'
                      : 'Take it a little easier today',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _WorkoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBBDDD5), Color(0xFFE7F1EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(.9)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -18,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 150,
              color: AppColors.primary.withOpacity(.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upper Body Strength',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '18 exercises • 35 min',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularMetric extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _CircularMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (value.clamp(0, 100)) / 100,
            strokeWidth: 7,
            backgroundColor: color.withOpacity(.12),
            color: color,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load your dashboard',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
