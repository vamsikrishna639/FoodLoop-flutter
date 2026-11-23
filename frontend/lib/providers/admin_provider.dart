// The admin's working lists:
//   - approved requests that still need a volunteer (Overview),
//   - the approved volunteers to choose from (assign dialog),
//   - every non-admin account (Approvals).
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/claim_request.dart';
import '../models/user.dart';
import '../services/admin_service.dart';
import '../services/pickup_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._pickups, this._admin);
  final PickupService _pickups;
  final AdminService _admin;

  // ---- Needs a volunteer ---------------------------------------------------

  /// null until the first load finishes.
  List<ClaimRequest>? queue;
  String? queueError;

  /// Requests assigned during this visit: claim id -> volunteer's name.
  /// They stay in the list with an ASSIGNED stamp, like decided requests on
  /// the donor's Board, and drop out on the next load.
  final Map<String, String> assignedHere = {};

  Future<void> loadQueue() async {
    queueError = null;
    notifyListeners();
    try {
      final fresh = await _pickups.unassigned();
      // Keep this visit's assigned slips in place at the top of the list.
      final kept = [for (final c in queue ?? const <ClaimRequest>[]) if (assignedHere.containsKey(c.id)) c];
      queue = [...kept, ...fresh.where((c) => !assignedHere.containsKey(c.id))];
    } on ApiException catch (e) {
      queueError = e.message;
    }
    notifyListeners();
  }

  // ---- Volunteers ----------------------------------------------------------

  List<AppUser>? volunteers;
  String? volunteersError;

  /// Read each time the assign dialog opens, so the "runs on" counts are current.
  Future<void> loadVolunteers() async {
    volunteersError = null;
    notifyListeners();
    try {
      volunteers = await _admin.users(status: 'approved', role: 'volunteer');
    } on ApiException catch (e) {
      volunteersError = e.message;
    }
    notifyListeners();
  }

  /// Throws ApiException when the server refuses. Returns the slip message.
  Future<String> assign(ClaimRequest claim, AppUser volunteer) async {
    final result = await _pickups.assign(claim.id, volunteer.id);
    assignedHere[claim.id] = volunteer.name;
    notifyListeners();
    return result.message;
  }

  // ---- Accounts ------------------------------------------------------------

  List<AppUser>? accounts;
  String? accountsError;

  /// Accounts approved or rejected during this visit. They stay under
  /// "Waiting" with their new stamp until the next load.
  final Set<String> decidedHere = {};

  Future<void> loadAccounts() async {
    accountsError = null;
    notifyListeners();
    try {
      accounts = await _admin.users();
      decidedHere.clear();
    } on ApiException catch (e) {
      accountsError = e.message;
    }
    notifyListeners();
  }

  /// Throws ApiException when the server refuses. Returns the slip message.
  Future<String> verify(AppUser user, {required bool approve}) async {
    final (updated, message) = await _admin.verify(user.id, approve: approve);
    decidedHere.add(user.id);
    accounts = [for (final u in accounts ?? const <AppUser>[]) u.id == user.id ? updated : u];
    notifyListeners();
    return message;
  }

  void reset() {
    queue = null;
    queueError = null;
    assignedHere.clear();
    volunteers = null;
    volunteersError = null;
    accounts = null;
    accountsError = null;
    decidedHere.clear();
    notifyListeners();
  }
}
