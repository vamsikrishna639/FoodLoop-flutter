// Minus / number / plus, capped between [min] and [max].
// The number is printed in mono, like the count on a token stub.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.min = 1,
  });

  final int value;
  final int min;
  final int max; // the portions still available
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;

    Widget button(IconData icon, String tip, int? next) => IconButton(
          tooltip: tip,
          onPressed: next == null ? null : () => onChanged(next),
          icon: Icon(icon),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            disabledForegroundColor: fl.perforation,
          ),
        );

    return Semantics(
      label: 'Quantity: $value $unit, up to $max',
      child: Container(
        decoration: BoxDecoration(
          color: fl.surface,
          border: Border.all(color: fl.controlBorder),
          borderRadius: BorderRadius.circular(FlRadius.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Icons.remove, 'One less', value > min ? value - 1 : null),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$value', style: fl.monoLarge, textAlign: TextAlign.center),
                  Text(unit.toUpperCase(), style: fl.monoSmall),
                ],
              ),
            ),
            button(Icons.add, 'One more', value < max ? value + 1 : null),
          ],
        ),
      ),
    );
  }
}
