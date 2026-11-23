// "Today's Counter": what the canteen has on offer, soonest deadline first.
//
//   Phone:            search, tags, one column of tokens. Tapping a token
//                     opens the detail page (the token flies there as a Hero).
//   Tablet / desktop: the list on the left and the chosen token's details in
//                     a side panel on the right, so nothing is hidden.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../models/food_listing.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/filter_tag.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/token_card.dart';
import '../../widgets/veg_marker.dart';
import 'listing_detail.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchFocus = FocusNode();
  late final TextEditingController _search;
  late final FeedProvider _feed;
  String? _selectedId; // side-panel selection on wide screens

  @override
  void initState() {
    super.initState();
    _feed = context.read<FeedProvider>();
    _search = TextEditingController(text: _feed.search);
    _feed.addListener(_takeFocusRequest);
    // After the first frame (a provider must not notify during a build):
    // fetch the tokens - the first time this shows skeletons, later visits
    // keep the old list on screen while it refreshes - and take any focus
    // request from the Browse button, which may have been pressed before
    // this screen existed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _feed.load();
      _takeFocusRequest();
    });
  }

  /// Puts the cursor in the search field when the Browse button asked for it.
  void _takeFocusRequest() {
    if (mounted && _feed.takeSearchFocusRequest()) _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _feed.removeListener(_takeFocusRequest);
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  void _open(FoodListing l) {
    if (context.isMobile) {
      context.go('/home/listing/${l.id}');
    } else {
      setState(() => _selectedId = l.id);
    }
  }

  void _clearAll() {
    _search.clear();
    _feed.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();
    final items = feed.items;

    // The list fades up the first time real tokens appear, never again.
    final animate = !feed.hasAnimatedIn && items != null && items.isNotEmpty;
    if (animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => feed.hasAnimatedIn = true);
    }

    final header = _Header(searchController: _search, searchFocus: _searchFocus, feed: feed);

    if (context.isMobile) return _mobile(feed, header, animate);
    return _wide(feed, header, animate);
  }

  // ---- Phone ---------------------------------------------------------------

  Widget _mobile(FeedProvider feed, Widget header, bool animate) {
    final gutter = Breakpoints.gutter(context);
    final items = feed.items;

    return RefreshIndicator(
      onRefresh: feed.load,
      color: context.fl.ink,
      child: ListView(
        padding: EdgeInsets.fromLTRB(gutter, FlSpace.xl, gutter, FlSpace.xxxl),
        children: [
          header,
          const SizedBox(height: FlSpace.lg),
          if (items == null || items.isEmpty)
            _status(feed)
          else
            for (final (i, l) in items.indexed)
              Padding(
                key: ValueKey(l.id),
                padding: const EdgeInsets.only(bottom: FlSpace.lg),
                child: FadeUp(index: i, animate: animate, child: _card(l, useHero: true)),
              ),
        ],
      ),
    );
  }

  // ---- Tablet and desktop --------------------------------------------------

  Widget _wide(FeedProvider feed, Widget header, bool animate) {
    final gutter = Breakpoints.gutter(context);
    final items = feed.items ?? const <FoodListing>[];

    // Keep a valid selection: the first token unless the user picked one
    // that is still in the (filtered) list.
    // (final, so Dart knows it cannot change inside the builders below.)
    final FoodListing? selected =
        items.isEmpty ? null : items.firstWhere((l) => l.id == _selectedId, orElse: () => items.first);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, FlSpace.xxxl, gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: FlSpace.xl),
          Expanded(
            child: selected == null
                ? SingleChildScrollView(child: _status(feed))
                : LayoutBuilder(
                    builder: (context, box) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The list keeps a little over half the width (at
                        // least 320 so a token's stub never gets cramped).
                        SizedBox(
                          width: (box.maxWidth * 0.54).clamp(320.0, 400.0),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: FlSpace.xxxl, top: FlSpace.xs),
                            itemCount: items.length,
                            itemBuilder: (context, i) => Padding(
                              key: ValueKey(items[i].id),
                              padding: const EdgeInsets.only(bottom: FlSpace.lg),
                              child: FadeUp(
                                index: i,
                                animate: animate,
                                child: _card(items[i], selected: items[i].id == selected.id),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: FlSpace.xl),
                        // The side panel. A short cross-fade marks the change
                        // of token without moving anything around. It is
                        // 120ms: tokens are switched often, and a longer fade
                        // shows two panels of text on top of each other.
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: FlMotion.fade(context, FlMotion.fast),
                            switchInCurve: FlMotion.easeOut,
                            switchOutCurve: FlMotion.easeOut,
                            layoutBuilder: FlMotion.topLeft,
                            child: SingleChildScrollView(
                              key: ValueKey(selected.id),
                              padding: const EdgeInsets.only(bottom: FlSpace.xxxl, top: FlSpace.xs),
                              child: ListingDetailView(listing: selected, inPanel: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---- Pieces --------------------------------------------------------------

  Widget _card(FoodListing l, {bool useHero = false, bool selected = false}) => TokenCard(
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
    heroTag: useHero ? l.heroTag : null,
    selected: selected,
    onTap: () => _open(l),
  );

  /// Loading, error and empty states (anything that is not a list of tokens).
  Widget _status(FeedProvider feed) {
    if (feed.items == null && feed.error == null) {
      // First load: skeletons shaped exactly like tokens.
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: FlSpace.lg),
              child: SkeletonToken(),
            ),
        ],
      );
    }
    if (feed.error != null && (feed.items == null || feed.items!.isEmpty)) {
      return EmptyState.error(message: feed.error!, onRetry: feed.load);
    }
    if (feed.hasFilters) {
      return EmptyState(
        art: EmptyArt.slip,
        title: 'No tokens match',
        message:
            'Nothing on the counter fits ${_describeFilters(feed)}. '
            'Try another word, or clear the filters to see everything.',
        actionLabel: 'Clear filters',
        onAction: _clearAll,
      );
    }
    return const EmptyState(
      art: EmptyArt.counter,
      title: "The counter's clear",
      message: 'Nothing is on offer right now. Check back after lunch service.',
    );
  }

  String _describeFilters(FeedProvider f) {
    final parts = <String>[
      if (f.search.isNotEmpty) '"${f.search}"',
      if (f.foodType != null) f.foodType!.label.toLowerCase(),
      if (f.closingSoon) 'closing within the hour',
    ];
    return parts.join(' and ');
  }
}

/// Title, search and filter tags.
class _Header extends StatelessWidget {
  const _Header({required this.searchController, required this.searchFocus, required this.feed});

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final FeedProvider feed;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final mobile = context.isMobile;
    final count = feed.items?.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text("Today's Counter", style: mobile ? context.text.displaySmall : context.text.displayMedium),
        ),
        const SizedBox(height: FlSpace.sm),
        Text(
          'Surplus from the campus canteen, soonest pickup first.',
          style: context.text.bodyLarge?.copyWith(color: fl.inkSoft),
        ),
        SizedBox(height: mobile ? FlSpace.lg : FlSpace.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            onChanged: feed.setSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search dishes or pickup places',
              prefixIcon: const Icon(Icons.search, semanticLabel: 'Search'),
              // A clear button appears once something is typed.
              suffixIcon: ListenableBuilder(
                listenable: searchController,
                builder: (context, _) => searchController.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          feed.setSearch('');
                        },
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: FlSpace.sm),
        Wrap(
          spacing: FlSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final type in FoodType.values)
              FilterTag(
                label: type.label,
                leading: VegMarker(type: type, size: 14),
                selected: feed.foodType == type,
                onTap: () => feed.toggleFoodType(type),
              ),
            FilterTag(
              label: 'Closing soon',
              leading: Icon(Icons.timer_outlined, size: 16, color: fl.ink),
              selected: feed.closingSoon,
              onTap: feed.toggleClosingSoon,
            ),
            // The count sits beside the tags, in the slip's mono type.
            if (count != null)
              Padding(
                padding: const EdgeInsets.only(left: FlSpace.sm),
                child: Text(count == 1 ? '1 TOKEN' : '$count TOKENS', style: fl.monoSmall),
              ),
          ],
        ),
      ],
    );
  }
}
