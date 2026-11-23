// The FoodLoop logo: a tiny chilli-red token slip next to the wordmark.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 32, this.showWordmark = true});

  final bool onDark; // true on the chalkboard sidebar
  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Semantics(
      label: 'FoodLoop',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size(size * 0.82, size),
              painter: _MarkPainter(fill: fl.chilli, cut: onDark ? fl.board : fl.paper, dot: fl.turmeric),
            ),
            if (showWordmark) ...[
              SizedBox(width: size * 0.3),
              Text(
                'FoodLoop',
                style: context.text.headlineSmall?.copyWith(
                  color: onDark ? fl.chalk : fl.ink,
                  fontSize: size * 0.72,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.fill, required this.cut, required this.dot});
  final Color fill, cut, dot;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // The slip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.2)),
      Paint()..color = fill,
    );
    // Two side notches and the perforation between them.
    final notch = Paint()..color = cut;
    final y = h * 0.64;
    canvas.drawCircle(Offset(0, y), w * 0.13, notch);
    canvas.drawCircle(Offset(w, y), w * 0.13, notch);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(w * (0.32 + i * 0.18), y), w * 0.035, notch);
    }
    // The "loop".
    canvas.drawCircle(
      Offset(w / 2, h * 0.34),
      w * 0.17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.1
        ..color = dot,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.fill != fill || old.cut != cut;
}
