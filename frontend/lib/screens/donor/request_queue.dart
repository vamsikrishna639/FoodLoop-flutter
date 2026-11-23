// The donor's queue of incoming requests, shown on the Board.
//
//   Requests  3 waiting
//   +--------------------------------------------+
//   | Ananya Rao                        APPROVED |  <- the stamp drops here
//   | Asha Night Shelter · 12 min ago            |
//   | 6 PACKETS  Veg Grilled Sandwiches          |
//   | #FL-0004 · 12 LEFT                         |
//   | [ Approve ]  [ Turn down ]                 |
//   +--------------------------------------------+
//   Decided earlier
//   Farhan Sheikh   3 kg · Dal Tadka   REJECTED
//
// A slip decided on this visit stays where it was, with its stamp, so the
// donor sees the result in place. It moves to "Decided earlier" next time.
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../models/claim_request.dart';
import '../../providers/claims_provider.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/stamp_drop.dart';
import '../../widgets/status_stamp.dart';

class RequestQueue extends StatelessWidget {
  const RequestQueue({super.key});

  /// How many decided requests are listed under the queue.
  static const _earlierShown = 4;

  @override
  Widget build(BuildContext context) {
    final claims = context.watch<ClaimsProvider>();
    final fl = context.fl;
    final items = claims.items;

    final Widget body;
    if (items == null && claims.error != null) {
      body = EmptyState.error(message: claims.error!, onRetry: claims.refresh);
    } else if (items == null) {
      body = const SkeletonToken();
    } else {
      final queue = [for (final c in items) if (c.isPending || claims.decidedHere.contains(c.id)) c];
      final earlier = [for (final c in items) if (!c.isPending && !claims.decidedHere.contains(c.id)) c];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (queue.isEmpty)
            Text(
              'Nobody is waiting. New requests line up here as soon as they are sent.',
              style: context.text.bodyLarge?.copyWith(color: fl.inkSoft),
            ),
          for (final c in queue)
            Padding(
              key: ValueKey(c.id),
              padding: const EdgeInsets.only(bottom: FlSpace.md),
              child: RequestSlip(claim: c),
            ),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: FlSpace.lg),
            Text('Decided earlier', style: context.text.titleMedium),
            const SizedBox(height: FlSpace.xs),
            for (final c in earlier.take(_earlierShown)) _EarlierLine(claim: c),
          ],
        ],
      );
    }

    final waiting = items?.where((c) => c.isPending).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The count sits beside the heading, never above it.
        Wrap(
          spacing: FlSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(header: true, child: Text('Requests', style: context.text.headlineMedium)),
            if (waiting != null)
              Text(waiting == 0 ? 'NONE WAITING' : '$waiting WAITING', style: fl.monoSmall),
          ],
        ),
        const SizedBox(height: FlSpace.md),
        body,
      ],
    );
  }
}

/// One request, with Approve and Turn down while it is pending.
class RequestSlip extends StatefulWidget {
  const RequestSlip({super.key, required this.claim});
  final ClaimRequest claim;

  @override
  State<RequestSlip> createState() => _RequestSlipState();
}

enum _Busy { none, approving, rejecting }

class _RequestSlipState extends State<RequestSlip> {
  _Busy _busy = _Busy.none;

  Future<void> _approve() async {
    setState(() => _busy = _Busy.approving);
    final claims = context.read<ClaimsProvider>();
    final listings = context.read<ListingsProvider>();
    try {
      final result = await claims.approve(widget.claim.id);
      // The listing now has fewer portions left; the board and the other
      // slips read it from the listings provider.
      listings.replace(result.claim.listing);
      if (mounted) showSlip(context, result.message);
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
      // Something changed under us (another approval, a cancellation):
      // read both lists again so the slip shows the truth.
      listings.refresh();
      claims.refresh();
    }
    if (mounted) setState(() => _busy = _Busy.none);
  }

  Future<void> _reject() async {
    final c = widget.claim;
    // A turned-down request cannot be reopened, so ask once.
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn this request down?'),
        content: Text(
          '${c.recipientName} asked for ${Fmt.quantity(c.requestedQuantity, c.listing.unit)} of '
          '${c.listing.title}. They will be told it was not approved.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FlButton(label: 'Turn down', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() => _busy = _Busy.rejecting);
    try {
      final result = await context.read<ClaimsProvider>().reject(c.id);
      if (mounted) showSlip(context, result.message);
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
    }
    if (mounted) setState(() => _busy = _Busy.none);
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final c = widget.claim;
    // Prefer the listings provider's copy: it is updated after every
    // approval, while the copy inside the claim is from when it loaded.
    final listing = context.watch<ListingsProvider>().byId(c.listing.id) ?? c.listing;
    final claims = context.read<ClaimsProvider>();

    // Play the stamp drop once, for the slip that was just approved.
    final drop = c.isApproved && claims.justApproved == c.id;
    if (drop) WidgetsBinding.instance.addPostFrameCallback((_) => claims.takeStampDrop(c.id));

    final short = c.isPending && c.requestedQuantity > listing.available;
    final closed = !listing.isOpen;
    final who = [if (c.recipientOrg.isNotEmpty) c.recipientOrg, Fmt.ago(c.createdAt)].join(' · ');

    return Semantics(
      container: true,
      child: Container(
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
                if (!c.isPending) ...[
                  const SizedBox(width: FlSpace.md),
                  Padding(
                    padding: const EdgeInsets.only(top: FlSpace.xs, right: FlSpace.xs),
                    // Only approval drops; a turned-down stamp just appears.
                    child: c.isApproved
                        ? StampDrop(play: drop, child: StatusStamp(c.stamp, scale: 1.25))
                        : FadeIn(child: StatusStamp(c.stamp, scale: 1.25)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: FlSpace.md),
            // What they asked for: the amount in mono, like a token stub.
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: Fmt.quantity(c.requestedQuantity, listing.unit).toUpperCase(),
                  style: fl.monoLarge,
                ),
                TextSpan(text: '   ${listing.title}', style: context.text.titleMedium),
              ]),
            ),
            const SizedBox(height: FlSpace.xxs),
            Text(
              '#${listing.tokenNumber} · ${closed ? 'pickup closed' : '${listing.available} left'}'.toUpperCase(),
              style: fl.monoSmall,
            ),
            if (c.note.isNotEmpty) ...[
              const SizedBox(height: FlSpace.sm),
              Text('"${c.note}"', style: context.text.bodyMedium),
            ],
            const SizedBox(height: FlSpace.md),
            // The buttons fade into the decision line in place. Anchored
            // top-left so the shorter line does not start centred and jump.
            AnimatedSwitcher(
              duration: FlMotion.fade(context, FlMotion.fast),
              switchInCurve: FlMotion.easeOut,
              switchOutCurve: FlMotion.easeOut,
              layoutBuilder: FlMotion.topLeft,
              child: c.isPending
                  ? _Actions(
                      key: const ValueKey('actions'),
                      busy: _busy,
                      // Approve is offered only when it can succeed. The
                      // server checks again, atomically, either way.
                      canApprove: !short && !closed,
                      warning: closed
                          ? 'Pickup has closed, so this can only be turned down.'
                          : short
                              ? 'Only ${Fmt.quantity(listing.available, listing.unit)} left, so this cannot be approved in full.'
                              : null,
                      onApprove: _approve,
                      onReject: _reject,
                    )
                  : Text(
                      key: const ValueKey('decided'),
                      _decidedLine(c, listing.unit),
                      style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _decidedLine(ClaimRequest c, String unit) {
    final at = c.decidedAt == null ? '' : ' at ${Fmt.time(c.decidedAt!)}';
    return switch (c.status) {
      'approved' => '${Fmt.quantity(c.requestedQuantity, unit)} reserved$at. An admin assigns a volunteer next.',
      'rejected' => 'Turned down$at. ${c.recipientName} has been told.',
      _ => 'Cancelled by ${c.recipientName}.',
    };
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    super.key,
    required this.busy,
    required this.canApprove,
    required this.warning,
    required this.onApprove,
    required this.onReject,
  });

  final _Busy busy;
  final bool canApprove;
  final String? warning;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final idle = busy == _Busy.none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warning != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: fl.turmericDeep, semanticLabel: 'Note'),
              const SizedBox(width: FlSpace.sm),
              Expanded(
                child: Text(warning!, style: context.text.bodyMedium?.copyWith(color: fl.turmericDeep)),
              ),
            ],
          ),
          const SizedBox(height: FlSpace.md),
        ],
        Wrap(
          spacing: FlSpace.sm,
          runSpacing: FlSpace.sm,
          children: [
            FlButton(
              label: 'Approve',
              icon: Icons.check,
              loading: busy == _Busy.approving,
              loadingLabel: 'Approving',
              onPressed: canApprove && idle ? onApprove : null,
            ),
            FlButton(
              label: 'Turn down',
              variant: FlButtonVariant.outline,
              loading: busy == _Busy.rejecting,
              loadingLabel: 'Turning down',
              onPressed: idle ? onReject : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// A decided request from before this visit: one compact line.
class _EarlierLine extends StatelessWidget {
  const _EarlierLine({required this.claim});
  final ClaimRequest claim;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final c = claim;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: FlSpace.sm),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: fl.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.recipientName, style: context.text.titleSmall),
                Text(
                  '${Fmt.quantity(c.requestedQuantity, c.listing.unit)} · ${c.listing.title}',
                  style: context.text.bodySmall?.copyWith(color: fl.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: FlSpace.md),
          StatusStamp(c.stamp, scale: 0.85),
        ],
      ),
    );
  }
}
