// The signed-in user's notifications and the unread count on the bell.
// The count is refreshed by LiveUpdates while the app is in the foreground.
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._service);
  final NotificationService _service;

  /// null until the first load finishes.
  List<AppNotification>? items;
  int unread = 0;
  String? error;

  /// [quiet] is for the background poll: a failure there keeps the last
  /// good list on screen instead of replacing it with an error.
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      error = null;
      notifyListeners();
    }
    try {
      final page = await _service.list();
      items = page.items;
      unread = page.unread;
      error = null;
    } on ApiException catch (e) {
      if (!quiet) error = e.message;
    }
    notifyListeners();
  }

  /// Marks one as read straight away on screen, then tells the server.
  /// If the server refuses, the next load shows the truth again.
  Future<void> markRead(String id) async {
    final list = items;
    if (list == null) return;
    final i = list.indexWhere((n) => n.id == id);
    if (i == -1 || list[i].isRead) return;
    items = [...list]..[i] = list[i].copyWith(isRead: true);
    unread = unread > 0 ? unread - 1 : 0;
    notifyListeners();
    try {
      unread = await _service.markRead(id);
      notifyListeners();
    } on ApiException {
      await load(quiet: true);
    }
  }

  /// Throws ApiException when the server refuses.
  Future<String> markAllRead() async {
    final message = await _service.markAllRead();
    items = [for (final n in items ?? const <AppNotification>[]) n.copyWith(isRead: true)];
    unread = 0;
    notifyListeners();
    return message;
  }

  void reset() {
    items = null;
    unread = 0;
    error = null;
    notifyListeners();
  }
}
