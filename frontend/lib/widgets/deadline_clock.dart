// A small ring countdown to the pickup deadline, like a kitchen timer.
// Ink normally, turmeric under 1 hour, chilli under 15 minutes, and an
// EXPIRED stamp once the deadline has passed.
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import 'status_stamp.dart';

class DeadlineClock extends StatefulWidget {
  const DeadlineClock({super.key, required this.deadline, this.size = 40, this.onDark = false});

  final DateTime deadline;
  final double size;
  final bool onDark;

  /// The ring is full when this much time (or more) is left.
  static const Duration fullRing = Duration(hours: 6);

  /// "3h 05m", "45m", "50s".
  static String format(Duration d) {
    if (d.inHours >= 24) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return '${d.inSeconds.clamp(0, 59)}s';
  }

  @override
  State<DeadlineClock> createState() => _DeadlineClockState();
}

class _DeadlineClockState extends State<DeadlineClock> {
  Timer? _timer;

  Duration get _left => widget.deadline.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(DeadlineClock old) {
    super.didUpdateWidget(old);
    if (old.deadline != widget.deadline) _schedule();
  }

  // Tick every second in the final minute, otherwise every 20 seconds.
  // Nothing ticks once the deadline has passed.
  void _schedule() {
    _timer?.cancel();
    final left = _left;
    if (left.isNegative) return;
    final every = left.inMinutes < 1 ? const Duration(seconds: 1) : const Duration(seconds: 20);
    _timer = Timer(every, () {
      if (!mounted) return;
      setState(() {});
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final left = _left;

    if (left.isNegative) {
      return const StatusStamp(StampKind.expired, scale: 0.9);
    }

    final base = widget.onDark ? fl.chalk : fl.ink;
    final (Color ring, Color text, String note) = left.inMinutes < 15
        ? (fl.chilli, widget.onDark ? fl.chilli : fl.chilliDeep, 'HURRY')
        : left.inMinutes < 60
            ? (fl.turmeric, widget.onDark ? fl.turmeric : fl.turmericDeep, 'CLOSING')
            : (base, base, 'LEFT');

    final fraction =
        (left.inSeconds / DeadlineClock.fullRing.inSeconds).clamp(0.04, 1.0).toDouble();
    final label = DeadlineClock.format(left);

    return Semantics(
      label: 'Pickup closes in $label',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size.square(widget.size),
              painter: _RingPainter(
                fraction: fraction,
                color: ring,
                track: widget.onDark ? fl.chalkLine : fl.perforation,
              ),
            ),
            const SizedBox(width: FlSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: fl.mono.copyWith(color: text, fontWeight: FontWeight.w700)),
                Text(note, style: fl.monoSmall.copyWith(color: text)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.color, required this.track});
  final double fraction; // share of the ring that is still "time left"
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    // Time left, drawn clockwise from 12 o'clock.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = color,
    );
    // The timer's knob: a tick at 12 o'clock and a centre dot.
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, stroke + 3),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
