// The 7-day deliveries chart (DESIGN.md section 8), drawn with fl_chart:
//   - leaf bars with square tops, today's bar in chilli,
//   - the value printed above each bar, so nothing depends on colour or hover,
//   - mono day labels, dotted perforation grid lines,
//   - a one-sentence summary for screen readers.
// It does not animate: the figures are data the admin reads, not decoration.
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import '../models/dashboard.dart';

class DeliveriesChart extends StatelessWidget {
  const DeliveriesChart({super.key, required this.days, this.height = 200});

  final List<DayTotal> days; // oldest first, today last
  final double height;

  static final DateFormat _weekday = DateFormat('EEE'); // Mon
  static final DateFormat _long = DateFormat('EEEE'); // Monday

  /// "Portions delivered in the last 7 days: Monday 18, ... Today 0. 82 in all."
  String _summary() {
    final parts = [
      for (final (i, d) in days.indexed) '${i == days.length - 1 ? 'today' : _long.format(d.date)} ${d.portions}',
    ];
    final total = days.fold<int>(0, (s, d) => s + d.portions);
    return 'Portions delivered in the last 7 days: ${parts.join(', ')}. $total in all.';
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final top = days.fold<int>(0, (m, d) => math.max(m, d.portions));
    // Head room above the tallest bar for its printed value; a week with no
    // deliveries still gets a sensible scale.
    final maxY = math.max(top * 1.3, 10).toDouble();
    final interval = _niceInterval(maxY);

    return Semantics(
      label: _summary(),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: false),
              borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: fl.controlBorder))),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(color: fl.perforation, strokeWidth: 1, dashArray: const [2, 4]),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: interval,
                    getTitlesWidget: (value, meta) => value == meta.max
                        ? const SizedBox.shrink() // the top line is head room, not a value
                        : Text(value.toInt().toString(), style: fl.monoSmall),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox.shrink();
                      final today = i == days.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: FlSpace.sm),
                        child: Text(
                          today ? 'TODAY' : _weekday.format(days[i].date).toUpperCase(),
                          style: fl.monoSmall.copyWith(
                            color: today ? fl.ink : fl.inkSoft,
                            fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (final (i, d) in days.indexed)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.portions.toDouble(),
                        width: 22,
                        color: i == days.length - 1 ? fl.chilli : fl.leaf,
                        borderRadius: BorderRadius.zero, // square tops: a printed bar
                        label: BarChartRodLabel(
                          show: true,
                          text: '${d.portions}',
                          style: fl.mono.copyWith(color: fl.ink, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
      ),
    );
  }

  /// A round step for the grid lines: 5, 10, 20, 25, 50...
  static double _niceInterval(double maxY) {
    final raw = maxY / 4;
    for (final step in [1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500]) {
      if (raw <= step) return step.toDouble();
    }
    return (raw / 1000).ceil() * 1000;
  }
}
