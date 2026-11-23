// The admin's home. Asymmetric on purpose (DESIGN.md section 7): one large
// impact block with the 7-day chart, then the admin's real work - approved
// requests that still need a volunteer - with a printed "right now" tally.
//
//   Wide:   [ 112 PORTIONS DELIVERED     | 7-day bar chart          ]
//           [ Needs a volunteer (slips)          ] [ Right now receipt ]
//   Phone:  impact, chart, needs a volunteer, right now - stacked.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../models/claim_request.dart';
import '../../models/dashboard.dart';
import '../../providers/admin_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/deliveries_chart.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/impact_number.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';
import 'assign_sheet.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().load();
      context.read<AdminProvider>().loadQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final stats = dash.stats;

    if (stats == null && dash.error != null) {
      return PageFrame(title: 'Overview', children: [EmptyState.error(message: dash.error!, onRetry: dash.load)]);
    }

    return PageFrame(
      title: 'Overview',
      lede: 'What reached people this week, and the requests that still need someone to carry them.',
      maxWidth: 1040,
      children: [
        _ImpactBlock(stats: stats),
        const SizedBox(height: FlSpace.xxxl),
        LayoutBuilder(builder: (context, box) {
          final queue = const _VolunteerQueue();
          final tally = _RightNow(stats: stats);
          if (box.maxWidth >= 860) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: queue),
                const SizedBox(width: FlSpace.xxl),
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(top: FlSpace.xs), child: tally)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              queue,
              const SizedBox(height: FlSpace.xxl),
              Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: tally),
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// The feature block: the one number that matters, and the week behind it.
class _ImpactBlock extends StatelessWidget {
  const _ImpactBlock({required this.stats});
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final s = stats;
    final week = s?.last7Days.fold<int>(0, (sum, d) => sum + d.portions) ?? 0;
    final deliveries = s?['deliveries'] ?? 0;

    // One printed sentence instead of a row of stat tiles.
    final sentence = Text(
      'Across $deliveries ${deliveries == 1 ? 'delivery' : 'deliveries'}, $week of them this week. '
      'Food counts only once a volunteer has handed it over.',
      style: context.text.bodyLarge?.copyWith(color: fl.inkSoft),
    );
    final big = s == null
        ? SizedBox(height: 120, child: Text('COUNTING...', style: fl.monoSmall))
        : ImpactNumber(value: s['portionsDelivered'], caption: 'Portions delivered', fontSize: 96, color: fl.leaf);

    final chart = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last 7 days', style: context.text.titleLarge),
        Text('PORTIONS DELIVERED PER DAY', style: fl.monoSmall),
        const SizedBox(height: FlSpace.lg),
        if (s == null) const SizedBox(height: 180) else DeliveriesChart(days: s.last7Days, height: 180),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: fl.surface,
        borderRadius: BorderRadius.circular(FlRadius.sharp),
        border: Border.all(color: fl.line),
      ),
      padding: const EdgeInsets.all(FlSpace.xl),
      child: LayoutBuilder(builder: (context, box) {
        // Very wide: number and sentence in a column beside the chart.
        if (box.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [big, const SizedBox(height: FlSpace.lg), sentence],
                ),
              ),
              const SizedBox(width: FlSpace.xxl),
              Expanded(child: chart),
            ],
          );
        }
        // Medium (desktop with the activity rail, tablets): the sentence
        // sits beside the number, so the block stays short and the
        // volunteer queue below is reached sooner.
        final head = box.maxWidth >= 520
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  big,
                  const SizedBox(width: FlSpace.xxl),
                  Expanded(child: Padding(padding: const EdgeInsets.only(bottom: FlSpace.xs), child: sentence)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [big, const SizedBox(height: FlSpace.lg), sentence],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [head, const SizedBox(height: FlSpace.xxl), chart],
        );
      }),
    );
  }
}

/// Approved requests with no volunteer yet, oldest approval first.
class _VolunteerQueue extends StatelessWidget {
  const _VolunteerQueue();

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final admin = context.watch<AdminProvider>();
    final queue = admin.queue;
    final waiting = queue?.where((c) => !admin.assignedHere.containsKey(c.id)).length;

    Widget body;
    if (queue == null && admin.queueError != null) {
      body = EmptyState.error(message: admin.queueError!, onRetry: admin.loadQueue);
    } else if (queue == null) {
      body = const SkeletonToken();
    } else if (queue.isEmpty) {
      body = Text(
        'Every approved request has a volunteer. New ones appear here as soon as the canteen approves them.',
        style: context.text.bodyLarge?.copyWith(color: fl.inkSoft),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in queue)
            Padding(
              key: ValueKey(c.id),
              padding: const EdgeInsets.only(bottom: FlSpace.md),
              child: _AssignSlip(claim: c, assignedTo: admin.assignedHere[c.id]),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The count sits beside the heading, never above it.
        Wrap(
          spacing: FlSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(header: true, child: Text('Needs a volunteer', style: context.text.headlineMedium)),
            if (waiting != null) Text(waiting == 0 ? 'NONE WAITING' : '$waiting WAITING', style: fl.monoSmall),
          ],
        ),
        const SizedBox(height: FlSpace.md),
        body,
      ],
    );
  }
}

/// One approved request, with "Assign volunteer". After assigning it stays
/// here with an ASSIGNED stamp until the next visit.
class _AssignSlip extends StatelessWidget {
  const _AssignSlip({required this.claim, required this.assignedTo});
  final ClaimRequest claim;
  final String? assignedTo;

  Future<void> _assign(BuildContext context) async {
    final dashboard = context.read<DashboardProvider>();
    final message = await showAssignSheet(context, claim);
    if (message == null || !context.mounted) return;
    showSlip(context, message);
    dashboard.load(); // "runs on the way" and "needs a volunteer" changed
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final c = claim;
    final l = c.listing;
    final closed = l.pickupDeadline.isBefore(DateTime.now());
    final who = [if (c.recipientOrg.isNotEmpty) c.recipientOrg, if (c.decidedAt != null) 'approved ${Fmt.ago(c.decidedAt!)}']
        .join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: fl.surface,
        borderRadius: BorderRadius.circular(FlRadius.sharp),
        border: Border.all(color: fl.line),
      ),
      padding: const EdgeInsets.all(FlSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.recipientName, style: context.text.titleLarge),
                    const SizedBox(height: FlSpace.xxs),
                    Text(who, style: context.text.bodySmall?.copyWith(color: fl.inkSoft)),
                  ],
                ),
              ),
              if (assignedTo != null) ...[
                const SizedBox(width: FlSpace.md),
                Padding(
                  padding: const EdgeInsets.only(top: FlSpace.xs, right: FlSpace.xs),
                  child: FadeIn(child: StatusStamp(StampKind.assigned, scale: 1.15)),
                ),
              ],
            ],
          ),
          const SizedBox(height: FlSpace.md),
          Text.rich(TextSpan(children: [
            TextSpan(text: Fmt.quantity(c.requestedQuantity, l.unit).toUpperCase(), style: fl.monoLarge),
            TextSpan(text: '   ${l.title}', style: context.text.titleMedium),
          ])),
          const SizedBox(height: FlSpace.xxs),
          Text('#${l.tokenNumber} · pickup by ${Fmt.time(l.pickupDeadline)} · ${l.donorName}'.toUpperCase(),
              style: fl.monoSmall),
          const SizedBox(height: FlSpace.md),
          if (assignedTo != null)
            Text('$assignedTo will collect it. They have been told.',
                style: context.text.bodyMedium?.copyWith(color: fl.inkSoft))
          else if (closed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: fl.turmericDeep, semanticLabel: 'Note'),
                const SizedBox(width: FlSpace.sm),
                Expanded(
                  child: Text('Pickup time has passed, so no run can be assigned.',
                      style: context.text.bodyMedium?.copyWith(color: fl.turmericDeep)),
                ),
              ],
            )
          else
            FlButton(label: 'Assign volunteer', icon: Icons.pedal_bike_outlined, onPressed: () => _assign(context)),
        ],
      ),
    );
  }
}

/// A printed tally of what is open right now, with a way to the approvals.
class _RightNow extends StatelessWidget {
  const _RightNow({required this.stats});
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    String? n(String key) => s == null ? null : '${s[key]}';
    final pending = s?['pendingAccounts'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptTimeline(
          title: 'Right now',
          heading: 'Printed ${Fmt.time(DateTime.now())}',
          entries: [
            ReceiptEntry('No volunteer', n('awaitingVolunteer'), emphasis: (s?['awaitingVolunteer'] ?? 0) > 0),
            ReceiptEntry('On the way', n('runsOnTheWay')),
            ReceiptEntry('Open tokens', n('openListings')),
            ReceiptEntry('To approve', n('pendingAccounts'), emphasis: pending > 0),
          ],
          footer: 'Whole campus',
        ),
        if (pending > 0)
          TextButton.icon(
            onPressed: () => context.go('/approvals'),
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text(pending == 1 ? 'Review 1 account' : 'Review $pending accounts'),
          ),
      ],
    );
  }
}
