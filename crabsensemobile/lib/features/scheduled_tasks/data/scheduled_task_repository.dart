import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/scheduled_task.dart';

class ScheduledTaskRepository {
  ScheduledTaskRepository(this._api);

  final ApiClient _api;

  Future<List<ScheduledTask>> list({String? farmingAreaId}) async {
    final response = await _api.get(
      ApiConstants.scheduledTasks,
      queryParameters: farmingAreaId == null
          ? null
          : {'farmingAreaId': farmingAreaId},
    );
    return _list(response.data).map(ScheduledTask.fromJson).toList();
  }

  Future<ScheduledTask> create(ScheduledTask task) async {
    final response = await _api.post(
      ApiConstants.scheduledTasks,
      data: task.toJson(),
    );
    return ScheduledTask.fromJson(_map(response.data));
  }

  Future<ScheduledTask> update(String id, Map<String, dynamic> data) async {
    final response = await _api.put(
      ApiConstants.scheduledTask(id),
      data: data,
    );
    return ScheduledTask.fromJson(_map(response.data));
  }

  Future<void> delete(String id) async {
    await _api.delete(ApiConstants.scheduledTask(id));
  }

  Future<ScheduledTask> toggle(String id, bool enabled) async {
    final response = await _api.post(
      ApiConstants.scheduledTaskToggle(id),
      queryParameters: {'enabled': enabled},
    );
    return ScheduledTask.fromJson(_map(response.data));
  }

  List<Map<String, dynamic>> _list(dynamic body) {
    final root = _map(body);
    final data = root['data'];
    final items = data is List ? data : (data is Map ? data['items'] : null);
    return (items as List?)
            ?.whereType<Map>()
            .map((item) => item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ))
            .toList() ??
        const [];
  }

  Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      return data is Map<String, dynamic> ? data : body;
    }
    if (body is Map) {
      return _map(body.map(
        (key, value) => MapEntry(key.toString(), value),
      ));
    }
    return const {};
  }
}
