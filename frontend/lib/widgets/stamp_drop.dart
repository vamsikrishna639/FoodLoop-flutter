// The signature moment (DESIGN.md section 4): when a donor approves a request,
// the APPROVED stamp drops onto the slip like a rubber stamp hitting paper.
//
//   start: scale 1.9, invisible, turned an extra -10 degrees
//   end:   scale 1, fully inked, at the stamp's own -6 degrees
//
// It is used ONLY for claim approval, so it stays special. With reduced
// motion the stamp does not fall or turn: it fades in at rest (120ms).
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class StampDrop extends StatefulWidget {
  const StampDrop({super.key, required this.play, required this.child});

  /// true: play the drop when this widget appears (or when [play] turns true).
  /// false: show the stamp at rest.
  final bool play;

  /// The stamp itself, usually StatusStamp(StampKind.approved).
  final Widget child;

  @override
  State<StampDrop> createState() => _StampDropState();
}

class _StampDropState extends State<StampDrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: FlMotion.stampDrop, value: 1);
  bool _started = false;
  bool _buzzed = false;
  bool _still = false; // reduced motion: fade only, no scale or turn

  // The ink is already fully visible a third of the way in, so the eye sees
  // the stamp while it lands, not a ghost that fades in at the end.
  late final Animation<double> _ink = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
  );
  // Scale and turn use the stamp curve, which overshoots very slightly, so
  // the stamp presses a hair past flat and settles.
  late final Animation<double> _land = CurvedAnimation(parent: _c, curve: FlMotion.stampCurve);

  @override
  void initState() {
    super.initState();
    // A light tap on the phone at the moment of impact, not on the button
    // press. (On the web this does nothing.)
    _c.addListener(() {
      if (!_buzzed && _c.isAnimating && _c.value >= 0.7) {
        _buzzed = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion is read from MediaQuery, which needs the context, so
    // the first play happens here rather than in initState.
    if (widget.play && !_started) _drop();
  }

  @override
  void didUpdateWidget(StampDrop old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _drop();
  }

  void _drop() {
    _started = true;
    _still = FlMotion.reduced(context);
    if (_still) {
      // Gentler, not nothing: a short fade at rest, and the tap at once.
      HapticFeedback.lightImpact();
      _buzzed = true;
      _c.value = 0;
      _c.animateTo(1, duration: FlMotion.fast);
      return;
    }
    _buzzed = false;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        if (_still) return Opacity(opacity: _c.value, child: child);
        final t = _land.value;
        final scale = 1.9 + (1 - 1.9) * t; // 1.9 -> 1
        final turn = -10 * (1 - t) * math.pi / 180; // extra -10deg -> 0
        return Opacity(
          opacity: _ink.value.clamp(0, 1),
          child: Transform.rotate(
            angle: turn,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}
