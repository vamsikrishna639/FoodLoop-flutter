// A status shown as a rubber stamp: uppercase mono text in a rounded border,
// tilted a few degrees, with slightly uneven ink.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

/// Every status the app can show. The label is always printed, so a stamp
/// never relies on colour alone.
enum StampKind {
  available('AVAILABLE'),
  reserved('RESERVED'),
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),
  assigned('ASSIGNED'),
  pickedUp('PICKED UP'),
  delivered('DELIVERED'),
  completed('COMPLETED'),
  expired('EXPIRED');

  const StampKind(this.label);
  final String label;

  Color color(FoodLoopTokens fl) => switch (this) {
        available || approved || delivered || completed => fl.leaf,
        reserved => fl.turmericDeep,
        rejected => fl.chilliDeep,
        pending => fl.inkSoft,
        assigned || pickedUp => fl.ink,
        cancelled || expired => fl.stampGrey,
      };

  /// Maps a listing status from the API to a stamp.
  static StampKind forListing(String status) => switch (status) {
        'fully_reserved' => reserved,
        'expired' => expired,
        'completed' => completed,
        _ => available,
      };

  /// Maps a claim status from the API to a stamp.
  static StampKind forClaim(String status) => switch (status) {
        'approved' => approved,
        'rejected' => rejected,
        'cancelled' => cancelled,
        _ => pending,
      };

  /// Maps a pickup status from the API to a stamp.
  static StampKind forPickup(String status) => switch (status) {
        'picked_up' => pickedUp,
        'delivered' => delivered,
        'cancelled' => cancelled,
        _ => assigned,
      };
}

class StatusStamp extends StatelessWidget {
  const StatusStamp(this.kind, {super.key, this.scale = 1, this.label, this.color, this.angle = -6});

  /// Any text as a stamp (used for role stamps such as "DONOR").
  const StatusStamp.custom(String this.label, {super.key, this.scale = 1, this.color, this.angle = -6})
      : kind = null;

  final StampKind? kind;
  final String? label;
  final Color? color;
  final double scale; // 1 = normal, 1.6 = large feature stamp
  final double angle; // degrees

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final text = label ?? kind!.label;
    final ink = color ?? kind?.color(fl) ?? fl.ink;
    final doubleBorder = kind == StampKind.delivered;
    final crossed = kind == StampKind.expired;

    Widget box = Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: 2 * scale.clamp(1, 1.5)),
        borderRadius: BorderRadius.circular(FlRadius.stamp),
      ),
      child: Text(text, style: fl.stamp.copyWith(color: ink, fontSize: 12 * scale)),
    );

    if (doubleBorder) {
      box = Container(
        padding: EdgeInsets.all(2 * scale),
        decoration: BoxDecoration(
          border: Border.all(color: ink, width: 1),
          borderRadius: BorderRadius.circular(FlRadius.stamp + 2),
        ),
        child: box,
      );
    }
    if (crossed) {
      box = CustomPaint(foregroundPainter: _StrikePainter(ink, scale), child: box);
    }

    return Semantics(
      label: 'Status: $text',
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: angle * math.pi / 180,
          // Uneven ink: a mask whose opacity varies across the stamp, the way
          // a real rubber stamp never prints perfectly evenly.
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF000000), Color(0xD1000000), Color(0xFF000000), Color(0xC4000000), Color(0xF2000000)],
              stops: [0, 0.3, 0.52, 0.78, 1],
            ).createShader(rect),
            child: box,
          ),
        ),
      ),
    );
  }
}

/// The strike-through line on an EXPIRED stamp.
class _StrikePainter extends CustomPainter {
  const _StrikePainter(this.color, this.scale);
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(-3, size.height * 0.68),
      Offset(size.width + 3, size.height * 0.32),
      Paint()
        ..color = color
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.color != color;
}
