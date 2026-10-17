import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'background_sync.dart';
import 'health_connect_service.dart';

enum ConnectResult { synced, permissionDenied, needsInstall, unavailable }

class HealthSyncService {
  final ApiClient api;
  final HealthConnectService health;

  HealthSyncService({ApiClient? api, HealthConnectService? health})
      : api = api ?? ApiClient.shared,
        health = health ?? HealthConnectService();

  static const consentKey = 'health_consent_v1';
  static const lastSyncKey = 'health_last_sync';

  static Future<bool> hasConsent() async =>
      (await SharedPreferences.getInstance()).getBool(consentKey) ?? false;

  static Future<void> setConsent(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(consentKey, value);

  static Future<DateTime?> lastSync() async {
    final value = (await SharedPreferences.getInstance()).getString(lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  /// Requests permissions, syncs today's data and enables hourly background sync.
  Future<(ConnectResult, NormalizedHealthData?)> connectAndSync() async {
    switch (await health.availability()) {
      case HealthAvailability.needsInstall:
        return (ConnectResult.needsInstall, null);
      case HealthAvailability.unavailable:
        return (ConnectResult.unavailable, null);
      case HealthAvailability.available:
        break;
    }

    if (!await health.requestAccess()) return (ConnectResult.permissionDenied, null);

    final data = await syncNow();

    if (health.isAndroid) {
      try {
        if (await health.backgroundAvailable() &&
            (await health.backgroundAuthorized() || await health.requestBackgroundAccess())) {
          await const BackgroundSync().scheduleHourlyHealthSync();
        }
      } catch (e) {
        // Foreground sync still works without background access.
        debugPrint('Background sync not enabled: $e');
      }
    }
    return (ConnectResult.synced, data);
  }

  Future<NormalizedHealthData> syncNow() async {
    final data = await health.readToday();
    await api.syncHealthData(data.toJson());
    await (await SharedPreferences.getInstance())
        .setString(lastSyncKey, DateTime.now().toIso8601String());
    return data;
  }
}
