// Talks to the /api/pickups endpoints. Knows nothing about the UI.
import '../core/api/api_client.dart';
import '../models/claim_request.dart';
import '../models/pickup.dart';

/// A pickup the server just changed, with its message for the slip.
class PickupResult {
  const PickupResult(this.pickup, this.message);
  final Pickup pickup;
  final String message;
}

class PickupService {
  PickupService(this._api);
  final ApiClient _api;

  PickupResult _parseOne(ApiResult res) =>
      PickupResult(Pickup.fromJson(res.data['pickup'] as Map<String, dynamic>), res.message);

  /// Volunteer: their own runs, newest first.
  Future<List<Pickup>> mine() async {
    final data = (await _api.get('/pickups/mine')).data;
    return [for (final p in data['pickups'] as List) Pickup.fromJson(p as Map<String, dynamic>)];
  }

  /// Volunteer: move a run on. [status] is picked_up, delivered or cancelled.
  Future<PickupResult> setStatus(String id, String status) async =>
      _parseOne(await _api.patch('/pickups/$id/status', body: {'status': status}));

  /// Admin: approved requests that still need a volunteer.
  Future<List<ClaimRequest>> unassigned() async {
    final data = (await _api.get('/pickups/unassigned')).data;
    return [for (final c in data['claims'] as List) ClaimRequest.fromJson(c as Map<String, dynamic>)];
  }

  /// Admin: give a request to a volunteer.
  Future<PickupResult> assign(String claimId, String volunteerId) async => _parseOne(
        await _api.post('/pickups/assign', body: {'claimRequestId': claimId, 'volunteerId': volunteerId}),
      );
}
