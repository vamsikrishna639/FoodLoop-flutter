// The signed-in role's figures, from /api/dashboard.

/// One day of the 7-day series.
class DayTotal {
  const DayTotal({required this.date, required this.portions, required this.deliveries});
  final DateTime date; // local midnight
  final int portions;
  final int deliveries;

  factory DayTotal.fromJson(Map<String, dynamic> json) => DayTotal(
        // "2026-11-14" parses as local midnight, which is what we want.
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        portions: (json['portions'] as num?)?.toInt() ?? 0,
        deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
      );
}

class DashboardStats {
  const DashboardStats({required this.figures, required this.last7Days});

  /// Named counts, which differ per role. For example the admin gets
  /// portionsDelivered, deliveries, awaitingVolunteer, runsOnTheWay,
  /// pendingAccounts and openListings. A missing name reads as 0.
  final Map<String, int> figures;

  /// Oldest day first, today last.
  final List<DayTotal> last7Days;

  int operator [](String name) => figures[name] ?? 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final raw = json['figures'] is Map ? json['figures'] as Map : const {};
    return DashboardStats(
      figures: {for (final e in raw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0},
      last7Days: [
        for (final d in (json['last7Days'] as List? ?? const [])) DayTotal.fromJson(d as Map<String, dynamic>),
      ],
    );
  }
}
