import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import 'package:kinetiq/models/dashboard_data.dart';
import 'package:kinetiq/services/health_connect_service.dart';

void main() {
  final now = DateTime(2026, 10, 17, 15, 0);
  final today = DateTime(2026, 10, 17);

  NormalizedHealthData summarize({List<HealthSample> activity = const [], List<HealthSample> sleep = const []}) =>
      HealthConnectService.summarize(now: now, steps: 6000, activity: activity, sleep: sleep, source: 'test');

  test('android uses workout sessions instead of the iOS-only exercise time', () {
    final android = HealthConnectService(isAndroid: true);
    final ios = HealthConnectService(isAndroid: false);
    expect(android.types, isNot(contains(HealthDataType.EXERCISE_TIME)));
    expect(android.types, containsAll([HealthDataType.WORKOUT, HealthDataType.SLEEP_SESSION]));
    expect(ios.types, containsAll([HealthDataType.EXERCISE_TIME, HealthDataType.DISTANCE_WALKING_RUNNING]));
    expect(android.source, 'health_connect');
    expect(ios.source, 'healthkit');
  });

  test('every Android type is supported by Health Connect', () {
    final android = HealthConnectService(isAndroid: true);
    for (final type in android.types) {
      expect(dataTypeKeysAndroid, contains(type), reason: '$type is not available on Android');
    }
  });

  test('totals are summed and converted', () {
    final data = summarize(activity: [
      HealthSample(HealthDataType.ACTIVE_ENERGY_BURNED, 120.5, today, now),
      HealthSample(HealthDataType.ACTIVE_ENERGY_BURNED, 80, today, now),
      HealthSample(HealthDataType.DISTANCE_DELTA, 2500, today, now),
      HealthSample(HealthDataType.EXERCISE_TIME, 25, today, now),
    ]);
    expect(data.steps, 6000);
    expect(data.caloriesBurned, 200.5);
    expect(data.distanceKm, 2.5);
    expect(data.activeMinutes, 25);
  });

  test('workouts that started yesterday only count today\'s minutes', () {
    final data = summarize(activity: [
      // 23:30 yesterday -> 00:30 today: only 30 minutes are today.
      HealthSample(HealthDataType.WORKOUT, null, today.subtract(const Duration(minutes: 30)),
          today.add(const Duration(minutes: 30))),
      HealthSample(HealthDataType.WORKOUT, null, DateTime(2026, 10, 17, 7), DateTime(2026, 10, 17, 7, 45)),
    ]);
    expect(data.activeMinutes, 75);
  });

  test('sleep counts the overnight session but not an afternoon nap yesterday', () {
    final data = summarize(sleep: [
      HealthSample(HealthDataType.SLEEP_SESSION, null, DateTime(2026, 10, 16, 23), DateTime(2026, 10, 17, 6, 30)),
      HealthSample(HealthDataType.SLEEP_SESSION, null, DateTime(2026, 10, 16, 14), DateTime(2026, 10, 16, 15)),
    ]);
    expect(data.sleepHours, 7.5);
  });

  test('payload omits sleep when none was recorded', () {
    final json = summarize().toJson();
    expect(json['day'], '2026-10-17');
    expect(json.containsKey('sleep'), isFalse);
    expect(json['activity'], containsPair('steps', 6000));

    final withSleep = summarize(sleep: [
      HealthSample(HealthDataType.SLEEP_SESSION, null, DateTime(2026, 10, 17, 0), DateTime(2026, 10, 17, 7)),
    ]).toJson();
    expect(withSleep['sleep'], {'duration_hours': 7.0, 'quality': 3});
  });

  test('dashboard parsing accepts floats for integer fields', () {
    final data = DashboardData.fromJson({
      'activity': {'steps': 1200.0, 'active_minutes': 30, 'calories_burned': 150, 'distance_km': 1.2},
      'sleep': {'hours': 7, 'quality': 3},
      'water_liters': 1.5,
      'workouts_today': 1.0,
      'scores': {'activity': 50, 'sleep': 80.5, 'recovery': 70},
      'recommendations': ['Walk'],
    });
    expect(data.steps, 1200);
    expect(data.workoutsToday, 1);
    expect(data.sleepScore, 80.5);
    expect(data.recommendations, ['Walk']);
  });
}
