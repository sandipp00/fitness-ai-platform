import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

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
        // Omit sleep when none was recorded so the server keeps any existing value.
        if (sleepHours > 0)
          'sleep': {
            'duration_hours': sleepHours,
            'quality': 3,
          },
      };
}

/// A platform-neutral health sample used for aggregation.
class HealthSample {
  final HealthDataType type;
  final double? value;
  final DateTime from;
  final DateTime to;

  const HealthSample(this.type, this.value, this.from, this.to);

  factory HealthSample.fromPoint(HealthDataPoint point) {
    final value = point.value;
    return HealthSample(
      point.type,
      value is NumericHealthValue ? value.numericValue.toDouble() : null,
      point.dateFrom,
      point.dateTo,
    );
  }
}

enum HealthAvailability { available, needsInstall, unavailable }

class HealthConnectService {
  final bool isAndroid;
  final Health _health;

  HealthConnectService({bool? isAndroid, Health? health})
      : isAndroid = isAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
        _health = health ?? Health();

  /// Data read for "today" (midnight to now).
  List<HealthDataType> get activityTypes => isAndroid
      // Health Connect has no exercise-time type; active minutes come from
      // workout sessions instead.
      ? const [HealthDataType.ACTIVE_ENERGY_BURNED, HealthDataType.DISTANCE_DELTA, HealthDataType.WORKOUT]
      : const [HealthDataType.ACTIVE_ENERGY_BURNED, HealthDataType.DISTANCE_WALKING_RUNNING, HealthDataType.EXERCISE_TIME];

  HealthDataType get sleepType => isAndroid ? HealthDataType.SLEEP_SESSION : HealthDataType.SLEEP_ASLEEP;

  List<HealthDataType> get types => [HealthDataType.STEPS, ...activityTypes, sleepType];

  List<HealthDataAccess> get _permissions => List.filled(types.length, HealthDataAccess.READ);

  String get source => isAndroid ? 'health_connect' : 'healthkit';

  Future<HealthAvailability> availability() async {
    await _health.configure();
    if (!isAndroid) return HealthAvailability.available;
    final status = await _health.getHealthConnectSdkStatus();
    switch (status) {
      case HealthConnectSdkStatus.sdkAvailable:
        return HealthAvailability.available;
      case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
        return HealthAvailability.needsInstall;
      default:
        return HealthAvailability.unavailable;
    }
  }

  Future<void> installHealthConnect() => _health.installHealthConnect();

  Future<bool> requestAccess() async {
    await _health.configure();
    if (isAndroid) {
      // Step counting on Android also needs the runtime activity-recognition permission.
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) return false;
    }
    return _health.requestAuthorization(types, permissions: _permissions);
  }

  Future<bool> hasAccess() async {
    await _health.configure();
    final result = await _health.hasPermissions(types, permissions: _permissions);
    return result == true;
  }

  Future<bool> backgroundAvailable() async {
    await _health.configure();
    return _health.isHealthDataInBackgroundAvailable();
  }

  Future<bool> backgroundAuthorized() async {
    await _health.configure();
    return _health.isHealthDataInBackgroundAuthorized();
  }

  Future<bool> requestBackgroundAccess() async {
    await _health.configure();
    return _health.requestHealthDataInBackgroundAuthorization();
  }

  Future<NormalizedHealthData> readToday({DateTime? now}) async {
    await _health.configure();
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // The platform aggregates steps across sources, so they are not double counted.
    final steps = await _health.getTotalStepsInInterval(today, now) ?? 0;
    final activity = await _health.getHealthDataFromTypes(
      types: activityTypes,
      startTime: today,
      endTime: now,
    );
    final sleep = await _health.getHealthDataFromTypes(
      types: [sleepType],
      startTime: sleepWindowStart(today),
      endTime: now,
    );

    return summarize(
      now: now,
      steps: steps,
      activity: _health.removeDuplicates(activity).map(HealthSample.fromPoint).toList(),
      sleep: _health.removeDuplicates(sleep).map(HealthSample.fromPoint).toList(),
      source: source,
    );
  }

  /// Last night's sleep is read from 18:00 the previous evening.
  static DateTime sleepWindowStart(DateTime today) => today.subtract(const Duration(hours: 6));

  /// Aggregates raw samples into today's totals.
  static NormalizedHealthData summarize({
    required DateTime now,
    required int steps,
    required List<HealthSample> activity,
    required List<HealthSample> sleep,
    required String source,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    double calories = 0;
    double distanceKm = 0;
    double activeMinutes = 0;

    for (final sample in activity) {
      switch (sample.type) {
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += sample.value ?? 0;
          break;
        case HealthDataType.DISTANCE_DELTA:
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          distanceKm += (sample.value ?? 0) / 1000.0;
          break;
        case HealthDataType.EXERCISE_TIME:
          activeMinutes += sample.value ?? 0;
          break;
        case HealthDataType.WORKOUT:
          // Count only the part of the workout that falls within today.
          activeMinutes += _overlapMinutes(sample.from, sample.to, today, now);
          break;
        default:
          break;
      }
    }

    double sleepMinutes = 0;
    final windowStart = sleepWindowStart(today);
    for (final sample in sleep) {
      sleepMinutes += _overlapMinutes(sample.from, sample.to, windowStart, now);
    }

    final minutesSinceMidnight = now.difference(today).inMinutes.toDouble();
    return NormalizedHealthData(
      day: today,
      steps: steps,
      activeMinutes: math.min(activeMinutes, minutesSinceMidnight).round(),
      caloriesBurned: double.parse(calories.toStringAsFixed(1)),
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      sleepHours: double.parse(math.min(sleepMinutes / 60.0, 24).toStringAsFixed(2)),
      source: source,
    );
  }

  static double _overlapMinutes(DateTime from, DateTime to, DateTime start, DateTime end) {
    final s = from.isAfter(start) ? from : start;
    final e = to.isBefore(end) ? to : end;
    return e.isAfter(s) ? e.difference(s).inSeconds / 60.0 : 0;
  }
}
