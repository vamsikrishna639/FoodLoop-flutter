// A food listing ("token"), as returned by /api/foods.
import '../widgets/status_stamp.dart';
import '../widgets/veg_marker.dart';

/// The units a listing can be measured in, in the order the form shows them.
const List<String> kListingUnits = ['plates', 'boxes', 'packets', 'kg'];

class FoodListing {
  const FoodListing({
    required this.id,
    required this.tokenNumber,
    required this.title,
    required this.description,
    required this.quantity,
    required this.reservedQuantity,
    required this.unit,
    required this.location,
    required this.preparedAt,
    required this.pickupDeadline,
    required this.foodType,
    required this.allergenNotes,
    required this.imageUrl,
    required this.status,
    required this.donorId,
    required this.donorName,
    required this.createdAt,
  });

  final String id;
  final String tokenNumber; // FL-0042
  final String title;
  final String description;
  final int quantity;
  final int reservedQuantity;
  final String unit; // plates | boxes | packets | kg
  final String location;
  final DateTime preparedAt;
  final DateTime pickupDeadline;
  final FoodType foodType;
  final String allergenNotes;
  final String imageUrl;
  final String status; // available | fully_reserved | expired | completed
  final String donorId;
  final String donorName;
  final DateTime createdAt;

  /// Portions nobody has been promised yet.
  int get available => (quantity - reservedQuantity).clamp(0, quantity);

  /// The server marks overdue listings as expired when they are read, but
  /// a card that stays on screen can pass its deadline in the meantime, so
  /// the app checks the clock too.
  bool get isExpired => status == 'expired' || pickupDeadline.isBefore(DateTime.now());

  /// Open = still on the counter (it can be edited and, later, requested).
  bool get isOpen => !isExpired && status != 'completed';

  /// Recipients can ask for some of it.
  bool get canRequest => isOpen && available > 0;

  /// Under an hour left: matches the "closing soon" filter and the turmeric ring.
  bool get isClosingSoon =>
      isOpen && pickupDeadline.difference(DateTime.now()) <= const Duration(hours: 1);

  StampKind get stamp {
    if (status == 'completed') return StampKind.completed;
    if (isExpired) return StampKind.expired;
    return StampKind.forListing(status);
  }

  /// Hero tag shared by the card in the list and the card on the detail page.
  String get heroTag => 'token-$id';

  factory FoodListing.fromJson(Map<String, dynamic> json) {
    // donorId arrives "populated" as {_id, name, organization}; fall back to
    // a plain id string just in case.
    final donor = json['donorId'];
    final donorMap = donor is Map ? donor : const {};

    DateTime date(String key) =>
        DateTime.tryParse((json[key] ?? '').toString())?.toLocal() ?? DateTime.now();
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;
    String text(String key) => (json[key] ?? '').toString();

    return FoodListing(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      tokenNumber: text('tokenNumber'),
      title: text('title'),
      description: text('description'),
      quantity: number('quantity'),
      reservedQuantity: number('reservedQuantity'),
      unit: text('unit'),
      location: text('location'),
      preparedAt: date('preparedAt'),
      pickupDeadline: date('pickupDeadline'),
      foodType: FoodType.fromApi(json['foodType']?.toString()),
      allergenNotes: text('allergenNotes'),
      imageUrl: text('imageUrl'),
      status: text('status'),
      donorId: (donorMap['_id'] ?? (donor is String ? donor : '')).toString(),
      donorName: (donorMap['organization']?.toString().isNotEmpty ?? false)
          ? donorMap['organization'].toString()
          : (donorMap['name'] ?? 'Canteen').toString(),
      createdAt: date('createdAt'),
    );
  }
}

/// What the post/edit form sends. Dates go out in UTC ISO format.
class ListingDraft {
  ListingDraft({
    required this.title,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.preparedAt,
    required this.pickupDeadline,
    required this.foodType,
    required this.allergenNotes,
    required this.imageUrl,
  });

  final String title;
  final String description;
  final int quantity;
  final String unit;
  final String location;
  final DateTime preparedAt;
  final DateTime pickupDeadline;
  final FoodType foodType;
  final String allergenNotes;
  final String imageUrl;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'location': location,
        'preparedAt': preparedAt.toUtc().toIso8601String(),
        'pickupDeadline': pickupDeadline.toUtc().toIso8601String(),
        'foodType': foodType.apiValue,
        'allergenNotes': allergenNotes,
        'imageUrl': imageUrl,
      };
}
