// The activity feed in the desktop rail. LiveUpdates reloads it every few
// seconds, but only while the rail is on screen and the app is in the
// foreground.
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/activity_event.dart';
import '../services/dashboard_service.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._service);
  final DashboardService _service;

  /// null until the first load finishes.
  List<ActivityEvent>? events;
  String? error;

  /// Lines that were not there on the previous load. Only these fade in,
  /// so the first load and unchanged lines never animate.
  Set<String> fresh = {};

  /// How many activity rails are on screen. The poller skips the feed when
  /// this is 0 (phones and tablets have no rail).
  int _watchers = 0;
  bool get watched => _watchers > 0;
  void attach() => _watchers++;
  void detach() => _watchers = _watchers > 0 ? _watchers - 1 : 0;

  Future<void> load() async {
    try {
      final next = await _service.activity();
      final before = events;
      final seen = {for (final b in before ?? const <ActivityEvent>[]) b.id};
      fresh = before == null ? {} : {for (final e in next) if (!seen.contains(e.id)) e.id};
      events = next;
      error = null;
    } on ApiException catch (e) {
      // Keep the last good feed if there is one; the next poll tries again.
      if (events == null) error = e.message;
    }
    notifyListeners();
  }

  void reset() {
    events = null;
    error = null;
    fresh = {};
    notifyListeners();
  }
}
