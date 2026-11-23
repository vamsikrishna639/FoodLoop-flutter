// Success and error messages, shown as a small printed slip instead of the
// default Material snackbar.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

/// Shows a slip at the bottom of the screen. Set [error] for failures and
/// [note] for plain information that is neither a success nor a failure
/// ("Still in the queue"). With neither, the slip reads DONE.
void showSlip(BuildContext context, String message, {bool error = false, bool note = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final wide = MediaQuery.sizeOf(context).width >= 600;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        padding: EdgeInsets.zero,
        // On wide screens the slip is a fixed width, not a full-width bar.
        width: wide ? 420 : null,
        margin: wide ? null : const EdgeInsets.all(FlSpace.lg),
        content: _Slip(message: message, error: error, note: note),
      ),
    );
}

class _Slip extends StatelessWidget {
  const _Slip({required this.message, required this.error, required this.note});
  final String message;
  final bool error;
  final bool note;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    // The slip is always "ink" coloured: dark in light mode, light in dark mode.
    final (Color mark, String word) = error
        ? (fl.chilli, 'NOT DONE')
        : note
            ? (fl.paper, 'NOTE')
            : (fl.turmeric, 'DONE');

    return Semantics(
      liveRegion: true, // screen readers announce it without moving focus
      child: Container(
        decoration: BoxDecoration(
          color: fl.ink,
          borderRadius: BorderRadius.circular(FlRadius.sharp),
          boxShadow: [BoxShadow(color: fl.ink.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: FlSpace.lg, vertical: FlSpace.md),
        child: Row(
          children: [
            // A small boxed word, so the result never depends on colour alone.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: mark, width: 1.5),
                borderRadius: BorderRadius.circular(FlRadius.stamp),
              ),
              child: Text(word, style: fl.monoSmall.copyWith(color: mark)),
            ),
            const SizedBox(width: FlSpace.md),
            Expanded(child: Text(message, style: fl.mono.copyWith(color: fl.paper))),
          ],
        ),
      ),
    );
  }
}
