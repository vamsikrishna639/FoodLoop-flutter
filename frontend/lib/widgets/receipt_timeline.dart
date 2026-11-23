// A claim or pickup history printed like a till receipt: torn zigzag edges,
// mono text and dotted leaders between each label and its time.
//
//     Chicken Biryani
//     REQUEST RECEIPT  #FL-0003
//     ---------------------------------
//     Requested ............. 12:40 PM
//     Approved .............. 12:52 PM
//     Picked up ................ --:--
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import 'paper_shapes.dart';

/// One printed line. [value] is null for a step that has not happened yet.
class ReceiptEntry {
  const ReceiptEntry(this.label, this.value, {this.emphasis = false});
  final String label;
  final String? value;
  final bool emphasis; // bold line, e.g. the current step
}

class ReceiptTimeline extends StatelessWidget {
  const ReceiptTimeline({
    super.key,
    required this.title,
    required this.heading,
    required this.entries,
    this.reference,
    this.stamp,
    this.footer,
  });

  final String title; // e.g. the dish and quantity
  final String heading; // e.g. REQUEST RECEIPT
  final String? reference; // e.g. #FL-0003
  final List<ReceiptEntry> entries;
  final Widget? stamp; // a StatusStamp printed over the corner
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;

    return CustomPaint(
      foregroundPainter: ReceiptOutlinePainter(fl.line),
      child: ClipPath(
        clipper: const ReceiptClipper(),
        child: ColoredBox(
          color: fl.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(FlSpace.lg, FlSpace.xl, FlSpace.lg, FlSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The title leads; the receipt type and number print under it.
                // The stamp sits beside it in the corner, so a long title
                // wraps instead of running underneath the stamp.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.titleLarge),
                          const SizedBox(height: FlSpace.xs),
                          Text(
                            [heading.toUpperCase(), ?reference].join('  '),
                            style: fl.monoSmall,
                          ),
                        ],
                      ),
                    ),
                    if (stamp != null) ...[
                      const SizedBox(width: FlSpace.md),
                      Padding(padding: const EdgeInsets.only(top: 6), child: stamp!),
                    ],
                  ],
                ),
                const SizedBox(height: FlSpace.md),
                DottedLine(color: fl.controlBorder, dot: 4, gap: 3, height: 1),
                const SizedBox(height: FlSpace.md),
                for (final e in entries) _ReceiptRow(entry: e),
                if (footer != null) ...[
                  const SizedBox(height: FlSpace.sm),
                  DottedLine(color: fl.controlBorder, dot: 4, gap: 3, height: 1),
                  const SizedBox(height: FlSpace.md),
                  Text(footer!.toUpperCase(), textAlign: TextAlign.center, style: fl.monoSmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.entry});
  final ReceiptEntry entry;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final done = entry.value != null;
    final style = fl.mono.copyWith(
      color: done ? fl.ink : fl.inkSoft,
      fontWeight: entry.emphasis ? FontWeight.w700 : FontWeight.w500,
    );

    return Semantics(
      label: '${entry.label}: ${entry.value ?? 'not yet'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          // LayoutBuilder gives the row's width, so the label and the value
          // can each be capped. The dotted leader then fills what is left and
          // the value always ends at the right edge, like a printed receipt.
          child: LayoutBuilder(
            builder: (context, box) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.36),
                  child: Text(entry.label, style: style),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 5),
                    child: DottedLine(color: fl.perforation, dot: 2, gap: 4),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                  child: Text(entry.value ?? '--:--', style: style, textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
