// Talks to the /api/foods endpoints (and the public /api/impact figure).
// Knows nothing about the UI.
import '../core/api/api_client.dart';
import '../models/food_listing.dart';

/// The result of a create/update: the saved listing and the server's message
/// (e.g. "Token #FL-0009 is on the counter"), which the UI shows in a slip.
class SavedListing {
  const SavedListing(this.listing, this.message);
  final FoodListing listing;
  final String message;
}

class FoodService {
  FoodService(this._api);
  final ApiClient _api;

  List<FoodListing> _parseList(dynamic data) => [
        for (final item in (data['listings'] as List))
          FoodListing.fromJson(item as Map<String, dynamic>),
      ];

  /// Browse listings. [statuses] is sent as a comma-separated list.
  Future<List<FoodListing>> list({
    List<String> statuses = const [],
    String? foodType,
    String? search,
    bool closingSoon = false,
  }) async {
    final res = await _api.get('/foods', query: {
      'status': statuses.join(','),
      'foodType': foodType,
      'search': search,
      'closingSoon': closingSoon ? 'true' : null,
    });
    return _parseList(res.data);
  }

  /// The signed-in donor's own listings, newest first.
  Future<List<FoodListing>> mine() async => _parseList((await _api.get('/foods/mine')).data);

  Future<FoodListing> get(String id) async {
    final res = await _api.get('/foods/$id');
    return FoodListing.fromJson(res.data['listing'] as Map<String, dynamic>);
  }

  Future<SavedListing> create(ListingDraft draft) async {
    final res = await _api.post('/foods', body: draft.toJson());
    return SavedListing(FoodListing.fromJson(res.data['listing'] as Map<String, dynamic>), res.message);
  }

  Future<SavedListing> update(String id, ListingDraft draft) async {
    final res = await _api.patch('/foods/$id', body: draft.toJson());
    return SavedListing(FoodListing.fromJson(res.data['listing'] as Map<String, dynamic>), res.message);
  }

  /// Returns the server's message ("Token #FL-0009 deleted").
  Future<String> delete(String id) async => (await _api.delete('/foods/$id')).message;

  /// Total portions delivered so far (public, works before login).
  Future<int> portionsDelivered() async {
    final res = await _api.get('/impact');
    return (res.data['portionsDelivered'] as num).toInt();
  }
}
