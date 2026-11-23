// The food listing card, shaped like a canteen token slip.
//
//   +------------------------------------------+
//   | [CB]  (veg) VEG              AVAILABLE   |   <- top: what the food is
//   |       Chicken Biryani                    |
//   |       Main Block Canteen                 |
//   o- - - - - - - - - - - - - - - - - - - - - o   <- notches + perforation
//   | #FL-0003                      (ring)     |   <- stub: number, portions,
//   | [][][][][]  12 / 20 LEFT      3h 59m     |      deadline
//   +------------------------------------------+
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import 'deadline_clock.dart';
import 'paper_shapes.dart';
import 'portion_meter.dart';
import 'pressable.dart';
import 'status_stamp.dart';
import 'veg_marker.dart';

class TokenCard extends StatelessWidget {
  const TokenCard({
    super.key,
    required this.title,
    required this.donorName,
    required this.tokenNumber,
    required this.quantity,
    required this.reservedQuantity,
    required this.unit,
    required this.deadline,
    required this.foodType,
    required this.stamp,
    this.imageUrl,
    this.onTap,
    this.heroTag,
    this.selected = false,
  });

  final String title;
  final String donorName;
  final String tokenNumber; // e.g. FL-0042
  final int quantity;
  final int reservedQuantity;
  final String unit;
  final DateTime deadline;
  final FoodType foodType;
  final StampKind stamp;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Object? heroTag;

  /// True for the token whose details are open in the side panel. It gets an
  /// ink outline and stays lifted, so the link between list and panel is clear.
  final bool selected;

  /// Height of the tear-off stub. It grows with the user's text size so the
  /// notches always sit exactly on the perforation line.
  static double stubHeightOf(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(84)).clamp(84, 132).toDouble();

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final stubHeight = stubHeightOf(context);
    final muted = stamp == StampKind.expired || stamp == StampKind.completed;

    Widget slip(bool hovered) => CustomPaint(
          // Outline and hover shadow are painted, because the clip below
          // would cut off an ordinary border.
          painter: TokenSlipPainter(
            stubHeight: stubHeight,
            lineColor: selected ? fl.ink : (hovered ? fl.controlBorder : fl.line),
            shadowColor: fl.ink.withValues(alpha: 0.10),
            lifted: hovered || selected,
          ),
          child: ClipPath(
            clipper: TokenSlipClipper(stubHeight),
            child: ColoredBox(
              color: fl.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _top(context, muted),
                  SizedBox(height: stubHeight, child: _stub(context)),
                ],
              ),
            ),
          ),
        );

    Widget card = onTap == null
        ? slip(false)
        : Pressable(
            onTap: onTap,
            selected: selected,
            semanticLabel: '$title from $donorName, token $tokenNumber',
            builder: (context, hovered) => slip(hovered),
          );

    // With reduced motion there is no Hero: the card does not fly, the page
    // simply appears (both ends are TokenCards, so neither has a Hero).
    if (heroTag != null && !FlMotion.reduced(context)) {
      // Material keeps text styles intact while the card flies between screens.
      // The card moves between two places on screen, so it uses the app's
      // movement curve (ease-in-out) instead of Material's default.
      card = Hero(
        tag: heroTag!,
        curve: FlMotion.easeInOut,
        child: Material(type: MaterialType.transparency, child: card),
      );
    }
    return card;
  }

  Widget _top(BuildContext context, bool muted) {
    final fl = context.fl;
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(FlSpace.lg, FlSpace.lg, FlSpace.lg, FlSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TicketBlock(title: title, foodType: foodType, imageUrl: imageUrl),
          const SizedBox(width: FlSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marker on the left, stamp in the right corner. The Wrap is
                // given the full width so spaceBetween can push them apart;
                // on very narrow cards the stamp wraps below instead of
                // overflowing.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: FlSpace.sm,
                    runSpacing: FlSpace.sm,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: VegMarker(type: foodType, showLabel: true),
                      ),
                      StatusStamp(stamp, scale: 0.92),
                    ],
                  ),
                ),
                const SizedBox(height: FlSpace.sm),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(color: muted ? fl.inkSoft : fl.ink),
                ),
                const SizedBox(height: FlSpace.xxs),
                Text(
                  donorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: fl.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stub(BuildContext context) {
    final fl = context.fl;
    return ColoredBox(
      color: fl.surfaceSunken,
      child: Column(
        children: [
          // The perforation sits on the top edge of the stub, level with the notches.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FlRadius.notch + 4),
            child: DottedLine(color: fl.perforation, dot: 3, gap: 5, height: 3),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FlSpace.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#$tokenNumber', style: fl.monoLarge, maxLines: 1),
                        const SizedBox(height: FlSpace.xs),
                        PortionMeter(total: quantity, reserved: reservedQuantity, unit: unit),
                      ],
                    ),
                  ),
                  const SizedBox(width: FlSpace.md),
                  // Finished and expired listings have no countdown to show;
                  // the stamp above already says so.
                  if (stamp != StampKind.completed && stamp != StampKind.expired)
                    DeadlineClock(deadline: deadline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The square block on the left of a token. Most listings have no photo, so
/// the default is a printed "ticket" with the dish's initials on a tint of
/// its food-type colour. A photo, when present, simply replaces it.
class _TicketBlock extends StatelessWidget {
  const _TicketBlock({required this.title, required this.foodType, this.imageUrl});

  final String title;
  final FoodType foodType;
  final String? imageUrl;

  static const double size = 68;

  /// "Chicken Biryani" -> "CB", "Samosa" -> "SA".
  String get _initials {
    final words = title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'FL';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(1, 2)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final tone = switch (foodType) {
      FoodType.veg => fl.leaf,
      FoodType.nonVeg => fl.chilliDeep,
      FoodType.mixed => fl.turmericDeep,
    };

    final printed = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FlRadius.stamp),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Stack(
        children: [
          // A printed rule and caption, like the header of a real slip.
          Positioned(
            left: 7,
            right: 7,
            top: 7,
            child: Row(
              children: [
                Text('TOKEN', style: fl.monoSmall.copyWith(fontSize: 8, color: tone)),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 1, color: tone.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.45),
            child: Text(
              _initials,
              style: context.text.headlineMedium?.copyWith(color: tone, height: 1),
            ),
          ),
        ],
      ),
    );

    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return printed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(FlRadius.stamp),
      child: Image.network(
        url,
        width: size,
        height: size,
        // Decode at the size shown, not the photo's full size.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        fit: BoxFit.cover,
        semanticLabel: 'Photo of $title',
        // A broken link falls back to the printed block.
        errorBuilder: (_, _, _) => printed,
        loadingBuilder: (_, child, progress) => progress == null ? child : printed,
      ),
    );
  }
}
