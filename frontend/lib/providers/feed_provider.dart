// State for the recipient's "Today's Counter": the listings on offer, the
// search text and the filter tags.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/food_listing.dart';
import '../services/food_service.dart';
import '../widgets/veg_marker.dart';

class FeedProvider extends ChangeNotifier {
  FeedProvider(this._service);
  final FoodService _service;

  /// null until the first load finishes.
  List<FoodListing>? items;
  bool loading = false;
  String? error;

  // Filters. Food type is one-of (or none); "closing soon" combines with it.
  String search = '';
  FoodType? foodType;
  bool closingSoon = false;

  bool get hasFilters => search.isNotEmpty || foodType != null || closingSoon;

  /// The list fades up only the first time it appears, not on every refresh.
  bool hasAnimatedIn = false;

  Timer? _debounce;
  int _requestId = 0; // used to ignore replies that arrive out of order

  /// The counter shows listings people can still look at: open ones and
  /// fully reserved ones (stamped RESERVED). Expired and completed are hidden.
  static const _statuses = ['available', 'fully_reserved'];

  Future<void> load() async {
    final id = ++_requestId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.list(
        statuses: _statuses,
        foodType: foodType?.apiValue,
        search: search,
        closingSoon: closingSoon,
      );
      if (id != _requestId) return; // a newer search has started since
      items = result;
    } on ApiException catch (e) {
      if (id != _requestId) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// Called on every keystroke; waits for a short pause before asking the server.
  void setSearch(String text) {
    search = text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  /// Tapping the selected type again clears it.
  void toggleFoodType(FoodType type) {
    foodType = foodType == type ? null : type;
    load();
  }

  void toggleClosingSoon() {
    closingSoon = !closingSoon;
    load();
  }

  void clearFilters() {
    search = '';
    foodType = null;
    closingSoon = false;
    load();
  }

  /// Keeps a listing that was re-read on the detail page up to date in the list.
  void replace(FoodListing listing) {
    final list = items;
    if (list == null) return;
    final i = list.indexWhere((l) => l.id == listing.id);
    if (i == -1) return;
    items = [...list]..[i] = listing;
    notifyListeners();
  }

  // ---- "Browse" action -----------------------------------------------------
  // The raised Browse button asks the feed to put the cursor in its search
  // field. The feed screen may not be on screen yet when the button is
  // pressed, so the request is stored here and the screen takes it once it
  // is built.
  bool _wantsSearchFocus = false;

  void requestSearchFocus() {
    _wantsSearchFocus = true;
    notifyListeners();
  }

  /// Returns true once per request.
  bool takeSearchFocusRequest() {
    final wanted = _wantsSearchFocus;
    _wantsSearchFocus = false;
    return wanted;
  }

  /// Forget everything on sign-out, so the next user starts fresh.
  void reset() {
    _debounce?.cancel();
    _requestId++;
    items = null;
    loading = false;
    error = null;
    search = '';
    foodType = null;
    closingSoon = false;
    hasAnimatedIn = false;
    _wantsSearchFocus = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
