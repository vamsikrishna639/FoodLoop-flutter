// A very large editorial number with a small mono caption, e.g.
//   1,240
//   MEALS SAVED
// It counts up from 0 the first time a figure appears in a session. After
// that it starts from the value it last showed, so coming back to the page
// shows the number standing still, and a figure that grew (112 -> 116)
// counts only the difference, which is the change worth seeing.
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../core/theme/tokens.dart';

class ImpactNumber extends StatelessWidget {
  const ImpactNumber({
    super.key,
    required this.value,
    required this.caption,
    this.fontSize,
    this.color,
    this.captionColor,
    this.suffix,
  });

  final num value;
  final String caption;
  final double? fontSize; // defaults to the theme's impact size (72)
  final Color? color;
  final Color? captionColor;
  final String? suffix; // e.g. "kg"

  // Indian digit grouping: 1,24,000.
  static final NumberFormat _format = NumberFormat.decimalPattern('en_IN');

  /// The value each figure (by caption) last counted to in this session.
  /// Kept in memory only; a page reload counts from 0 again.
  static final Map<String, num> _shown = {};

  /// Called on sign-out, so the next user's figures count up from 0.
  static void forget() => _shown.clear();

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final style = fl.impact.copyWith(fontSize: fontSize, color: color ?? fl.ink);

    return Semantics(
      label: '${_format.format(value)} ${suffix ?? ''} $caption',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // TweenAnimationBuilder runs from `begin` to the value when first
            // built, and only animates again if the value itself changes.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: (_shown[caption] ?? 0).toDouble(), end: value.toDouble()),
              onEnd: () => _shown[caption] = value,
              duration: FlMotion.of(context, FlMotion.count),
              curve: FlMotion.easeOut,
              builder: (context, v, _) => FittedBox(
                // Shrinks instead of overflowing on a very narrow screen.
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: _format.format(v.round()),
                    children: [
                      if (suffix != null)
                        TextSpan(
                          text: ' $suffix',
                          style: style.copyWith(fontSize: (style.fontSize ?? 72) * 0.4, letterSpacing: 0),
                        ),
                    ],
                  ),
                  style: style,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: FlSpace.sm),
            Text(caption.toUpperCase(), style: fl.monoSmall.copyWith(color: captionColor ?? fl.inkSoft)),
          ],
        ),
      ),
    );
  }
}
