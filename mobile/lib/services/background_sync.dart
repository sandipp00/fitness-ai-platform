import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api_client.dart';
import 'health_connect_service.dart';

const healthSyncTask = 'fitness_ai_health_sync';

@pragma('vm:entry-point')
void healthBackgroundCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task != healthSyncTask) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return true;

      final health = const HealthConnectService();
      if (!await health.backgroundAvailable()) return true;
      if (!await health.backgroundAuthorized()) return true;
      if (!await health.hasAccess()) return true;

      final data = await health.readToday();
      await const ApiClient().syncHealthData(token, data.toJson());
      return true;
    } catch (_) {
      // Background jobs should not crash the application. Workmanager will
      // retry according to the platform's scheduling policy when appropriate.
      return false;
    }
  });
}

class BackgroundSync {
  const BackgroundSync();

  Future<void> initialize() async {
    await Workmanager().initialize(
      healthBackgroundCallback,
      isInDebugMode: false,
    );
  }

  Future<void> scheduleHourlyHealthSync() async {
    await Workmanager().registerPeriodicTask(
      'fitness-ai-hourly-health-sync',
      healthSyncTask,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> cancel() async {
    await Workmanager().cancelByUniqueName('fitness-ai-hourly-health-sync');
  }
}
