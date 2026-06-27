import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AppNotification>> list({
    required String token,
    bool onlyUnread = false,
  }) async {
    final response = await _apiClient.getJson(
      onlyUnread ? '/notifications?lida=false' : '/notifications',
      token: token,
    );

    final items = _extractItems(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  Future<int> unreadCount({required String token}) async {
    final response = await _apiClient.getJson(
      '/notifications/unread-count',
      token: token,
    );

    if (response is Map<String, dynamic>) {
      final count = response['count'];
      if (count is num) {
        return count.toInt();
      }
      if (count is String) {
        return int.tryParse(count) ?? 0;
      }
    }

    return 0;
  }

  Future<void> markAsRead({
    required String token,
    required String id,
  }) async {
    await _apiClient.patchJson('/notifications/$id/read', token: token);
  }

  Future<void> markAllAsRead({required String token}) async {
    await _apiClient.patchJson('/notifications/read-all', token: token);
  }

  List<dynamic> _extractItems(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      for (final key in const ['data', 'notifications', 'items', 'result']) {
        final value = response[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const <dynamic>[];
  }
}
