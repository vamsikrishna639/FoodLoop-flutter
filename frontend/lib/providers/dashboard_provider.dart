// The signed-in role's figures from /api/dashboard: the admin's Overview,
// the donor's tally, the recipient's "received so far" and the volunteer's
// run count all read from here.
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._service);
  final DashboardService _service;

  /// null until the first load finishes.
  DashboardStats? stats;
  String? error;

  Future<void> load() async {
    error = null;
    notifyListeners();
    try {
      stats = await _service.stats();
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  void reset() {
    stats = null;
    error = null;
    notifyListeners();
  }
}
