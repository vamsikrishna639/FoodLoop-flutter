// A filter option, styled like a small paper tag. When it is on, it turns
// ink and shows a tick, so "selected" never depends on colour alone.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import 'pressable.dart';

class FilterTag extends StatelessWidget {
  const FilterTag({super.key, required this.label, required this.selected, required this.onTap, this.leading});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading; // e.g. a VegMarker

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final fg = selected ? fl.paper : fl.ink;

    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$label filter',
      focusRadius: FlRadius.pill,
      // 48px tall touch area; the visible tag is slightly smaller inside it.
      // widthFactor: 1 keeps the tag as wide as its text (a plain Container
      // with an alignment would stretch to the full row).
      builder: (context, hovered) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: FlMotion.fade(context, FlMotion.fast), // colours only
            curve: FlMotion.easeOut,
            // A minimum, not a fixed height, so large text sizes still fit.
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: FlSpace.md),
            decoration: BoxDecoration(
              color: selected ? fl.ink : (hovered ? fl.surfaceSunken : fl.surface),
              borderRadius: BorderRadius.circular(FlRadius.pill),
              border: Border.all(color: selected ? fl.ink : fl.controlBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 16, color: fg),
                  const SizedBox(width: FlSpace.xs),
                ] else if (leading != null) ...[
                  leading!,
                  const SizedBox(width: FlSpace.sm),
                ],
                Text(label, style: context.text.labelLarge?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
