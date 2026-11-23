// The volunteer's runs (their home screen).
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/pickup.dart';
import '../services/pickup_service.dart';

class PickupsProvider extends ChangeNotifier {
  PickupsProvider(this._service);
  final PickupService _service;

  /// null until the first load finishes.
  List<Pickup>? items;
  String? error;

  /// Runs moved on during this visit: run id -> the status it had when the
  /// volunteer first tapped it (which decides its tab). The run stays in
  /// that tab with its new stamp and next button, so the card does not jump
  /// away mid-task. It moves to its real tab on the next load.
  final Map<String, String> movedHere = {};

  /// The status that decides which tab a run is listed under.
  String tabStatusOf(Pickup p) => movedHere[p.id] ?? p.status;

  Future<void> load() async {
    error = null;
    notifyListeners();
    try {
      items = await _service.mine();
      movedHere.clear();
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  /// [status]: picked_up, delivered or cancelled. Throws ApiException when
  /// the server refuses (for example after a double tap).
  Future<PickupResult> setStatus(String id, String status) async {
    final before = items?.where((p) => p.id == id).firstOrNull?.status;
    final result = await _service.setStatus(id, status);
    if (before != null) movedHere.putIfAbsent(id, () => before);
    items = [for (final p in items ?? const <Pickup>[]) p.id == id ? result.pickup : p];
    notifyListeners();
    return result;
  }

  void reset() {
    items = null;
    error = null;
    movedHere.clear();
    notifyListeners();
  }
}
