// Talks to the /api/notifications endpoints. Knows nothing about the UI.
import '../core/api/api_client.dart';
import '../models/app_notification.dart';

/// The list plus the unread count (the bell badge).
class NotificationPage {
  const NotificationPage(this.items, this.unread);
  final List<AppNotification> items;
  final int unread;
}

class NotificationService {
  NotificationService(this._api);
  final ApiClient _api;

  Future<NotificationPage> list() async {
    final data = (await _api.get('/notifications')).data;
    return NotificationPage(
      [for (final n in data['notifications'] as List) AppNotification.fromJson(n as Map<String, dynamic>)],
      (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns the new unread count.
  Future<int> markRead(String id) async =>
      ((await _api.patch('/notifications/$id/read')).data['unreadCount'] as num?)?.toInt() ?? 0;

  /// Returns the server's message ("Marked 3 as read").
  Future<String> markAllRead() async => (await _api.patch('/notifications/read-all')).message;
}
