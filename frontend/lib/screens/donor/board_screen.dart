// The donor's home: "Today's Surplus" on a chalkboard, like the menu board
// behind a canteen counter, with the request queue and a printed tally.
//
//   Wide:   [ chalkboard (big)          ] [ requests queue ]
//                                         [ tally receipt  ]
//   Phone:  chalkboard, then requests, then tally, stacked.
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../models/food_listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claims_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/chalkboard.dart';
import '../../widgets/deadline_clock.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/paper_shapes.dart';
import '../../widgets/pressable.dart';
import '../../widgets/receipt_timeline.dart';
import 'listing_form.dart';
import 'request_queue.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame, because a provider must not notify during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListingsProvider>().load();
      context.read<ClaimsProvider>().load(incoming: true);
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listings = context.watch<ListingsProvider>();
    final user = context.watch<AuthProvider>().user;
    final title = (user?.organization.isNotEmpty ?? false) ? user!.organization : (user?.name ?? 'Board');

    final Widget content;
    if (listings.items == null && listings.error != null) {
      content = EmptyState.error(message: listings.error!, onRetry: listings.refresh);
    } else {
      content = LayoutBuilder(builder: (context, box) {
        final board = _SurplusBoard(listings: listings);
        final tally = _Tally(listings: listings);
        // Wide: board on the left; the queue (the donor's actual work) at
        // the top of the right column so it needs no scrolling, tally below.
        if (box.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: board),
              const SizedBox(width: FlSpace.xl),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const RequestQueue(), const SizedBox(height: FlSpace.xxl), tally],
                ),
              ),
            ],
          );
        }
        // Tablet and phone: everything stacked, requests straight after the board.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            board,
            const SizedBox(height: FlSpace.xxl),
            const RequestQueue(),
            const SizedBox(height: FlSpace.xxl),
            // A receipt does not need the full width of a tablet.
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: tally),
            ),
          ],
        );
      });
    }

    return PageFrame(
      title: title,
      lede: 'Post what is left after each service. Tap a line on the board to change it.',
      maxWidth: 1000,
      children: [content],
    );
  }
}

/// The chalkboard: one menu line per open token.
class _SurplusBoard extends StatelessWidget {
  const _SurplusBoard({required this.listings});
  final ListingsProvider listings;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    // Like a real board: whatever must go first is at the top.
    final open = [...listings.open]..sort((a, b) => a.pickupDeadline.compareTo(b.pickupDeadline));
    final loading = listings.items == null;

    return Chalkboard(
      title: "Today's Surplus",
      caption: DateFormat('EEEE d MMMM').format(DateTime.now()),
      // No "Post food" button here: the shell already shows one on every
      // screen size (raised in the bottom bar, red in the rail/sidebar).
      child: loading
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: FlSpace.lg),
              child: Text('Reading the board...', style: fl.mono.copyWith(color: fl.chalkSoft)),
            )
          : open.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: FlSpace.md),
                  child: Text(
                    'The board is blank. When service ends, post what is left so it reaches someone before it spoils.',
                    style: context.text.bodyLarge?.copyWith(color: fl.chalkSoft),
                  ),
                )
              : Column(children: [for (final l in open) _BoardLine(listing: l)]),
    );
  }
}

/// One line on the board. Tapping it opens the edit form.
///
///   Chicken Biryani .................. 12 left
///   #FL-0003 · 20 BOXES · UNTIL 2:13 PM
///
/// The small line runs the full width underneath, so it stays on one line
/// even on a phone.
class _BoardLine extends StatelessWidget {
  const _BoardLine({required this.listing});
  final FoodListing listing;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final l = listing;
    final left = l.pickupDeadline.difference(DateTime.now());
    final when = l.isClosingSoon ? 'closes in ${DeadlineClock.format(left)}' : 'until ${Fmt.time(l.pickupDeadline)}';
    // Kept short so it fits one line on a 360px phone.
    final shortWhen = l.isClosingSoon ? '${DeadlineClock.format(left)} left' : Fmt.time(l.pickupDeadline);
    final note = '#${l.tokenNumber} · ${Fmt.quantity(l.quantity, l.unit)} · $shortWhen';
    // "none left" is in turmeric below, so a fully reserved line stands out.
    final leftText = l.available == 0 ? 'none left' : '${l.available} left';

    return Pressable(
      onTap: () => showListingForm(context, existing: l),
      onBoard: true,
      focusRadius: FlRadius.stamp,
      semanticLabel: '${l.title}, ${l.available} of ${l.quantity} ${l.unit} left, $when. Edit',
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: FlSpace.xs, vertical: FlSpace.sm),
        decoration: BoxDecoration(
          color: fl.chalk.withValues(alpha: hovered ? 0.06 : 0),
          borderRadius: BorderRadius.circular(FlRadius.stamp),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The name may use up to 65% of the line; the dotted leader
              // fills whatever is left, so the count always ends at the edge.
              LayoutBuilder(
                builder: (context, box) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth * 0.65),
                      child: Text(l.title, style: context.text.titleLarge?.copyWith(color: fl.chalk)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(FlSpace.sm, 0, FlSpace.sm, 6),
                        child: DottedLine(color: fl.chalkSoft.withValues(alpha: 0.5), dot: 2, gap: 5),
                      ),
                    ),
                    Text(
                      leftText,
                      style: fl.mono.copyWith(
                        color: l.available == 0 ? fl.turmeric : fl.chalk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FlSpace.xxs),
              Text(note.toUpperCase(), style: fl.monoSmall.copyWith(color: fl.chalkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The printed tally of today's counter.
class _Tally extends StatelessWidget {
  const _Tally({required this.listings});
  final ListingsProvider listings;

  @override
  Widget build(BuildContext context) {
    final items = listings.items ?? const <FoodListing>[];
    final open = listings.open;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final postedToday = items.where((l) => !l.createdAt.isBefore(today)).length;
    final portionsLeft = open.fold<int>(0, (sum, l) => sum + l.available);
    final closingSoon = open.where((l) => l.isClosingSoon).length;
    final reserved = open.fold<int>(0, (sum, l) => sum + l.reservedQuantity);
    String? n(int v) => listings.items == null ? null : '$v';
    // Rule 4: only portions a volunteer has handed over count as given.
    final stats = context.watch<DashboardProvider>().stats;

    return ReceiptTimeline(
          title: 'Counter tally',
          heading: 'Printed ${Fmt.time(now)}',
          entries: [
            ReceiptEntry('Open tokens', n(open.length), emphasis: true),
            ReceiptEntry('Portions left', n(portionsLeft)),
            ReceiptEntry('Reserved', n(reserved)),
            ReceiptEntry('Closing < 1h', n(closingSoon)),
            ReceiptEntry('Posted today', n(postedToday)),
            ReceiptEntry('Delivered, ever', stats == null ? null : '${stats['portionsDelivered']}', emphasis: true),
          ],
          footer: 'All units added together',
        );
  }
}
