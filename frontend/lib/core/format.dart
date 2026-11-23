// Date and time formatting used across the app, in one place.
import 'package:intl/intl.dart';

abstract final class Fmt {
  static final DateFormat _time = DateFormat('h:mm a'); // 4:30 PM
  static final DateFormat _dayMonth = DateFormat('EEE d MMM'); // Sat 14 Nov

  /// "4:30 PM"
  static String time(DateTime t) => _time.format(t);

  /// "Today, 4:30 PM", "Tomorrow, 9:00 AM", "Yesterday, 8:15 PM" or
  /// "Sat 14 Nov, 4:30 PM".
  static String dayTime(DateTime t) => '${day(t)}, ${time(t)}';

  /// "Today", "Tomorrow", "Yesterday" or "Sat 14 Nov".
  static String day(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(t.year, t.month, t.day).difference(today).inDays;
    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => _dayMonth.format(t),
    };
  }

  /// "just now", "8 min ago", "2 h ago", then "Yesterday, 4:30 PM".
  static String ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 12) return '${d.inHours} h ago';
    return dayTime(t);
  }

  /// "12 boxes", "1 kg", "1 plate".
  static String quantity(int n, String unit) {
    if (n == 1 && unit.endsWith('s')) return '1 ${unit.substring(0, unit.length - 1)}';
    return '$n $unit';
  }
}
