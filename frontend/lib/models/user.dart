// A FoodLoop account, as returned by the backend.

enum UserRole {
  donor('donor', 'Donor', 'I run a canteen and have surplus food'),
  recipient('recipient', 'Recipient', 'I collect food for people who need it'),
  volunteer('volunteer', 'Volunteer', 'I pick up and deliver food'),
  admin('admin', 'Admin', 'I manage accounts and assignments');

  const UserRole(this.apiValue, this.label, this.blurb);
  final String apiValue;
  final String label;
  final String blurb;

  static UserRole fromApi(String? v) =>
      values.firstWhere((r) => r.apiValue == v, orElse: () => UserRole.recipient);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.organization,
    required this.verificationStatus,
    this.createdAt,
    this.activeRuns = 0,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final String organization;
  final String verificationStatus; // pending | approved | rejected
  final DateTime? createdAt; // when they registered (shown to the admin)

  /// Volunteers only, in the admin's lists: runs they have on the go.
  final int activeRuns;

  bool get isPending => verificationStatus == 'pending';

  bool get isApproved => verificationStatus == 'approved';
  bool get isRejected => verificationStatus == 'rejected';

  /// "Ananya Rao" -> "AR". Used in the user chip.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: UserRole.fromApi(json['role']?.toString()),
        phone: (json['phone'] ?? '').toString(),
        organization: (json['organization'] ?? '').toString(),
        verificationStatus: (json['verificationStatus'] ?? 'pending').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal(),
        activeRuns: (json['activeRuns'] as num?)?.toInt() ?? 0,
      );
}
