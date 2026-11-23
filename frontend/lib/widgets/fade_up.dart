// A list item that fades in while rising a few pixels, a little after the
// item above it. Used only the first time a list appears (the caller decides),
// so refreshing or filtering never replays it. Under reduced motion every
// item simply fades in together, without rising.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class FadeUp extends StatefulWidget {
  const FadeUp({super.key, required this.index, required this.animate, required this.child});

  final int index; // position in the list, sets the delay
  final bool animate; // false = show immediately
  final Widget child;

  /// Items further down than this start together, so a long list never
  /// makes the user wait for the bottom of the screen.
  static const int maxStaggered = 6;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: FlMotion.base);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: FlMotion.easeOut);

  bool _started = false; // the entrance is decided once
  bool _still = false; // reduced motion: fade only, no rise

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion is read from MediaQuery, which needs the context, so
    // the entrance starts here rather than in initState.
    if (_started) return;
    _started = true;

    if (!widget.animate) {
      _c.value = 1; // shown as it is
      return;
    }
    _still = FlMotion.reduced(context);
    if (_still) {
      // Everything fades in together, quickly, without moving.
      _c.duration = FlMotion.fast;
      _c.forward();
      return;
    }
    final step = widget.index.clamp(0, FadeUp.maxStaggered);
    Future.delayed(FlMotion.stagger * step, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: _still ? child : Transform.translate(offset: Offset(0, 8 * (1 - _t.value)), child: child),
      ),
    );
  }
}
