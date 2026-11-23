// Keeps the bell badge and the activity feed up to date by asking the
// server again every [interval] - but only while the app is in front of
// the user.
//
// Polling stops when:
//   - nobody approved is signed in, or
//   - the app is hidden: the browser tab is in the background or minimised,
//     or the Android app is in the background.
// When the app comes back to the front it refreshes at once, then carries on.
//
// Flutter reports both cases through AppLifecycleState. On the web the
// engine maps the page's visibility to it: a hidden tab is "hidden", and a
// visible tab is "resumed" (or "inactive" while the window has no focus).
// An inactive window is still on screen, so it keeps polling.
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'activity_provider.dart';
import 'notifications_provider.dart';

class LiveUpdates {
  LiveUpdates({required this.notifications, required this.activity, this.interval = const Duration(seconds: 20)}) {
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  final NotificationsProvider notifications;
  final ActivityProvider activity;
  final Duration interval;

  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _signedIn = false;
  bool _visible = true;

  /// True while a timer is running. Shown nowhere; handy when testing.
  bool get polling => _timer != null;

  /// Called by main.dart whenever the signed-in user changes.
  void setSignedIn(bool signedIn) {
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    _sync(refreshNow: signedIn);
  }

  void _onLifecycle(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    if (visible == _visible) return;
    _visible = visible;
    // Coming back to the front: catch up straight away.
    _sync(refreshNow: visible);
  }

  /// Starts or stops the timer to match the current state.
  void _sync({required bool refreshNow}) {
    final shouldPoll = _signedIn && _visible;
    if (!shouldPoll) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (refreshNow) tick();
    _timer ??= Timer.periodic(interval, (_) => tick());
  }

  /// One round of updates. The feed is only fetched while a rail shows it.
  Future<void> tick() async {
    await notifications.load(quiet: true);
    if (activity.watched) await activity.load();
  }

  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
  }
}
