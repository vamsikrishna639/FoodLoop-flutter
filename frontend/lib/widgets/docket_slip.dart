// An order docket: a slip with a tear-off stub on its LEFT edge, like the
// kitchen copy of an order. Used for the things that wait for a decision:
// a request on the donor's board, an approved request waiting for a
// volunteer, an account waiting for approval.
//
//   +--------o-------------------------------------+
//   |   6    :  Ananya Rao                APPROVED |
//   | PACKETS:  Asha Night Shelter · 12m ago       |
//   |        :  Veg Grilled Sandwiches             |
//   |        :  [ Approve ]  [ Turn down ]         |
//   +--------o-------------------------------------+
//
// The stub holds the one figure that matters (how much), the perforation
// has a notch at each end, and the body grows with its content.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class DocketSlip extends StatelessWidget {
  const DocketSlip({super.key, required this.stub, required this.child, this.stubWidth = 76});

  /// The figure on the stub, e.g. [DocketFigure].
  final Widget stub;
  final Widget child;
  final double stubWidth;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return CustomPaint(
      foregroundPainter: _DocketOutline(stubWidth, fl.line),
      child: ClipPath(
        clipper: _DocketClipper(stubWidth),
        child: ColoredBox(
          color: fl.surface,
          // The body sizes the slip; the stub's fill and the perforation are
          // stretched to its height behind it (no IntrinsicHeight needed).
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: stubWidth,
                child: ColoredBox(color: fl.surfaceSunken),
              ),
              Positioned(
                left: stubWidth - 1.5,
                top: FlRadius.notch + 3,
                bottom: FlRadius.notch + 3,
                width: 3,
                child: CustomPaint(painter: _VerticalDots(fl.perforation)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: stubWidth,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(FlSpace.sm, FlSpace.lg, FlSpace.sm, FlSpace.lg),
                      child: stub,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(FlSpace.lg, FlSpace.lg, FlSpace.lg, FlSpace.lg),
                      child: child,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The stub's printed figure: a big mono number over a small caption.
class DocketFigure extends StatelessWidget {
  const DocketFigure({super.key, required this.value, required this.caption});
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return ExcludeSemantics(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: fl.monoLarge.copyWith(fontSize: 24, height: 1.1)),
          ),
          const SizedBox(height: FlSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(caption.toUpperCase(), style: fl.monoSmall),
          ),
        ],
      ),
    );
  }
}

Path _docketPath(Size size, double stubWidth) {
  final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(FlRadius.slip)));
  final notches = Path()
    ..addOval(Rect.fromCircle(center: Offset(stubWidth, 0), radius: FlRadius.notch))
    ..addOval(Rect.fromCircle(center: Offset(stubWidth, size.height), radius: FlRadius.notch));
  return Path.combine(PathOperation.difference, body, notches);
}

class _DocketClipper extends CustomClipper<Path> {
  const _DocketClipper(this.stubWidth);
  final double stubWidth;

  @override
  Path getClip(Size size) => _docketPath(size, stubWidth);

  @override
  bool shouldReclip(_DocketClipper old) => old.stubWidth != stubWidth;
}

class _DocketOutline extends CustomPainter {
  const _DocketOutline(this.stubWidth, this.color);
  final double stubWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _docketPath(size, stubWidth),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_DocketOutline old) => old.color != color || old.stubWidth != stubWidth;
}

class _VerticalDots extends CustomPainter {
  const _VerticalDots(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = 1.5; y < size.height; y += 8) {
      canvas.drawCircle(Offset(size.width / 2, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_VerticalDots old) => old.color != color;
}
