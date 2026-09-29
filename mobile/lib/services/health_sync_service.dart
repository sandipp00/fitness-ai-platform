import 'api_client.dart';
import 'health_connect_service.dart';
import 'session.dart';

class HealthSyncService {
  final ApiClient api;
  final Session session;
  final HealthConnectService health;

  const HealthSyncService({
    this.api = const ApiClient(),
    this.session = const Session(),
    this.health = const HealthConnectService(),
  });

  Future<bool> connectAndSync() async {
    final token = await session.getToken();
    if (token == null) return false;

    final granted = await health.requestAccess();
    if (!granted) return false;

    final data = await health.readToday();
    await api.syncHealthData(token, data.toJson());
    return true;
  }
}
