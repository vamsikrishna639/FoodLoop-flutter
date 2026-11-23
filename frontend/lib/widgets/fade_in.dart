// A plain short fade (200ms, ease-out) for things that appear in place, such
// as a stamp that is not the approval moment. It only changes opacity, so it
// stays (120ms) under reduced motion.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: FlMotion.fade(context, FlMotion.base),
      curve: FlMotion.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: child,
    );
  }
}
