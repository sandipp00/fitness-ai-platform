import 'package:health/health.dart';

class NormalizedHealthData {
  final DateTime day;
  final int steps;
  final int activeMinutes;
  final double caloriesBurned;
  final double distanceKm;
  final double sleepHours;
  final String source;

  const NormalizedHealthData({
    required this.day,
    required this.steps,
    required this.activeMinutes,
    required this.caloriesBurned,
    required this.distanceKm,
    required this.sleepHours,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'day': '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
        'source': source,
        'activity': {
          'steps': steps,
          'active_minutes': activeMinutes,
          'calories_burned': caloriesBurned,
          'distance_km': distanceKm,
        },
        'sleep': {
          'duration_hours': sleepHours,
          'quality': 3,
        },
      };
}

class HealthConnectService {
  const HealthConnectService();

  Health get health => Health();

  static const types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static const permissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> configure() => health.configure();

  Future<bool> requestAccess() async {
    await configure();
    return health.requestAuthorization(types, permissions: permissions);
  }

  Future<bool> hasAccess() async {
    await configure();
    final result = await health.hasPermissions(types, permissions: permissions);
    return result == true;
  }

  Future<bool> backgroundAvailable() async {
    await configure();
    return health.isHealthDataInBackgroundAvailable();
  }

  Future<bool> backgroundAuthorized() async {
    await configure();
    return health.isHealthDataInBackgroundAuthorized();
  }

  Future<bool> requestBackgroundAccess() async {
    await configure();
    return health.requestHealthDataInBackgroundAuthorization();
  }

  Future<NormalizedHealthData> readToday() async {
    await configure();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Capture a full previous-night window without pulling a week of history.
    final sleepStart = today.subtract(const Duration(hours: 18));

    // Health Connect aggregates cumulative steps, preventing source overlap.
    final totalSteps = await health.getTotalStepsInInterval(today, now) ?? 0;

    final points = await health.getHealthDataFromTypes(
      startTime: sleepStart,
      endTime: now,
      types: types,
    );

    double calories = 0;
    double distanceKm = 0;
    double sleepHours = 0;
    double activeMinutes = 0;

    for (final point in health.removeDuplicates(points)) {
      final value = point.value;
      if (value is NumericHealthValue) {
        final number = value.numericValue;
        switch (point.type) {
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            calories += number;
            break;
          case HealthDataType.DISTANCE_DELTA:
            distanceKm += number / 1000.0;
            break;
          case HealthDataType.EXERCISE_TIME:
            activeMinutes += number;
            break;
          case HealthDataType.SLEEP_ASLEEP:
            sleepHours += number / 60.0;
            break;
          default:
            break;
        }
      }
    }

    return NormalizedHealthData(
      day: today,
      steps: totalSteps,
      activeMinutes: activeMinutes.round(),
      caloriesBurned: calories,
      distanceKm: distanceKm,
      sleepHours: sleepHours,
      source: 'health_connect',
    );
  }
}
