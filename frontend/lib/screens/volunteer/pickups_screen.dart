// The volunteer's home: their runs, each printed as a pickup slip with one
// large button for the next step.
//
//     Chicken Biryani                         ASSIGNED
//     PICKUP SLIP  #FL-0003
//     ----------------------------------------
//     Carry ............................ 8 boxes
//     From ........ Main Block Canteen, Counter 2
//     To ..................... Ananya Rao, Asha...
//     Phone ......................... 9000000003
//     Pickup by ............... Today, 4:30 PM
//     Assigned ................ Today, 12:58 PM
//     Picked up .......................... --:--
//     Delivered .......................... --:--
//     [            I've collected it            ]
//
// Tabs: Assigned / On the way / Delivered. A run moved on during this visit
// stays in its tab (new stamp, next button) so it never jumps away mid-task.
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../models/dashboard.dart';
import '../../models/pickup.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/pickups_provider.dart';
import '../../widgets/deadline_clock.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/filter_tag.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/impact_number.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/pressable.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';

/// The three tabs, by the pickup status they list.
enum _Tab {
  assigned('Assigned', 'assigned'),
  onTheWay('On the way', 'picked_up'),
  delivered('Delivered', 'delivered');

  const _Tab(this.label, this.status);
  final String label;
  final String status;
}

class PickupsScreen extends StatefulWidget {
  const PickupsScreen({super.key});

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen> {
  _Tab _tab = _Tab.assigned;
  // The opening tab is chosen once, when the runs first arrive (see build).
  bool _tabPicked = false;
  bool _animated = false; // fade the slips in on the first load only

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PickupsProvider>().load();
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pickups = context.watch<PickupsProvider>();
    final stats = context.watch<DashboardProvider>().stats;
    final all = pickups.items;

    // A run handed back during this visit stays visible with its stamp;
    // older handed-back runs are not listed at all.
    List<Pickup> inTab(_Tab t) => [
          for (final p in all ?? const <Pickup>[])
            if (pickups.tabStatusOf(p) == t.status) p,
        ];

    // Open on the tab with work in it: with nothing assigned but a run in
    // the bag, start on "On the way" instead of an empty Assigned tab.
    // Done once, so it never overrides a tab the volunteer picked.
    if (!_tabPicked && all != null) {
      _tabPicked = true;
      if (inTab(_Tab.assigned).isEmpty && inTab(_Tab.onTheWay).isNotEmpty) _tab = _Tab.onTheWay;
    }
    final shown = inTab(_tab);

    final animate = !_animated && all != null && shown.isNotEmpty;
    if (animate) WidgetsBinding.instance.addPostFrameCallback((_) => _animated = true);

    Widget list;
    if (all == null && pickups.error != null) {
      list = EmptyState.error(message: pickups.error!, onRetry: pickups.load);
    } else if (all == null) {
      list = const SkeletonToken();
    } else if (shown.isEmpty) {
      list = switch (_tab) {
        _Tab.assigned => const EmptyState(
            art: EmptyArt.clock,
            title: 'No runs waiting',
            message: 'When the admin gives you a pickup it prints here, with where to collect it and who it is for.',
          ),
        _Tab.onTheWay => const EmptyState(
            art: EmptyArt.plate,
            title: 'Nothing in your bag',
            message: 'Runs you have collected and not yet handed over show here.',
          ),
        _Tab.delivered => const EmptyState(
            art: EmptyArt.slip,
            title: 'No deliveries yet',
            message: 'Every run you complete is kept here as a record.',
          ),
      };
    } else {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, p) in shown.indexed)
            Padding(
              key: ValueKey(p.id),
              padding: const EdgeInsets.only(bottom: FlSpace.xxl),
              child: FadeUp(index: i, animate: animate, child: _RunSlip(run: p)),
            ),
        ],
      );
    }

    void pick(_Tab t) => setState(() {
          _tab = t;
          _tabPicked = true;
        });
    // Phones: three equal cells in one row (three pill tags wrapped onto a
    // second line at 360). Wider: the usual tags.
    final tags = context.isMobile
        ? _TabStrip(
            tabs: [for (final t in _Tab.values) (t.label, all == null ? null : inTab(t).length, _tab == t)],
            onTap: (i) => pick(_Tab.values[i]),
          )
        : Wrap(
            spacing: FlSpace.sm,
            children: [
              for (final t in _Tab.values)
                FilterTag(
                  label: '${t.label}  ${all == null ? '' : inTab(t).length}'.trim(),
                  selected: _tab == t,
                  onTap: () => pick(t),
                ),
            ],
          );

    return PageFrame(
      title: 'Pickups',
      // Short on phones, so the first run's button is still on screen.
      lede: context.isMobile
          ? 'Tap the button at each step.'
          : 'Collect from the canteen counter, hand it over, and tap the button at each step.',
      maxWidth: 960,
      children: [
        LayoutBuilder(builder: (context, box) {
          // Wide: the runs, with the volunteer's own tally beside them.
          // Narrow: the tally shrinks to one printed line under the tabs.
          final wide = box.maxWidth >= 640;
          final runs = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tags,
              // Narrow: the tally is a record, so it prints under Delivered only.
              if (!wide && stats != null && _tab == _Tab.delivered) ...[
                const SizedBox(height: FlSpace.sm),
                Text(
                  '${stats['runsDelivered']} RUNS DELIVERED · ${stats['portionsCarried']} PORTIONS CARRIED',
                  style: context.fl.monoSmall,
                ),
              ],
              const SizedBox(height: FlSpace.xl),
              list,
            ],
          );
          if (!wide) return runs;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: runs)),
              const SizedBox(width: FlSpace.xxl),
              SizedBox(width: 200, child: _Tally(stats: stats)),
            ],
          );
        }),
      ],
    );
  }
}

/// The three tabs on a phone: one row of equal cells, the label over the
/// count. The chosen cell is inked in and carries a tick, so the choice is
/// not shown by colour alone.
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.tabs, required this.onTap});
  final List<(String, int?, bool)> tabs; // label, count, selected
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Row(
      children: [
        for (final (i, (label, count, selected)) in tabs.indexed) ...[
          if (i > 0) const SizedBox(width: FlSpace.xs),
          Expanded(
            child: Pressable(
              onTap: () => onTap(i),
              selected: selected,
              focusRadius: FlRadius.control,
              semanticLabel: '$label${count == null ? '' : ', $count'}',
              builder: (context, hovered) => Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: FlSpace.xs, vertical: FlSpace.xs),
                decoration: BoxDecoration(
                  color: selected ? fl.ink : (hovered ? fl.surfaceSunken : fl.surface),
                  borderRadius: BorderRadius.circular(FlRadius.control),
                  border: Border.all(color: selected ? fl.ink : fl.controlBorder),
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelMedium?.copyWith(color: selected ? fl.paper : fl.ink),
                      ),
                      const SizedBox(height: FlSpace.xxs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            Icon(Icons.check, size: 14, color: fl.paper),
                            const SizedBox(width: FlSpace.xxs),
                          ],
                          Text(
                            count == null ? '-' : '$count',
                            style: fl.mono.copyWith(
                              color: selected ? fl.paper : fl.inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The volunteer's own numbers, beside the runs on wide screens.
class _Tally extends StatelessWidget {
  const _Tally({required this.stats});
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final s = stats;
    if (s == null) return const SizedBox.shrink();
    final runs = s['runsDelivered'];
    // Level with the first slip, under the tags.
    return Padding(
      padding: const EdgeInsets.only(top: FlSpace.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImpactNumber(value: s['portionsCarried'], caption: 'Portions you carried', fontSize: 64),
          const SizedBox(height: FlSpace.md),
          Text(
            runs == 0
                ? 'Your first delivery will count here.'
                : 'Over $runs ${runs == 1 ? 'run' : 'runs'}. Only food that reached someone is counted.',
            style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// One run as a pickup slip, with the next step underneath.
class _RunSlip extends StatefulWidget {
  const _RunSlip({required this.run});
  final Pickup run;

  @override
  State<_RunSlip> createState() => _RunSlipState();
}

class _RunSlipState extends State<_RunSlip> {
  bool _busy = false;

  Future<void> _move(String status) async {
    final pickups = context.read<PickupsProvider>();
    final dashboard = context.read<DashboardProvider>();
    setState(() => _busy = true);
    try {
      final result = await pickups.setStatus(widget.run.id, status);
      if (status == 'delivered') dashboard.load(); // the tally just grew
      if (mounted) showSlip(context, result.message, note: status == 'cancelled');
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
      pickups.load(); // something changed elsewhere: show the truth
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _handBack() async {
    final r = widget.run;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hand this run back?'),
        content: Text(
          'The admin will give ${r.listing.title} for ${r.recipientName} to another volunteer. '
          'The food stays reserved for them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FlButton(label: 'Hand back', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (sure == true && mounted) await _move('cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final r = widget.run;
    final l = r.listing;
    String? at(DateTime? t) => t == null ? null : Fmt.dayTime(t);
    final to = r.recipientOrg.isEmpty ? r.recipientName : '${r.recipientName}, ${r.recipientOrg}';

    final receipt = ReceiptTimeline(
      title: l.title,
      heading: 'Pickup slip',
      reference: '#${l.tokenNumber}',
      // A plain short fade when the stamp changes; the stamp drop is kept
      // for the canteen approving a request.
      stamp: AnimatedSwitcher(
        duration: FlMotion.fade(context, FlMotion.base),
        switchInCurve: FlMotion.easeOut,
        switchOutCurve: FlMotion.easeOut,
        // Stamps differ in width; anchor them to the corner they sit in.
        layoutBuilder: FlMotion.topRight,
        child: r.isCancelled
            ? StatusStamp.custom('HANDED BACK', key: ValueKey(r.status), color: fl.stampGrey)
            : StatusStamp(r.stamp, key: ValueKey(r.status)),
      ),
      entries: [
        ReceiptEntry('Carry', Fmt.quantity(r.requestedQuantity, l.unit), emphasis: true),
        ReceiptEntry('From', l.location),
        ReceiptEntry('To', to),
        if (r.recipientPhone.isNotEmpty) ReceiptEntry('Phone', Fmt.phone(r.recipientPhone)),
        ReceiptEntry('Pickup by', Fmt.dayTime(l.pickupDeadline)),
        ReceiptEntry('Assigned', at(r.assignedAt)),
        ReceiptEntry('Picked up', at(r.pickedUpAt), emphasis: r.isPickedUp),
        ReceiptEntry('Delivered', at(r.deliveredAt), emphasis: r.isDelivered),
      ],
      footer: l.donorName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        receipt,
        if (r.note.isNotEmpty) ...[
          const SizedBox(height: FlSpace.sm),
          Text('Note from ${r.recipientName}: "${r.note}"', style: context.text.bodyMedium),
        ],
        // The number on the slip, one tap from the phone's dialler.
        if (r.recipientPhone.isNotEmpty && (r.isAssigned || r.isPickedUp))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: r.recipientPhone.replaceAll(' ', ''))),
              icon: const Icon(Icons.call_outlined, size: 20),
              label: Text('Call ${r.recipientName.split(' ').first}'),
            ),
          ),
        const SizedBox(height: FlSpace.md),
        AnimatedSwitcher(
          duration: FlMotion.fade(context, FlMotion.fast),
          switchInCurve: FlMotion.easeOut,
          switchOutCurve: FlMotion.easeOut,
          layoutBuilder: FlMotion.topLeft,
          child: KeyedSubtree(key: ValueKey(r.status), child: _nextStep(context)),
        ),
      ],
    );
  }

  /// The one large button for the next step, or a closing line.
  Widget _nextStep(BuildContext context) {
    final fl = context.fl;
    final r = widget.run;
    final done = context.text.bodyMedium?.copyWith(color: fl.inkSoft);

    switch (r.status) {
      case 'assigned':
      case 'picked_up':
        final collecting = r.isAssigned;
        final left = r.listing.pickupDeadline.difference(DateTime.now());
        // Only collection is tied to the canteen's deadline.
        final String? warning = !collecting
            ? null
            : left.isNegative
                ? 'Pickup time has passed. Check with the canteen that the food is still there.'
                : left <= const Duration(hours: 1)
                    ? 'The counter closes this in ${DeadlineClock.format(left)}.'
                    : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (warning != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, size: 18, color: fl.turmericDeep, semanticLabel: 'Time'),
                  const SizedBox(width: FlSpace.sm),
                  Expanded(child: Text(warning, style: context.text.bodyMedium?.copyWith(color: fl.turmericDeep))),
                ],
              ),
              const SizedBox(height: FlSpace.md),
            ],
            SizedBox(
              height: 56,
              child: FlButton(
                label: collecting ? "I've collected it" : 'Mark delivered',
                icon: collecting ? Icons.inventory_2_outlined : Icons.check,
                variant: collecting ? FlButtonVariant.ink : FlButtonVariant.accent,
                loading: _busy,
                loadingLabel: collecting ? 'Saving' : 'Delivering',
                expand: true,
                onPressed: () => _move(collecting ? 'picked_up' : 'delivered'),
              ),
            ),
            if (collecting)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _busy ? null : _handBack, child: const Text("Can't do this run")),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: FlSpace.sm),
                child: Text('Hand it to ${r.recipientName}, then tap the button.', style: done),
              ),
          ],
        );
      case 'delivered':
        return Text(
          'Delivered ${r.deliveredAt == null ? '' : 'at ${Fmt.time(r.deliveredAt!)}'}. Thank you for the run.',
          style: done,
        );
      default:
        return Text('Handed back. The admin will find someone else.', style: done);
    }
  }
}
