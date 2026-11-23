// Design tokens for the "Canteen Token" concept. See DESIGN.md.
//
// Colours and special text styles live in a ThemeExtension so every widget
// reads them from the theme (context.fl) and they switch with light/dark mode.
// Spacing, radii and motion do not change with the theme, so they are consts.
import 'package:material_ui/material_ui.dart';

/// Spacing scale (4-point rhythm).
abstract final class FlSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 72;
}

/// Corner radii. They differ per object on purpose (see DESIGN.md section 3).
abstract final class FlRadius {
  static const double sharp = 2; // receipts, chalkboard
  static const double stamp = 4; // stamps, veg markers
  static const double control = 6; // buttons, inputs
  static const double slip = 10; // token slips
  static const double sheet = 20; // bottom sheets, dialogs
  static const double pill = 999; // chips
  static const double notch = 9; // token slip side cut-outs
}

/// Durations and curves. Most UI motion is 120-280ms with ease-out.
abstract final class FlMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
  static const Duration stagger = Duration(milliseconds: 40);
  static const Duration count = Duration(milliseconds: 900);
  static const Duration stampDrop = Duration(milliseconds: 420);

  /// Default curve: things arriving on screen.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Things that move from one place to another on screen.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// The approve stamp: lands with a very small overshoot.
  static const Curve stampCurve = Cubic(0.2, 0.9, 0.3, 1.15);

  /// True when the user asked the system to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Returns [d], or zero when reduced motion is on. Use it for anything
  /// that MOVES or SCALES.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// For pure opacity fades. Reduced motion means gentler, not none: a fade
  /// does not move anything, and it still tells the eye that something
  /// changed, so it keeps running (never longer than [fast] when reduced).
  static Duration fade(BuildContext context, Duration d) =>
      reduced(context) && d > fast ? fast : d;

  /// Lays out an AnimatedSwitcher's old and new child from the top-left
  /// (Flutter centres them by default, so a narrower new child would start
  /// in the middle and jump left when the old one is removed).
  static Widget topLeft(Widget? current, List<Widget> previous) =>
      Stack(alignment: Alignment.topLeft, children: [...previous, ?current]);

  /// The same, anchored top-right (stamps sit in the top-right corner).
  static Widget topRight(Widget? current, List<Widget> previous) =>
      Stack(alignment: Alignment.topRight, children: [...previous, ?current]);
}

/// Colours and text styles that Material's ColorScheme / TextTheme cannot hold.
@immutable
class FoodLoopTokens extends ThemeExtension<FoodLoopTokens> {
  const FoodLoopTokens({
    required this.paper,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkSoft,
    required this.line,
    required this.perforation,
    required this.controlBorder,
    required this.chilli,
    required this.chilliDeep,
    required this.onChilli,
    required this.leaf,
    required this.onLeaf,
    required this.turmeric,
    required this.turmericDeep,
    required this.onTurmeric,
    required this.stampGrey,
    required this.board,
    required this.boardFrame,
    required this.chalk,
    required this.chalkSoft,
    required this.chalkLine,
    required this.impact,
    required this.monoLarge,
    required this.mono,
    required this.monoSmall,
    required this.stamp,
  });

  // Paper and ink
  final Color paper; // app background
  final Color surface; // slips, receipts, sheets
  final Color surfaceSunken; // stubs, input fills
  final Color ink; // primary text
  final Color inkSoft; // secondary text
  final Color line; // decorative dividers
  final Color perforation; // dotted lines
  final Color controlBorder; // input outlines (3:1 contrast)

  // Accents
  final Color chilli; // brand red: large display, rings, borders
  final Color chilliDeep; // red that is safe for text and button fills
  final Color onChilli; // label colour on a chilliDeep button
  final Color leaf; // success green
  final Color onLeaf;
  final Color turmeric; // highlight fill
  final Color turmericDeep; // turmeric that is safe for text
  final Color onTurmeric;
  final Color stampGrey; // EXPIRED / CANCELLED stamps

  // Chalkboard block: dark in both themes
  final Color board;
  final Color boardFrame;
  final Color chalk;
  final Color chalkSoft;
  final Color chalkLine;

  // Text styles that have no Material slot
  final TextStyle impact; // huge editorial numbers
  final TextStyle monoLarge; // token number
  final TextStyle mono; // quantities, times, receipt rows
  final TextStyle monoSmall; // uppercase captions
  final TextStyle stamp; // rubber stamp text

  @override
  FoodLoopTokens copyWith() => this;

  // Tokens switch instantly between themes. (Material animates its own
  // colours; our custom ones simply swap halfway through.)
  @override
  FoodLoopTokens lerp(ThemeExtension<FoodLoopTokens>? other, double t) {
    if (other is! FoodLoopTokens) return this;
    return t < 0.5 ? this : other;
  }
}

/// Short-hands: `context.fl.chilli`, `context.text.bodyLarge`.
extension FoodLoopThemeX on BuildContext {
  FoodLoopTokens get fl => Theme.of(this).extension<FoodLoopTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
