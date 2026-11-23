// My requests: every request the recipient has made, each printed as a
// receipt that fills in as it moves along.
//
//     Chicken Biryani                       APPROVED
//     REQUEST RECEIPT  #FL-0003
//     ----------------------------------------
//     Asked for ........................ 8 boxes
//     Requested ............... Today, 12:40 PM
//     Approved ................ Today, 12:52 PM
//     Pickup by ................ Today, 4:30 PM
//     Volunteer ............................ --:--
//     Picked up ............................ --:--
//     Delivered ............................ --:--
//
// Phones show one column. Wider screens lay the receipts out in two
// staggered columns, like slips pinned to a board.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../models/claim_request.dart';
import '../../providers/claims_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/filter_tag.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';

/// Asks before cancelling. Shared with the listing detail page.
Future<bool> confirmCancel(BuildContext context, ClaimRequest c) async {
  final what = '${Fmt.quantity(c.requestedQuantity, c.listing.unit)} of ${c.listing.title}';
  final sure = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel this request?'),
      content: Text(
        c.isApproved
            ? 'The $what reserved for you goes back on the counter for someone else.'
            : 'Your request for $what is withdrawn. You can ask again while the token is open.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
        FlButton(label: 'Cancel request', variant: FlButtonVariant.accent, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return sure == true;
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  bool _showPast = false;
  bool _animated = false; // fade the receipts in on the first load only

  @override
  void initState() {
    super.initState();
    // Always read again: the canteen may have decided since the last visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClaimsProvider>().load(incoming: false);
      context.read<DashboardProvider>().load();
    });
  }

  Future<void> _cancel(ClaimRequest c) async {
    if (!await confirmCancel(context, c) || !mounted) return;
    try {
      final result = await context.read<ClaimsProvider>().cancel(c.id);
      if (!mounted) return;
      showSlip(context, result.message);
      context.read<FeedProvider>().replace(result.claim.listing);
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claims = context.watch<ClaimsProvider>();
    final all = claims.items;
    final active = [for (final c in all ?? const <ClaimRequest>[]) if (c.isActive) c];
    final past = [for (final c in all ?? const <ClaimRequest>[]) if (!c.isActive) c];
    final shown = _showPast ? past : active;
    final received = context.watch<DashboardProvider>().stats?['portionsReceived'];

    final animate = !_animated && all != null && shown.isNotEmpty;
    if (animate) WidgetsBinding.instance.addPostFrameCallback((_) => _animated = true);

    Widget body;
    if (all == null && claims.error != null) {
      body = EmptyState.error(message: claims.error!, onRetry: claims.refresh);
    } else if (all == null) {
      body = const Column(children: [SkeletonToken(), SizedBox(height: FlSpace.lg), SkeletonToken()]);
    } else if (shown.isEmpty) {
      body = _showPast
          ? const EmptyState(
              art: EmptyArt.slip,
              title: 'No old receipts',
              message: 'Delivered, turned-down and cancelled requests are kept here as a record.',
            )
          : EmptyState(
              art: EmptyArt.plate,
              title: 'Nothing on order',
              message: 'Open a token on the counter, pick how much you need and send a request. '
                  'Its receipt prints here.',
              actionLabel: 'Go to the counter',
              onAction: () => context.go('/home'),
            );
    } else {
      final receipts = [
        for (final (i, c) in shown.indexed)
          FadeUp(
            key: ValueKey(c.id),
            index: i,
            animate: animate,
            child: _RequestReceipt(claim: c, onCancel: () => _cancel(c)),
          ),
      ];
      body = LayoutBuilder(builder: (context, box) {
        // Each column needs ~300px so a receipt's times stay on one line.
        if (box.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final r in receipts) Padding(padding: const EdgeInsets.only(bottom: FlSpace.xl), child: r)],
          );
        }
        // Two columns, filled alternately; the right one starts lower so
        // the receipts look pinned up by hand rather than set in a grid.
        Widget column(int start, {double top = 0}) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: top),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < receipts.length; i += 2)
                      Padding(padding: const EdgeInsets.only(bottom: FlSpace.xl), child: receipts[i]),
                  ],
                ),
              ),
            );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [column(0), const SizedBox(width: FlSpace.xl), column(1, top: FlSpace.xxl)],
        );
      });
    }

    return PageFrame(
      title: 'My requests',
      lede: 'Each request prints a receipt that fills in as the canteen decides and a volunteer brings it over.',
      maxWidth: 920,
      children: [
        Wrap(
          spacing: FlSpace.sm,
          children: [
            FilterTag(
              label: 'Active  ${all == null ? '' : active.length}'.trim(),
              selected: !_showPast,
              onTap: () => setState(() => _showPast = false),
            ),
            FilterTag(
              label: 'Past  ${all == null ? '' : past.length}'.trim(),
              selected: _showPast,
              onTap: () => setState(() => _showPast = true),
            ),
          ],
        ),
        // Only delivered food counts (rule 4), so the figure is honest.
        if (received != null && received > 0) ...[
          const SizedBox(height: FlSpace.xs),
          Text('$received PORTIONS RECEIVED SO FAR', style: context.fl.monoSmall),
        ],
        const SizedBox(height: FlSpace.xl),
        body,
      ],
    );
  }
}

/// One request as a receipt, with what happens next and Cancel underneath.
class _RequestReceipt extends StatelessWidget {
  const _RequestReceipt({required this.claim, required this.onCancel});
  final ClaimRequest claim;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final c = claim;
    final l = c.listing;
    final p = c.pickup;
    String? at(DateTime? t) => t == null ? null : Fmt.dayTime(t);

    // The receipt prints only the steps this request can still reach.
    final entries = <ReceiptEntry>[
      ReceiptEntry('Asked for', Fmt.quantity(c.requestedQuantity, l.unit), emphasis: true),
      ReceiptEntry('Requested', Fmt.dayTime(c.createdAt)),
      if (c.status == 'rejected')
        ReceiptEntry('Turned down', at(c.decidedAt), emphasis: true)
      else if (c.status == 'cancelled') ...[
        if (c.decidedAt != null) ReceiptEntry('Approved', at(c.decidedAt)),
        ReceiptEntry('Cancelled', at(c.cancelledAt), emphasis: true),
      ] else ...[
        ReceiptEntry('Approved', at(c.decidedAt)),
        ReceiptEntry('Pickup by', Fmt.dayTime(l.pickupDeadline)),
        ReceiptEntry('Volunteer', p?.volunteerName.isNotEmpty == true ? p!.volunteerName : null),
        ReceiptEntry('Picked up', at(p?.pickedUpAt)),
        ReceiptEntry('Delivered', at(p?.deliveredAt), emphasis: c.isDelivered),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReceiptTimeline(
          title: l.title,
          heading: 'Request receipt',
          reference: '#${l.tokenNumber}',
          stamp: StatusStamp(c.stamp),
          entries: entries,
          footer: l.donorName,
        ),
        const SizedBox(height: FlSpace.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FlSpace.xs),
          child: Text(_nextStep(c), style: context.text.bodyMedium?.copyWith(color: fl.inkSoft)),
        ),
        if (c.canCancel)
          TextButton.icon(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: fl.chilliDeep),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Cancel request'),
          ),
      ],
    );
  }

  /// One plain sentence: where this request stands and what comes next.
  String _nextStep(ClaimRequest c) {
    final where = c.listing.location;
    return switch (c.stamp) {
      StampKind.pending => 'Waiting for ${c.listing.donorName} to decide.',
      StampKind.approved => 'Reserved for you at $where. An admin will assign a volunteer.',
      StampKind.assigned => '${c.pickup!.volunteerName} will collect it from $where.',
      StampKind.pickedUp => '${c.pickup!.volunteerName} has it and is on the way.',
      StampKind.delivered => 'Delivered. Check the food before you serve it.',
      StampKind.rejected => 'The canteen could not give this one. Other tokens may still be open.',
      _ => 'You cancelled this request.',
    };
  }
}
