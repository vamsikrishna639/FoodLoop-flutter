// Shared "paper" shapes: the token slip outline, the torn receipt edge and
// dotted lines. Used by TokenCard, SkeletonToken, ReceiptTimeline and others.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

/// Outline of a canteen token slip: a rounded rectangle with a semicircle
/// notch cut out of the left and right edges, [stubHeight] above the bottom.
Path tokenSlipPath(Size size, double stubHeight) {
  final notchY = size.height - stubHeight;
  final body = Path()
    ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(FlRadius.slip)));
  final notches = Path()
    ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: FlRadius.notch))
    ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: FlRadius.notch));
  // body minus the two circles
  return Path.combine(PathOperation.difference, body, notches);
}

/// Clips its child to the token slip shape.
class TokenSlipClipper extends CustomClipper<Path> {
  const TokenSlipClipper(this.stubHeight);
  final double stubHeight;

  @override
  Path getClip(Size size) => tokenSlipPath(size, stubHeight);

  @override
  bool shouldReclip(TokenSlipClipper old) => old.stubHeight != stubHeight;
}

/// Paints the slip's outline (a clip removes normal borders) and, when
/// [lifted], a short soft shadow underneath, as if the slip left the table.
class TokenSlipPainter extends CustomPainter {
  const TokenSlipPainter({
    required this.stubHeight,
    required this.lineColor,
    required this.shadowColor,
    this.lifted = false,
  });

  final double stubHeight;
  final Color lineColor;
  final Color shadowColor;
  final bool lifted;

  @override
  void paint(Canvas canvas, Size size) {
    final path = tokenSlipPath(size, stubHeight);
    if (lifted) {
      canvas.drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..color = shadowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(TokenSlipPainter old) =>
      old.lifted != lifted || old.lineColor != lineColor || old.stubHeight != stubHeight;
}

/// Outline of a printed receipt: straight sides, zigzag "torn" top and bottom.
Path receiptPath(Size size, {double tooth = 6}) {
  final count = (size.width / (tooth * 2)).round().clamp(4, 400);
  final step = size.width / count;
  final path = Path()..moveTo(0, tooth);
  // top edge, left to right: up to a point, back down
  for (var i = 0; i < count; i++) {
    path
      ..lineTo(step * i + step / 2, 0)
      ..lineTo(step * (i + 1), tooth);
  }
  path.lineTo(size.width, size.height - tooth);
  // bottom edge, right to left
  for (var i = count; i > 0; i--) {
    path
      ..lineTo(step * i - step / 2, size.height)
      ..lineTo(step * (i - 1), size.height - tooth);
  }
  return path..close();
}

class ReceiptClipper extends CustomClipper<Path> {
  const ReceiptClipper();

  @override
  Path getClip(Size size) => receiptPath(size);

  @override
  bool shouldReclip(ReceiptClipper old) => false;
}

class ReceiptOutlinePainter extends CustomPainter {
  const ReceiptOutlinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      receiptPath(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ReceiptOutlinePainter old) => old.color != color;
}

/// A horizontal row of dots. Used for perforations and receipt leaders.
class DottedLine extends StatelessWidget {
  const DottedLine({super.key, this.color, this.dot = 2, this.gap = 5, this.height = 2});

  final Color? color;
  final double dot;
  final double gap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DottedLinePainter(color ?? context.fl.perforation, dot, gap),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter(this.color, this.dot, this.gap);
  final Color color;
  final double dot;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final y = size.height / 2;
    for (double x = dot / 2; x < size.width; x += dot + gap) {
      canvas.drawCircle(Offset(x, y), dot / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}
