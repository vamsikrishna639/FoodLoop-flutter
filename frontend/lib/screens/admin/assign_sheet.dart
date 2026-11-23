// "Who collects it?" - the admin picks a volunteer for an approved request.
// A bottom sheet on phones, a dialog on wider screens (PROMPT.md Part A).
//
//   Who collects it?
//   8 boxes of Chicken Biryani for Ananya Rao
//   ( ) Kiran Kumar      NSS Unit 2        1 RUN ON
//   (*) Meera Nair       NSS Unit 2        FREE
//   [ Assign Meera ]  [ Not now ]
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../models/claim_request.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/pressable.dart';

/// Opens the picker. Returns the slip message after a successful assignment,
/// or null when the admin closed it.
Future<String?> showAssignSheet(BuildContext context, ClaimRequest claim) {
  final content = _AssignForm(claim: claim);
  if (context.isMobile) {
    return showModalBottomSheet<String>(
      context: context,
      // The sheet slides up; with reduced motion it simply appears.
      sheetAnimationStyle: FlMotion.reduced(context) ? AnimationStyle.noAnimation : null,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(padding: const EdgeInsets.fromLTRB(FlSpace.lg, 0, FlSpace.lg, FlSpace.lg), child: content),
      ),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(padding: const EdgeInsets.all(FlSpace.xl), child: content),
      ),
    ),
  );
}

class _AssignForm extends StatefulWidget {
  const _AssignForm({required this.claim});
  final ClaimRequest claim;

  @override
  State<_AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<_AssignForm> {
  AppUser? _chosen;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Read again each time, so the "runs on" counts are current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadVolunteers();
    });
  }

  Future<void> _assign() async {
    final v = _chosen;
    if (v == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final message = await context.read<AdminProvider>().assign(widget.claim, v);
      if (mounted) Navigator.pop(context, message);
    } on ApiException catch (e) {
      // Shown inside the form, next to the choice it is about.
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final admin = context.watch<AdminProvider>();
    final c = widget.claim;
    final volunteers = admin.volunteers;

    // Quietest volunteers first, so spreading the work is the easy choice.
    final sorted = [...?volunteers]..sort((a, b) => a.activeRuns.compareTo(b.activeRuns));

    Widget list;
    if (volunteers == null && admin.volunteersError != null) {
      list = Text(admin.volunteersError!, style: context.text.bodyMedium?.copyWith(color: fl.chilliDeep));
    } else if (volunteers == null) {
      list = Padding(
        padding: const EdgeInsets.symmetric(vertical: FlSpace.md),
        child: Text('READING THE LIST...', style: fl.monoSmall),
      );
    } else if (sorted.isEmpty) {
      list = Text(
        'There are no approved volunteers yet. Approve one on the Approvals page first.',
        style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
      );
    } else {
      list = Column(
        children: [
          for (final v in sorted)
            _VolunteerOption(
              volunteer: v,
              selected: _chosen?.id == v.id,
              onTap: _saving ? null : () => setState(() => _chosen = v),
            ),
        ],
      );
    }

    final first = _chosen?.name.split(' ').first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who collects it?', style: context.text.headlineSmall),
        const SizedBox(height: FlSpace.xs),
        Text(
          '${Fmt.quantity(c.requestedQuantity, c.listing.unit)} of ${c.listing.title} for ${c.recipientName}. '
          'Pickup by ${Fmt.dayTime(c.listing.pickupDeadline)}.',
          style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
        ),
        const SizedBox(height: FlSpace.lg),
        Flexible(child: SingleChildScrollView(child: list)),
        if (_error != null) ...[
          const SizedBox(height: FlSpace.sm),
          Text(_error!, style: context.text.bodyMedium?.copyWith(color: fl.chilliDeep)),
        ],
        const SizedBox(height: FlSpace.xl),
        Wrap(
          spacing: FlSpace.sm,
          runSpacing: FlSpace.sm,
          children: [
            FlButton(
              label: first == null ? 'Choose a volunteer' : 'Assign $first',
              variant: FlButtonVariant.accent,
              loading: _saving,
              loadingLabel: 'Assigning',
              onPressed: _chosen == null ? null : _assign,
            ),
            TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Not now')),
          ],
        ),
      ],
    );
  }
}

/// One volunteer to choose, with how busy they are.
class _VolunteerOption extends StatelessWidget {
  const _VolunteerOption({required this.volunteer, required this.selected, required this.onTap});
  final AppUser volunteer;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final v = volunteer;
    final load = v.activeRuns == 0 ? 'FREE' : '${v.activeRuns} ${v.activeRuns == 1 ? 'RUN' : 'RUNS'} ON';

    return Padding(
      padding: const EdgeInsets.only(bottom: FlSpace.sm),
      child: Pressable(
        onTap: onTap,
        selected: selected,
        focusRadius: FlRadius.control,
        semanticLabel: '${v.name}, ${v.organization}, ${load.toLowerCase()}',
        // Not animated: picking a radio option should answer at once, and an
        // animated border width would push the text around while it ran.
        // The selected border is 1px thicker, so the padding is 1px smaller
        // and the content stays exactly where it was.
        builder: (context, hovered) => Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: EdgeInsets.symmetric(
            horizontal: FlSpace.md - (selected ? 1 : 0),
            vertical: FlSpace.sm - (selected ? 1 : 0),
          ),
          decoration: BoxDecoration(
            color: selected ? fl.surfaceSunken : (hovered ? fl.surfaceSunken : fl.surface),
            borderRadius: BorderRadius.circular(FlRadius.control),
            border: Border.all(color: selected ? fl.ink : fl.controlBorder, width: selected ? 2 : 1),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                // A radio mark, so the choice is shown by shape as well as border.
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: fl.ink),
                const SizedBox(width: FlSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name, style: context.text.titleMedium),
                      if (v.organization.isNotEmpty)
                        Text(v.organization, style: context.text.bodySmall?.copyWith(color: fl.inkSoft)),
                    ],
                  ),
                ),
                const SizedBox(width: FlSpace.sm),
                Text(load, style: fl.monoSmall.copyWith(color: v.activeRuns == 0 ? fl.leaf : fl.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
