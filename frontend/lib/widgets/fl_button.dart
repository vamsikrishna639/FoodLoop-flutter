// The app's button. Three looks:
//   ink     - the default action (dark ink on paper)
//   accent  - chilli red, for the ONE most important action on a screen
//   outline - secondary actions
// While [loading] is true it keeps its size, disables itself and shows a
// small printed "..." ticker instead of a spinner.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

enum FlButtonVariant { ink, accent, outline }

class FlButton extends StatelessWidget {
  const FlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FlButtonVariant.ink,
    this.loading = false,
    this.icon,
    this.expand = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final FlButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expand; // fill the available width
  final String? loadingLabel; // e.g. "Signing in"

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final onTap = loading ? null : onPressed;

    final content = loading
        ? _Ticker(label: loadingLabel ?? 'Working')
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: FlSpace.sm)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final Widget button = switch (variant) {
      FlButtonVariant.outline => OutlinedButton(onPressed: onTap, child: content),
      FlButtonVariant.ink => FilledButton(
          onPressed: onTap,
          // Keep the ink colour while loading so the button does not flash grey.
          style: loading
              ? FilledButton.styleFrom(
                  disabledBackgroundColor: fl.ink,
                  disabledForegroundColor: fl.paper,
                  side: BorderSide.none,
                )
              : null,
          child: content,
        ),
      FlButtonVariant.accent => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: fl.chilliDeep,
            foregroundColor: fl.onChilli,
            // While loading it keeps its colour. Otherwise disabled looks the
            // same as every disabled button (the theme's sunken slot).
            disabledBackgroundColor: loading ? fl.chilliDeep : fl.surfaceSunken,
            disabledForegroundColor: loading ? fl.onChilli : fl.inkSoft,
            side: loading ? BorderSide.none : null,
          ),
          child: content,
        ),
    };

    return Semantics(
      label: loading ? '${loadingLabel ?? 'Working'}, please wait' : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// "Signing in." -> "Signing in.." -> "Signing in..." like a receipt printing.
class _Ticker extends StatefulWidget {
  const _Ticker({required this.label});
  final String label;

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> {
  Timer? _timer;
  int _dots = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    // With reduced motion the three dots simply stay still.
    if (!FlMotion.reduced(context)) {
      _timer = Timer.periodic(const Duration(milliseconds: 320), (_) {
        if (mounted) setState(() => _dots = _dots % 3 + 1);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Unused dots are replaced by spaces so the label does not shift.
    return Text('${widget.label}${'.' * _dots}${' ' * (3 - _dots)}');
  }
}
