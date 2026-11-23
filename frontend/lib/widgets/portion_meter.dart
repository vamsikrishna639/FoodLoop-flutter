// Shows how many portions are left as a row of small plate/box icons that
// fill in as they get reserved. Large counts collapse to text plus a bar.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class PortionMeter extends StatelessWidget {
  const PortionMeter({
    super.key,
    required this.total,
    required this.reserved,
    required this.unit,
    this.onDark = false,
  });

  final int total;
  final int reserved;
  final String unit; // boxes | plates | kg | packets
  final bool onDark; // true when drawn on the chalkboard

  /// Above this many portions, icons would be too small to read.
  static const int maxIcons = 12;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final left = (total - reserved).clamp(0, total);
    final ink = onDark ? fl.chalk : fl.ink;
    final soft = onDark ? fl.chalkSoft : fl.inkSoft;
    final caption = fl.monoSmall.copyWith(color: soft);
    // kg is a weight, not a count of things, so it never draws icons.
    final useIcons = total <= maxIcons && unit != 'kg';

    final Widget visual = useIcons
        ? Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (var i = 0; i < total; i++)
                CustomPaint(
                  size: const Size.square(12),
                  painter: _PortionIconPainter(
                    color: ink,
                    filled: i < reserved, // reserved portions are inked in
                    round: unit == 'plates',
                  ),
                ),
            ],
          )
        : _SegmentBar(fraction: total == 0 ? 0 : reserved / total, ink: ink, track: soft);

    return Semantics(
      label: '$left of $total $unit left',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: FlSpace.xs),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '$left', style: fl.mono.copyWith(color: ink, fontWeight: FontWeight.w700)),
                TextSpan(text: ' / $total $unit left'.toUpperCase(), style: caption),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// One plate (circle) or box (square), outlined when free and solid when reserved.
class _PortionIconPainter extends CustomPainter {
  const _PortionIconPainter({required this.color, required this.filled, required this.round});
  final Color color;
  final bool filled;
  final bool round;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.75);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;
    if (round) {
      canvas.drawOval(rect, paint);
      if (!filled) {
        // inner rim of the plate
        canvas.drawOval(rect.deflate(2.6), Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.stroke);
      }
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  @override
  bool shouldRepaint(_PortionIconPainter old) =>
      old.filled != filled || old.color != color || old.round != round;
}

/// Ten small segments; used when there are too many portions for icons.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.fraction, required this.ink, required this.track});
  final double fraction; // reserved share, 0..1
  final Color ink;
  final Color track;

  @override
  Widget build(BuildContext context) {
    const segments = 10;
    final filled = (fraction * segments).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < segments; i++)
          Container(
            width: 9,
            height: 12,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < filled ? ink : null,
              border: Border.all(color: i < filled ? ink : track, width: 1.5),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
      ],
    );
  }
}
