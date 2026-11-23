// The read-only views: /api/dashboard and /api/activity.
import '../core/api/api_client.dart';
import '../models/activity_event.dart';
import '../models/dashboard.dart';

class DashboardService {
  DashboardService(this._api);
  final ApiClient _api;

  Future<DashboardStats> stats() async =>
      DashboardStats.fromJson((await _api.get('/dashboard')).data as Map<String, dynamic>);

  Future<List<ActivityEvent>> activity() async {
    final data = (await _api.get('/activity')).data;
    return [for (final e in data['events'] as List) ActivityEvent.fromJson(e as Map<String, dynamic>)];
  }
}
