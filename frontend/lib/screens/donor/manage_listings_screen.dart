// Listings: every token a donor has printed, split into Open and Closed, with
// Edit and Delete under each. An admin sees the same page for every listing.
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../models/food_listing.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/filter_tag.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/token_card.dart';
import 'listing_form.dart';

class ManageListingsScreen extends StatefulWidget {
  const ManageListingsScreen({super.key, this.admin = false});

  /// true: the admin's view of all listings (no "Post food").
  final bool admin;

  @override
  State<ManageListingsScreen> createState() => _ManageListingsScreenState();
}

class _ManageListingsScreenState extends State<ManageListingsScreen> {
  bool _showClosed = false;
  bool _animated = false; // fade the list in on the first load only

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ListingsProvider>().load(all: widget.admin);
    });
  }

  Future<void> _delete(FoodListing l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete #${l.tokenNumber}?'),
        content: Text(
          '"${l.title}" comes off the counter, and any requests still waiting for it are removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FlButton(
            label: 'Delete',
            variant: FlButtonVariant.accent,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final message = await context.read<ListingsProvider>().delete(l.id);
      if (mounted) showSlip(context, message);
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listings = context.watch<ListingsProvider>();
    final shown = _showClosed ? listings.closed : listings.open;
    final animate = !_animated && listings.items != null && shown.isNotEmpty;
    if (animate) WidgetsBinding.instance.addPostFrameCallback((_) => _animated = true);

    Widget body;
    if (listings.items == null && listings.error == null) {
      body = const Column(children: [SkeletonToken(), SizedBox(height: FlSpace.lg), SkeletonToken()]);
    } else if (listings.items == null) {
      body = EmptyState.error(message: listings.error!, onRetry: listings.refresh);
    } else if (shown.isEmpty) {
      body = _showClosed
          ? const EmptyState(
              art: EmptyArt.clock,
              title: 'Nothing closed yet',
              message: 'Tokens move here once they are collected or their pickup time passes.',
            )
          : EmptyState(
              art: EmptyArt.slip,
              title: 'No tokens on the counter',
              message: widget.admin
                  ? 'No canteen has food on offer right now.'
                  : 'Post what is left after service and it will be listed here.',
              actionLabel: widget.admin ? null : 'Post food',
              onAction: widget.admin ? null : () => showListingForm(context),
            );
    } else {
      body = Column(
        children: [
          for (final (i, l) in shown.indexed)
            Padding(
              key: ValueKey(l.id),
              padding: const EdgeInsets.only(bottom: FlSpace.xl),
              child: FadeUp(index: i, animate: animate, child: _ListingRow(listing: l, onDelete: () => _delete(l))),
            ),
        ],
      );
    }

    return PageFrame(
      title: widget.admin ? 'All listings' : 'Listings',
      lede: widget.admin
          ? 'Every token from every canteen. Remove anything that should not be on the counter.'
          : 'Every token you have printed. Edit open ones; closed ones stay as a record.',
      maxWidth: 600,
      // No "Post food" button in the header: the shell shows one on every
      // screen size, and the empty state offers it when the list is empty.
      children: [
        Wrap(
          spacing: FlSpace.sm,
          children: [
            FilterTag(
              label: 'Open  ${listings.items == null ? '' : listings.open.length}'.trim(),
              selected: !_showClosed,
              onTap: () => setState(() => _showClosed = false),
            ),
            FilterTag(
              label: 'Closed  ${listings.items == null ? '' : listings.closed.length}'.trim(),
              selected: _showClosed,
              onTap: () => setState(() => _showClosed = true),
            ),
          ],
        ),
        const SizedBox(height: FlSpace.xl),
        body,
      ],
    );
  }
}

/// A token with its actions printed underneath.
class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing, required this.onDelete});
  final FoodListing listing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final l = listing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ),
        const SizedBox(height: FlSpace.xs),
        Wrap(
          spacing: FlSpace.xs,
          children: [
            // Closed tokens are a record: they can be removed, not changed.
            if (l.isOpen)
              TextButton.icon(
                onPressed: () => showListingForm(context, existing: l),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Edit'),
              ),
            // Reserved portions belong to approved requests, and the server
            // refuses to delete those, so the button is not offered at all.
            if (l.reservedQuantity == 0)
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: fl.chilliDeep),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete'),
              ),
          ],
        ),
        if (l.reservedQuantity > 0)
          Padding(
            padding: EdgeInsets.only(top: l.isOpen ? 0 : FlSpace.sm, left: FlSpace.xs),
            child: Text(
              '${Fmt.quantity(l.reservedQuantity, l.unit)} promised to approved requests, so it stays on record.',
              style: context.text.bodySmall,
            ),
          ),
      ],
    );
  }
}
