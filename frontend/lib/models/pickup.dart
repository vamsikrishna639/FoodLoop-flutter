// A volunteer's run, as returned by /api/pickups/mine: collect an approved
// request at the canteen and take it to the recipient.
import '../widgets/status_stamp.dart';
import 'food_listing.dart';

class Pickup {
  const Pickup({
    required this.id,
    required this.status,
    required this.assignedAt,
    required this.requestedQuantity,
    required this.note,
    required this.recipientName,
    required this.recipientOrg,
    required this.recipientPhone,
    required this.listing,
    this.pickedUpAt,
    this.deliveredAt,
  });

  final String id;
  final String status; // assigned | picked_up | delivered | cancelled
  final DateTime assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final int requestedQuantity;
  final String note;
  final String recipientName;
  final String recipientOrg;
  final String recipientPhone;
  final FoodListing listing; // what to collect, and from where

  bool get isAssigned => status == 'assigned';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  StampKind get stamp => StampKind.forPickup(status);

  factory Pickup.fromJson(Map<String, dynamic> json) {
    final claim = json['claim'] is Map ? json['claim'] as Map : const {};
    final r = json['recipient'] is Map ? json['recipient'] as Map : const {};
    final listing = json['listing'];
    return Pickup(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      status: (json['pickupStatus'] ?? 'assigned').toString(),
      assignedAt: _date(json['assignedAt']) ?? DateTime.now(),
      pickedUpAt: _date(json['pickedUpAt']),
      deliveredAt: _date(json['deliveredAt']),
      requestedQuantity: (claim['requestedQuantity'] as num?)?.toInt() ?? 0,
      note: (claim['note'] ?? '').toString(),
      recipientName: (r['name'] ?? 'A recipient').toString(),
      recipientOrg: (r['organization'] ?? '').toString(),
      recipientPhone: (r['phone'] ?? '').toString(),
      listing: FoodListing.fromJson(listing is Map<String, dynamic> ? listing : const {}),
    );
  }
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
