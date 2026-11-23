// One in-app notification, as returned by /api/notifications.

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;

  /// claim_submitted | claim_approved | claim_rejected | volunteer_assigned
  /// | delivered | account_approved
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  /// The short printed word shown beside the message, so the kind of news
  /// is readable at a glance without relying on an icon or colour.
  String get word => switch (type) {
        'claim_submitted' => 'NEW REQUEST',
        'claim_approved' => 'APPROVED',
        'claim_rejected' => 'TURNED DOWN',
        'volunteer_assigned' => 'PICKUP',
        'delivered' => 'DELIVERED',
        'account_approved' => 'ACCOUNT',
        _ => 'NOTE',
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        isRead: json['isRead'] == true,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      );
}
