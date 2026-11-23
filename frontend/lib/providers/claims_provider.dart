// State for claim requests. A signed-in user only ever has one of two views:
//   - recipient: their own requests (My requests, and the listing detail
//     uses it to know whether they already asked for a token);
//   - donor: incoming requests for their listings (the Board's queue).
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/claim_request.dart';
import '../services/claim_service.dart';

class ClaimsProvider extends ChangeNotifier {
  ClaimsProvider(this._service);
  final ClaimService _service;

  /// null until the first load finishes.
  List<ClaimRequest>? items;
  bool loading = false;
  String? error;

  bool _incoming = false; // which list is loaded

  /// Requests the donor approved or turned down since the Board opened.
  /// They stay in the queue where they were, so the stamp lands where the
  /// donor is looking instead of the slip jumping to another list.
  final Set<String> decidedHere = {};

  /// The one request that was just approved, so only its slip plays the
  /// stamp drop. Cleared by the slip once it has played.
  String? justApproved;

  Future<void> load({required bool incoming}) async {
    _incoming = incoming;
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = incoming ? await _service.incoming() : await _service.mine();
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(incoming: _incoming);

  /// The recipient's open (pending or approved) request for a listing, if any.
  ClaimRequest? openFor(String listingId) {
    for (final c in items ?? const <ClaimRequest>[]) {
      if (c.isOpen && c.listing.id == listingId) return c;
    }
    return null;
  }

  void _put(ClaimRequest claim) {
    final list = items ?? <ClaimRequest>[];
    final i = list.indexWhere((c) => c.id == claim.id);
    items = i == -1 ? [claim, ...list] : ([...list]..[i] = claim);
  }

  /// Each action throws ApiException when the server refuses it.
  Future<ClaimResult> request(String listingId, int quantity, String note) async {
    final result = await _service.create(listingId, quantity, note);
    _put(result.claim);
    notifyListeners();
    return result;
  }

  Future<ClaimResult> approve(String id) async {
    final result = await _service.approve(id);
    decidedHere.add(id);
    justApproved = id;
    _put(result.claim);
    notifyListeners();
    return result;
  }

  Future<ClaimResult> reject(String id) async {
    final result = await _service.reject(id);
    decidedHere.add(id);
    _put(result.claim);
    notifyListeners();
    return result;
  }

  Future<ClaimResult> cancel(String id) async {
    final result = await _service.cancel(id);
    _put(result.claim);
    notifyListeners();
    return result;
  }

  /// Returns true once, for the slip whose stamp should drop.
  bool takeStampDrop(String id) {
    if (justApproved != id) return false;
    justApproved = null;
    return true;
  }

  /// Forget everything on sign-out.
  void reset() {
    items = null;
    loading = false;
    error = null;
    _incoming = false;
    decidedHere.clear();
    justApproved = null;
    notifyListeners();
  }
}
