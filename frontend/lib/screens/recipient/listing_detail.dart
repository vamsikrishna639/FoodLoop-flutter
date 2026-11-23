// Listing detail: everything a recipient needs before asking for food.
//
// ListingDetailView is the content. It is used in two places:
//   - ListingDetailScreen, the full page on phones (/home/listing/:id), which
//     the token card "flies" into with a Hero animation;
//   - the side panel next to the list on tablets and desktops.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../models/claim_request.dart';
import '../../models/food_listing.dart';
import '../../providers/claims_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/food_service.dart';
import '../auth/auth_layout.dart' show LabeledField;
import 'my_requests_screen.dart' show confirmCancel;
import '../../widgets/deadline_clock.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/portion_meter.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';
import '../../widgets/token_card.dart';

class ListingDetailView extends StatefulWidget {
  const ListingDetailView({super.key, required this.listing, this.useHero = false, this.inPanel = false});

  final FoodListing listing;
  final bool useHero; // only the full page takes part in the Hero flight

  /// In the side panel the token card is already visible in the list beside
  /// it, so the panel opens with a plain heading instead of a second card.
  final bool inPanel;

  @override
  State<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends State<ListingDetailView> {
  int _quantity = 1;
  final _note = TextEditingController();
  bool _sending = false;
  String? _quantityError; // the server's reason, shown under the stepper

  @override
  void initState() {
    super.initState();
    // The recipient's own requests tell us whether they already asked for
    // this token. Load them once if nothing has loaded them yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final claims = context.read<ClaimsProvider>();
      if (claims.items == null && !claims.loading) claims.load(incoming: false);
    });
  }

  @override
  void didUpdateWidget(ListingDetailView old) {
    super.didUpdateWidget(old);
    // A different token was picked in the side panel: start again.
    if (old.listing.id != widget.listing.id) {
      _quantity = 1;
      _quantityError = null;
      _note.clear();
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _request(FoodListing l, int qty) async {
    setState(() {
      _sending = true;
      _quantityError = null;
    });
    try {
      final result = await context.read<ClaimsProvider>().request(l.id, qty, _note.text.trim());
      _note.clear();
      if (mounted) showSlip(context, result.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      final field = e.fieldErrors['requestedQuantity'];
      if (field != null) {
        setState(() => _quantityError = field);
      } else {
        showSlip(context, e.message, error: true);
      }
      // The listing may have changed (someone else's request was approved).
      _refreshListing(l.id);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _cancel(ClaimRequest claim) async {
    final confirmed = await confirmCancel(context, claim);
    if (!confirmed || !mounted) return;
    try {
      final result = await context.read<ClaimsProvider>().cancel(claim.id);
      if (!mounted) return;
      showSlip(context, result.message);
      // Cancelling an approved request puts portions back on the counter.
      context.read<FeedProvider>().replace(result.claim.listing);
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
    }
  }

  Future<void> _refreshListing(String id) async {
    try {
      final fresh = await context.read<FoodService>().get(id);
      if (mounted) context.read<FeedProvider>().replace(fresh);
    } on ApiException {
      // Keep what is on screen; the feed refreshes on its next load.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final qty = _quantity.clamp(1, l.available < 1 ? 1 : l.available);
    final open = context.watch<ClaimsProvider>().openFor(l.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.inPanel)
          _PanelHeading(listing: l)
        else
          // The same slip as in the list, so the eye keeps its place.
          TokenCard(
            title: l.title,
            donorName: l.donorName,
            tokenNumber: l.tokenNumber,
            quantity: l.quantity,
            reservedQuantity: l.reservedQuantity,
            unit: l.unit,
            deadline: l.pickupDeadline,
            foodType: l.foodType,
            stamp: l.stamp,
            imageUrl: l.imageUrl,
            heroTag: widget.useHero ? l.heroTag : null,
          ),
        if (l.description.isNotEmpty) ...[
          const SizedBox(height: FlSpace.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(l.description, style: context.text.bodyLarge),
          ),
        ],
        const SizedBox(height: FlSpace.xl),

        // The facts, printed like a receipt.
        ReceiptTimeline(
          title: l.location,
          heading: 'Collect from',
          reference: '#${l.tokenNumber}',
          entries: [
            ReceiptEntry('Prepared', Fmt.dayTime(l.preparedAt)),
            ReceiptEntry('Pickup by', Fmt.dayTime(l.pickupDeadline), emphasis: true),
            ReceiptEntry('Posted', Fmt.quantity(l.quantity, l.unit)),
            ReceiptEntry('Left', Fmt.quantity(l.available, l.unit), emphasis: true),
          ],
        ),
        const SizedBox(height: FlSpace.xl),

        Text('Allergens', style: context.text.titleLarge),
        const SizedBox(height: FlSpace.xs),
        Text(
          l.allergenNotes.isEmpty ? 'None declared by the canteen.' : l.allergenNotes,
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: FlSpace.xl),

        // The request area. It follows the state of the listing and of the
        // recipient's own request:
        //   already asked (pending/approved) -> "You asked for ..." (rule 7)
        //   portions left                    -> stepper, note, Request food
        //   nothing left / closed            -> why not, in plain words
        if (open != null)
          _YourRequest(claim: open, onCancel: () => _cancel(open))
        else if (l.canRequest) ...[
          Text('How much do you need?', style: context.text.titleLarge),
          const SizedBox(height: FlSpace.md),
          QuantityStepper(
            value: qty,
            max: l.available,
            unit: l.unit,
            onChanged: (v) => setState(() {
              _quantity = v;
              _quantityError = null;
            }),
          ),
          const SizedBox(height: FlSpace.sm),
          // A server refusal about the amount is shown right here.
          Text(
            _quantityError ?? 'Up to ${Fmt.quantity(l.available, l.unit)} left.',
            style: context.text.bodySmall?.copyWith(
              color: _quantityError == null ? null : context.fl.chilliDeep,
            ),
          ),
          const SizedBox(height: FlSpace.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LabeledField(
              label: 'Note for the canteen',
              optional: true,
              child: TextField(
                controller: _note,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. We can collect by 3 PM',
                  counterText: '',
                ),
              ),
            ),
          ),
          FlButton(
            label: 'Request ${Fmt.quantity(qty, l.unit)}',
            icon: Icons.back_hand_outlined,
            variant: FlButtonVariant.accent,
            loading: _sending,
            loadingLabel: 'Sending',
            onPressed: () => _request(l, qty),
          ),
        ] else
          _ClosedNote(listing: l),
        const SizedBox(height: FlSpace.xl),

        const _SafetyNote(),
        SizedBox(height: context.isMobile ? FlSpace.xl : 0),
      ],
    );
  }
}

/// The top of the side panel: name, canteen, and the countdown.
class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.listing});
  final FoodListing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(l.title, style: context.text.headlineMedium)),
        const SizedBox(height: FlSpace.xs),
        Text('${l.donorName}  ·  #${l.tokenNumber}', style: context.text.bodyMedium?.copyWith(color: context.fl.inkSoft)),
        const SizedBox(height: FlSpace.lg),
        Wrap(
          spacing: FlSpace.xl,
          runSpacing: FlSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (l.isOpen) DeadlineClock(deadline: l.pickupDeadline) else StatusStamp(l.stamp),
            PortionMeter(total: l.quantity, reserved: l.reservedQuantity, unit: l.unit),
          ],
        ),
      ],
    );
  }
}

/// The recipient already has an open request for this token (rule 7 allows
/// only one), so the stepper is replaced by what they asked for.
class _YourRequest extends StatelessWidget {
  const _YourRequest({required this.claim, required this.onCancel});
  final ClaimRequest claim;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final c = claim;
    final body = switch (c.stamp) {
      StampKind.pending => 'Waiting for the canteen to decide. You will see the answer in My requests.',
      StampKind.approved => 'Reserved for you. An admin will assign a volunteer to bring it over.',
      StampKind.assigned => '${c.pickup!.volunteerName} will collect it for you.',
      StampKind.pickedUp => '${c.pickup!.volunteerName} has it and is on the way.',
      _ => 'This request is on your receipts in My requests.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                'You asked for ${Fmt.quantity(c.requestedQuantity, c.listing.unit)}',
                style: context.text.titleLarge,
              ),
            ),
            const SizedBox(width: FlSpace.lg),
            StatusStamp(c.stamp),
          ],
        ),
        const SizedBox(height: FlSpace.xs),
        Text(body, style: context.text.bodyLarge?.copyWith(color: fl.inkSoft)),
        const SizedBox(height: FlSpace.md),
        Wrap(
          spacing: FlSpace.sm,
          runSpacing: FlSpace.sm,
          children: [
            FlButton(
              label: 'See my requests',
              variant: FlButtonVariant.outline,
              onPressed: () => context.go('/requests'),
            ),
            if (c.canCancel)
              TextButton.icon(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: fl.chilliDeep),
                icon: const Icon(Icons.close, size: 20),
                label: const Text('Cancel request'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Why a token cannot be requested, in plain words.
class _ClosedNote extends StatelessWidget {
  const _ClosedNote({required this.listing});
  final FoodListing listing;

  @override
  Widget build(BuildContext context) {
    final (String title, String body) = listing.isExpired
        ? ('Pickup has closed', 'The deadline passed at ${Fmt.time(listing.pickupDeadline)}, so this token is off the counter.')
        : listing.status == 'completed'
            ? ('All handed out', 'This token has been collected and delivered.')
            : ('Every portion is spoken for', 'Approved requests have reserved all of it. If one is cancelled, it comes back here.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleLarge),
        const SizedBox(height: FlSpace.xs),
        Text(body, style: context.text.bodyLarge?.copyWith(color: context.fl.inkSoft)),
      ],
    );
  }
}

/// The food-safety reminder. A deadline alone does not make food safe.
class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(FlSpace.lg),
        decoration: BoxDecoration(
          color: fl.surfaceSunken,
          borderRadius: BorderRadius.circular(FlRadius.control),
          border: Border.all(color: fl.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined, color: fl.ink, size: 22, semanticLabel: 'Food safety'),
            const SizedBox(width: FlSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check before you serve', style: context.text.titleMedium),
                  const SizedBox(height: FlSpace.xs),
                  Text(
                    'Look at and smell the food when you collect it, and read the allergens '
                    'above. A pickup deadline is not a promise that food is safe to eat. '
                    'If anything seems off, do not serve it.',
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full page on phones: /home/listing/:id
// ---------------------------------------------------------------------------

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  FoodListing? _listing;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Show the copy already in the feed straight away (so the Hero has
    // something to land on), then fetch a fresh one in the background.
    final cached = context.read<FeedProvider>().items?.where((l) => l.id == widget.id);
    if (cached != null && cached.isNotEmpty) _listing = cached.first;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final fresh = await context.read<FoodService>().get(widget.id);
      if (!mounted) return;
      setState(() => _listing = fresh);
      context.read<FeedProvider>().replace(fresh);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(context);
    final listing = _listing;

    Widget body;
    if (listing != null) {
      body = ListingDetailView(listing: listing, useHero: true);
    } else if (_error != null) {
      body = EmptyState.error(message: _error!, onRetry: _load);
    } else {
      body = const SkeletonToken();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, FlSpace.sm, gutter, FlSpace.xxxl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A plain back control, left-aligned with the content.
              TextButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Counter'),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: FlSpace.sm)),
              ),
              const SizedBox(height: FlSpace.sm),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
