// Talks to the /api/claims endpoints. Knows nothing about the UI.
import '../core/api/api_client.dart';
import '../models/claim_request.dart';

/// A claim the server just changed, with its message for the slip
/// (e.g. "Approved 6 packets of Veg Grilled Sandwiches").
class ClaimResult {
  const ClaimResult(this.claim, this.message);
  final ClaimRequest claim;
  final String message;
}

class ClaimService {
  ClaimService(this._api);
  final ApiClient _api;

  List<ClaimRequest> _parseList(dynamic data) => [
        for (final item in (data['claims'] as List)) ClaimRequest.fromJson(item as Map<String, dynamic>),
      ];

  ClaimResult _parseOne(ApiResult res) =>
      ClaimResult(ClaimRequest.fromJson(res.data['claim'] as Map<String, dynamic>), res.message);

  /// Recipient: their own requests, newest first.
  Future<List<ClaimRequest>> mine() async => _parseList((await _api.get('/claims/mine')).data);

  /// Donor: requests for their listings, pending ones first.
  Future<List<ClaimRequest>> incoming() async => _parseList((await _api.get('/claims/incoming')).data);

  Future<ClaimResult> create(String listingId, int quantity, String note) async => _parseOne(
        await _api.post('/claims', body: {'listingId': listingId, 'requestedQuantity': quantity, 'note': note}),
      );

  Future<ClaimResult> approve(String id) async => _parseOne(await _api.patch('/claims/$id/approve'));
  Future<ClaimResult> reject(String id) async => _parseOne(await _api.patch('/claims/$id/reject'));
  Future<ClaimResult> cancel(String id) async => _parseOne(await _api.patch('/claims/$id/cancel'));
}
