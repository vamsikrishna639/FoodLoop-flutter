// State for the listings a donor manages (and, for an admin, every listing).
// Used by the donor's Board, the Listings page and the post/edit form.
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/food_listing.dart';
import '../services/food_service.dart';

class ListingsProvider extends ChangeNotifier {
  ListingsProvider(this._service);
  final FoodService _service;

  /// null until the first load finishes.
  List<FoodListing>? items;
  bool loading = false;
  String? error;

  /// Admins see every listing; donors see only their own.
  bool _all = false;

  List<FoodListing> get open => (items ?? []).where((l) => l.isOpen).toList();
  List<FoodListing> get closed => (items ?? []).where((l) => !l.isOpen).toList();

  Future<void> load({bool all = false}) async {
    _all = all;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = all ? await _service.list() : await _service.mine();
      // The admin view is newest first, like the donor's.
      if (all) result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      items = result;
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(all: _all);

  /// Throws ApiException (with fieldErrors) when the server refuses it.
  Future<SavedListing> create(ListingDraft draft) async {
    final saved = await _service.create(draft);
    // If the list has not been loaded yet, the page will load it (with the
    // new token) when it opens; do not pretend it holds only this one.
    if (items != null) items = [saved.listing, ...items!];
    notifyListeners();
    return saved;
  }

  Future<SavedListing> update(String id, ListingDraft draft) async {
    final saved = await _service.update(id, draft);
    items = [for (final l in items ?? <FoodListing>[]) l.id == id ? saved.listing : l];
    notifyListeners();
    return saved;
  }

  /// Puts a fresher copy of one listing in the list, e.g. after an approval
  /// reserved some of it.
  void replace(FoodListing listing) {
    final list = items;
    if (list == null) return;
    final i = list.indexWhere((l) => l.id == listing.id);
    if (i == -1) return;
    items = [...list]..[i] = listing;
    notifyListeners();
  }

  /// The loaded copy of a listing, if there is one.
  FoodListing? byId(String id) {
    for (final l in items ?? const <FoodListing>[]) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<String> delete(String id) async {
    final message = await _service.delete(id);
    items = [for (final l in items ?? <FoodListing>[]) if (l.id != id) l];
    notifyListeners();
    return message;
  }

  void reset() {
    items = null;
    loading = false;
    error = null;
    _all = false;
    notifyListeners();
  }
}
