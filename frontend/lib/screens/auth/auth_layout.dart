// Shared layout for the login and register screens.
//   Wide screens: a chalkboard panel on the left, the form on paper at right.
//   Phones: a short chalkboard band on top, the form underneath.
import 'package:material_ui/material_ui.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/chalkboard.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.form, this.formMaxWidth = 440});

  final Widget form;
  final double formMaxWidth;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= 900; // side-by-side needs room for both halves
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
            // The board takes a little under half the screen, capped so the
            // form never ends up far away from it on very wide monitors.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: (width * 0.44).clamp(380, 620)),
              child: const _BoardPanel(),
            ),
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, FlSpace.lg, gutter, FlSpace.lg),
                child: const BrandMark(onDark: true, size: 28),
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
    return Container(
      color: fl.board,
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FlSpace.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(onDark: true, size: 34),
              const SizedBox(height: FlSpace.huge),
              Text(
                'Surplus food, served before the bell.',
                style: context.text.displayLarge?.copyWith(color: fl.chalk),
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
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.optional = false});

  final String label;
  final Widget child;
  final bool optional;

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
          const SizedBox(height: FlSpace.sm),
          Semantics(label: optional ? '$label, optional' : label, child: child),
        ],
      ),
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
