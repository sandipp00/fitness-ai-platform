import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'api_client.dart';
import 'health_connect_service.dart';
import 'session.dart';

const healthSyncTask = 'kinetiq_health_sync';
const _uniqueName = 'kinetiq-hourly-health-sync';

@pragma('vm:entry-point')
void healthBackgroundCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task != healthSyncTask) return true;
    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (!await const Session().isSignedIn()) return true;

      final health = HealthConnectService();
      if (!await health.backgroundAvailable()) return true;
      if (!await health.backgroundAuthorized()) return true;
      if (!await health.hasAccess()) return true;

      final data = await health.readToday();
      await ApiClient().syncHealthData(data.toJson());
      return true;
    } on SessionExpiredException {
      await const BackgroundSync().cancel();
      return true;
    } catch (_) {
      // Let Workmanager retry according to the platform's backoff policy.
      return false;
    }
  });
}

class BackgroundSync {
  const BackgroundSync();

  Future<void> initialize() => Workmanager().initialize(healthBackgroundCallback);

  Future<void> scheduleHourlyHealthSync() => Workmanager().registerPeriodicTask(
        _uniqueName,
        healthSyncTask,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );

  Future<void> cancel() => Workmanager().cancelByUniqueName(_uniqueName);
}
