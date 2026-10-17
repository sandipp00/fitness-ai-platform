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
      : steps = _int(json['activity']?['steps']),
        activeMinutes = _int(json['activity']?['active_minutes']),
        caloriesBurned = _double(json['activity']?['calories_burned']),
        distanceKm = _double(json['activity']?['distance_km']),
        sleepHours = _double(json['sleep']?['hours']),
        waterLiters = _double(json['water_liters']),
        recovery = _double(json['scores']?['recovery']),
        activityScore = _double(json['scores']?['activity']),
        sleepScore = _double(json['scores']?['sleep']),
        workoutsToday = _int(json['workouts_today']),
        recommendations = List<String>.from(json['recommendations'] ?? const []);

  // The API may send whole numbers as floats (e.g. 120.0); accept any number.
  static int _int(Object? value) => value is num ? value.round() : 0;
  static double _double(Object? value) => value is num ? value.toDouble() : 0;
}
