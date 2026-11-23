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

  /// "just now", "8m ago", "2h 05m ago", then "Yesterday, 4:30 PM".
  /// The same compact units as the countdowns ("1h 44m"), so the app writes
  /// a length of time one way everywhere.
  static String ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 12) {
      final m = d.inMinutes % 60;
      return m == 0 ? '${d.inHours}h ago' : '${d.inHours}h ${m.toString().padLeft(2, '0')}m ago';
    }
    return dayTime(t);
  }

  /// Like [ago], but within a list already grouped by day it never repeats
  /// the date: older lines show just the clock time ("4:30 PM").
  static String agoInDay(DateTime t) {
    final d = DateTime.now().difference(t);
    return d.inHours < 12 ? ago(t) : time(t);
  }

  /// Joins a SHORT last word to the word before it with a non-breaking space,
  /// so a heading or sentence never ends on a line holding only "2" or "in.".
  /// Long last words are left alone: gluing "Grilled Sandwiches" together
  /// would strand "Veg" on its own line instead.
  static String noOrphan(String s) {
    final t = s.trimRight();
    final i = t.lastIndexOf(' ');
    if (i <= 0 || t.length - i - 1 > 5) return s;
    return '${t.substring(0, i)} ${t.substring(i + 1)}';
  }

  /// "4:30 PM" that never breaks between the time and AM/PM.
  static String timeKept(DateTime t) => time(t).replaceAll(' ', ' ');

  /// Indian mobile numbers in two groups of five ("90000 00003"). Anything
  /// that is not ten plain digits is shown as it was typed.
  static String phone(String p) {
    final digits = p.replaceAll(RegExp(r'[\s-]'), '');
    final m = RegExp(r'^(\+91)?(\d{5})(\d{5})$').firstMatch(digits);
    if (m == null) return p;
    return [if (m[1] != null) '+91', m[2], m[3]].join(' ');
  }

  /// "12 boxes", "1 kg", "1 plate".
  static String quantity(int n, String unit) {
    if (n == 1 && unit.endsWith('s')) return '1 ${unit.substring(0, unit.length - 1)}';
    return '$n $unit';
  }
}
