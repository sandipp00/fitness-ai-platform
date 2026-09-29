class DashboardData {
  final int steps;
  final int activeMinutes;
  final double caloriesBurned;
  final double distanceKm;
  final double sleepHours;
  final double waterLiters;
  final double recovery;
  final double activityScore;
  final double sleepScore;
  final int workoutsToday;
  final List<String> recommendations;

  DashboardData.fromJson(Map<String, dynamic> json)
      : steps = (json['activity']['steps'] ?? 0) as int,
        activeMinutes = (json['activity']['active_minutes'] ?? 0) as int,
        caloriesBurned = ((json['activity']['calories_burned'] ?? 0) as num).toDouble(),
        distanceKm = ((json['activity']['distance_km'] ?? 0) as num).toDouble(),
        sleepHours = ((json['sleep']['hours'] ?? 0) as num).toDouble(),
        waterLiters = ((json['water_liters'] ?? 0) as num).toDouble(),
        recovery = ((json['scores']['recovery'] ?? 0) as num).toDouble(),
        activityScore = ((json['scores']['activity'] ?? 0) as num).toDouble(),
        sleepScore = ((json['scores']['sleep'] ?? 0) as num).toDouble(),
        workoutsToday = (json['workouts_today'] ?? 0) as int,
        recommendations = List<String>.from(json['recommendations'] ?? const []);
}
