// The Indian food marking: green square + dot (veg), red square + triangle
// (non-veg). "Mixed" shows both side by side.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

enum FoodType {
  veg('veg', 'Veg'),
  nonVeg('non-veg', 'Non-veg'),
  mixed('mixed', 'Mixed');

  const FoodType(this.apiValue, this.label);
  final String apiValue; // value used by the backend
  final String label;

  static FoodType fromApi(String? v) =>
      values.firstWhere((t) => t.apiValue == v, orElse: () => FoodType.veg);
}

class VegMarker extends StatelessWidget {
  const VegMarker({super.key, required this.type, this.size = 16, this.showLabel = false});

  final FoodType type;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    Widget mark(bool veg) => CustomPaint(
          size: Size.square(size),
          painter: _MarkerPainter(color: veg ? fl.leaf : fl.chilliDeep, veg: veg),
        );

    return Semantics(
      label: '${type.label} food',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type != FoodType.nonVeg) mark(true),
            if (type == FoodType.mixed) const SizedBox(width: 3),
            if (type != FoodType.veg) mark(false),
            if (showLabel) ...[
              const SizedBox(width: FlSpace.sm),
              Text(type.label.toUpperCase(), style: fl.monoSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter({required this.color, required this.veg});
  final Color color;
  final bool veg;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.11;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke), Radius.circular(s * 0.14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
    final fill = Paint()..color = color;
    if (veg) {
      canvas.drawCircle(Offset(s / 2, s / 2), s * 0.22, fill);
    } else {
      // upward triangle
      canvas.drawPath(
        Path()
          ..moveTo(s / 2, s * 0.27)
          ..lineTo(s * 0.74, s * 0.70)
          ..lineTo(s * 0.26, s * 0.70)
          ..close(),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color || old.veg != veg;
}
