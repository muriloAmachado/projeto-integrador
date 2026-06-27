import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> list({
    required String token,
    bool onlyUnread,
  });

  Future<int> unreadCount({required String token});

  Future<void> markAsRead({required String token, required String id});

  Future<void> markAllAsRead({required String token});
}
