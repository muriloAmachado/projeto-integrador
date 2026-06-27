import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationService service})
    : _service = service;

  final NotificationService _service;

  @override
  Future<List<AppNotification>> list({
    required String token,
    bool onlyUnread = false,
  }) {
    return _service.list(token: token, onlyUnread: onlyUnread);
  }

  @override
  Future<int> unreadCount({required String token}) {
    return _service.unreadCount(token: token);
  }

  @override
  Future<void> markAsRead({required String token, required String id}) {
    return _service.markAsRead(token: token, id: id);
  }

  @override
  Future<void> markAllAsRead({required String token}) {
    return _service.markAllAsRead(token: token);
  }
}
