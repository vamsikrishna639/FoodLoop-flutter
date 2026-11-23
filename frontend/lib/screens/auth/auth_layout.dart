// Shared layout for the login and register screens.
//   Tablets and wider (>= 720): a chalkboard panel on the left, the form on
//   paper at right.
//   Phones: a short chalkboard band on top (logo, the strapline under a
//   chalk underline), the form underneath.
import 'package:material_ui/material_ui.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/chalkboard.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.form, this.formMaxWidth = 440});

  final Widget form;
  final double formMaxWidth;

  /// From this width the entry screens (welcome, sign in, register) use the
  /// split layout. A portrait tablet (768) is wide enough for both halves.
  static const double splitWidth = 720;

  /// Width of the board panel in the split layout: a little under half the
  /// screen, capped so the form never ends up far away on wide monitors.
  static double boardWidth(double screen) => (screen * 0.44).clamp(320, 620);

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= splitWidth;
    final gutter = Breakpoints.gutter(context);

    final formArea = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, split ? FlSpace.huge : FlSpace.xl, gutter, FlSpace.xxxl),
      // Left-aligned at every width, in line with the logo above it.
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: formMaxWidth), child: form),
      ),
    );

    if (split) {
      return Scaffold(
        body: Row(
          // Stretch, so the form starts at the top instead of being centred.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: boardWidth(width), child: const _BoardPanel()),
            Expanded(child: SafeArea(child: formArea)),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: fl.board,
            child: SafeArea(
              bottom: false,
              // A small menu board: the logo, a chalk underline and the
              // strapline, so phones get the same canteen board as desktops.
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, FlSpace.lg, gutter, FlSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(onDark: true, size: 28),
                    const SizedBox(height: FlSpace.md),
                    const ChalkUnderline(width: 120),
                    const SizedBox(height: FlSpace.sm),
                    Text(
                      'SURPLUS FOOD, SERVED BEFORE THE BELL',
                      style: fl.monoSmall.copyWith(color: fl.chalkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: formArea),
        ],
      ),
    );
  }
}

/// The left-hand menu board: what FoodLoop does, written like a canteen menu.
class _BoardPanel extends StatelessWidget {
  const _BoardPanel();

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    // On a portrait tablet the panel is ~340 wide, so the headline steps
    // down a size and the padding tightens.
    final narrow = MediaQuery.sizeOf(context).width < 1100;
    return Container(
      color: fl.board,
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(narrow ? FlSpace.xxl : FlSpace.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(onDark: true, size: 34),
              SizedBox(height: narrow ? FlSpace.xxxl : FlSpace.huge),
              Text(
                'Surplus food, served before the bell.',
                style: (narrow ? context.text.displaySmall : context.text.displayLarge)
                    ?.copyWith(color: fl.chalk),
              ),
              const SizedBox(height: FlSpace.xl),
              Text(
                'The canteen posts what is left after service. '
                'Someone who needs it asks for a share. A volunteer carries it over.',
                style: context.text.bodyLarge?.copyWith(color: fl.chalkSoft),
              ),
              const SizedBox(height: FlSpace.xxxl),
              const ChalkItem(name: 'Canteen', trailing: 'posts surplus'),
              const ChalkItem(name: 'Recipient', trailing: 'requests a share'),
              const ChalkItem(name: 'Volunteer', trailing: 'picks up, delivers'),
              const ChalkItem(name: 'Admin', trailing: 'keeps it fair'),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text field with its label above it (never placeholder-only).
///
/// [helper] is a short hint printed under the label, flush with it. (A
/// Material helperText sits under the field, indented by the field's inner
/// padding, so it never lined up with the label.)
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.optional = false, this.helper});

  final String label;
  final Widget child;
  final bool optional;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The visible label is skipped by screen readers; the same words
          // are attached to the field itself below, so the field is
          // announced as "Email" rather than only by its hint text.
          ExcludeSemantics(
            child: Row(
              children: [
                Text(label, style: context.text.titleSmall),
                if (optional) ...[
                  const SizedBox(width: FlSpace.sm),
                  Text('optional', style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          if (helper != null)
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: FlSpace.xxs),
                child: Text(helper!, style: context.text.bodySmall),
              ),
            ),
          const SizedBox(height: FlSpace.sm),
          Semantics(
            label: [label, if (optional) 'optional', ?helper].join(', '),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// "New to FoodLoop? Create an account": a sentence with a link at its end.
/// The link uses the sentence's own type size, so the two share a baseline,
/// and it starts right after the words instead of a button's padding away.
class InlineLink extends StatelessWidget {
  const InlineLink({super.key, required this.lead, required this.link, required this.onPressed});
  final String lead;
  final String link;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final linkStyle = context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: FlSpace.xs,
      children: [
        Text(lead, style: context.text.bodyMedium),
        TextButton(
          onPressed: onPressed,
          style: const ButtonStyle().copyWith(
            textStyle: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? linkStyle?.copyWith(decoration: TextDecoration.underline)
                  : linkStyle,
            ),
          ),
          child: Text(link),
        ),
      ],
    );
  }
}

/// An inline message box for a failed submit ("Incorrect email or password").
class FormNotice extends StatelessWidget {
  const FormNotice({super.key, required this.message, this.error = true});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final color = error ? fl.chilliDeep : fl.inkSoft;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: FlSpace.lg),
        padding: const EdgeInsets.all(FlSpace.md),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(FlRadius.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(error ? Icons.error_outline : Icons.info_outline, color: color, size: 20),
            const SizedBox(width: FlSpace.sm),
            Expanded(
              child: Text(message,
                  style: context.text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
