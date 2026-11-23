// A claim request, as returned by /api/claims. It carries the listing it is
// for, who asked, and (once an admin assigns one) the volunteer's pickup.
import '../widgets/status_stamp.dart';
import 'food_listing.dart';

/// The pickup attached to an approved request (created in Stage 4; the seed
/// already has some).
class ClaimPickup {
  const ClaimPickup({
    required this.status,
    required this.volunteerName,
    required this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  final String status; // assigned | picked_up | delivered
  final String volunteerName;
  final DateTime assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  factory ClaimPickup.fromJson(Map<String, dynamic> json) => ClaimPickup(
        status: (json['pickupStatus'] ?? 'assigned').toString(),
        volunteerName: (json['volunteerName'] ?? '').toString(),
        assignedAt: _date(json['assignedAt']) ?? DateTime.now(),
        pickedUpAt: _date(json['pickedUpAt']),
        deliveredAt: _date(json['deliveredAt']),
      );
}

class ClaimRequest {
  const ClaimRequest({
    required this.id,
    required this.status,
    required this.requestedQuantity,
    required this.note,
    required this.createdAt,
    required this.listing,
    required this.recipientName,
    required this.recipientOrg,
    this.decidedAt,
    this.cancelledAt,
    this.pickup,
  });

  final String id;
  final String status; // pending | approved | rejected | cancelled
  final int requestedQuantity;
  final String note;
  final DateTime createdAt;
  final DateTime? decidedAt; // approved or turned down
  final DateTime? cancelledAt;
  final FoodListing listing;
  final String recipientName;
  final String recipientOrg;
  final ClaimPickup? pickup;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  /// Rule 7: a pending or approved request blocks a second one.
  bool get isOpen => isPending || isApproved;

  bool get isDelivered => pickup?.status == 'delivered';

  /// Still in progress for the recipient (shown under "Active").
  bool get isActive => isOpen && !isDelivered;

  /// The server refuses a cancel once a volunteer has the food.
  bool get canCancel => isOpen && (pickup == null || pickup!.status == 'assigned');

  /// The furthest step reached, as a stamp: DELIVERED beats APPROVED.
  StampKind get stamp {
    if (isApproved && pickup != null) return StampKind.forPickup(pickup!.status);
    return StampKind.forClaim(status);
  }

  factory ClaimRequest.fromJson(Map<String, dynamic> json) {
    final recipient = json['recipientId'];
    final r = recipient is Map ? recipient : const {};
    final listing = json['listingId'];
    final pickup = json['pickup'];

    return ClaimRequest(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      requestedQuantity: (json['requestedQuantity'] as num?)?.toInt() ?? 0,
      note: (json['note'] ?? '').toString(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      decidedAt: _date(json['decidedAt']),
      cancelledAt: _date(json['cancelledAt']),
      // The listing always arrives "populated" (a full object).
      listing: FoodListing.fromJson(listing is Map<String, dynamic> ? listing : const {}),
      recipientName: (r['name'] ?? 'A recipient').toString(),
      recipientOrg: (r['organization'] ?? '').toString(),
      pickup: pickup is Map<String, dynamic> ? ClaimPickup.fromJson(pickup) : null,
    );
  }
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
