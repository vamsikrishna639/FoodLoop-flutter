// The canteen menu board. It keeps its dark slate surface in BOTH themes,
// so the donor's "Today's Surplus" always reads as a chalkboard.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import 'paper_shapes.dart';

class Chalkboard extends StatelessWidget {
  const Chalkboard({super.key, required this.title, this.caption, this.trailing, required this.child});

  final String title;
  final String? caption; // small mono line under the title, e.g. the date
  final Widget? trailing; // e.g. a "Post food" button
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Container(
      decoration: BoxDecoration(
        color: fl.board,
        borderRadius: BorderRadius.circular(FlRadius.sharp),
        // The wooden frame around the slate.
        border: Border.all(color: fl.boardFrame, width: 6),
      ),
      padding: const EdgeInsets.all(FlSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(title, style: context.text.headlineMedium?.copyWith(color: fl.chalk)),
              ),
              if (trailing != null) ...[const SizedBox(width: FlSpace.md), trailing!],
            ],
          ),
          const SizedBox(height: FlSpace.sm),
          // A hand-drawn chalk underline: slightly wavy.
          SizedBox(
            height: 8,
            width: 160,
            child: CustomPaint(painter: _ChalkUnderlinePainter(fl.turmeric)),
          ),
          if (caption != null) ...[
            const SizedBox(height: FlSpace.sm),
            Text(caption!.toUpperCase(), style: fl.monoSmall.copyWith(color: fl.chalkSoft)),
          ],
          const SizedBox(height: FlSpace.lg),
          child,
        ],
      ),
    );
  }
}

/// One menu line: "Chicken Biryani ........ 12 boxes".
class ChalkItem extends StatelessWidget {
  const ChalkItem({super.key, required this.name, required this.trailing, this.note});

  final String name;
  final String trailing;
  final String? note; // small line under the name, e.g. "closes 4:30 PM"

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlSpace.sm),
      // The name may use up to 62% of the line. The dotted leader fills the
      // rest, so the quantity always ends at the right edge of the board.
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: context.text.titleLarge?.copyWith(color: fl.chalk)),
                  if (note != null) Text(note!, style: fl.monoSmall.copyWith(color: fl.chalkSoft)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(FlSpace.sm, 0, FlSpace.sm, 6),
                child: DottedLine(color: fl.chalkSoft.withValues(alpha: 0.5), dot: 2, gap: 5),
              ),
            ),
            Text(trailing, style: fl.mono.copyWith(color: fl.chalk, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ChalkUnderlinePainter extends CustomPainter {
  const _ChalkUnderlinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.3);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChalkUnderlinePainter old) => old.color != color;
}
