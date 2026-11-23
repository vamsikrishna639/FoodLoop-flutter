// Component gallery: every signature widget on one page, with sample data.
// Open it at /gallery (no login needed) to review the design system.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/chalkboard.dart';
import '../../widgets/deadline_clock.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/impact_number.dart';
import '../../widgets/portion_meter.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';
import '../../widgets/token_card.dart';
import '../../widgets/veg_marker.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Sample deadlines are fixed when the page opens so the clocks count down.
  final DateTime _opened = DateTime.now();
  bool _buttonLoading = false;

  DateTime _in(Duration d) => _opened.add(d);

  void _fakeLoad() {
    setState(() => _buttonLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _buttonLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final theme = context.watch<ThemeProvider>();
    final gutter = Breakpoints.gutter(context);
    final mobile = context.isMobile;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, FlSpace.xl, gutter, FlSpace.huge),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Top bar -------------------------------------------
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: FlSpace.lg,
                    runSpacing: FlSpace.md,
                    children: [
                      const BrandMark(size: 28),
                      Wrap(
                        spacing: FlSpace.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FlButton(
                            label: theme.isChalkboard ? 'Switch to paper' : 'Switch to chalkboard',
                            icon: theme.isChalkboard ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            variant: FlButtonVariant.outline,
                            onPressed: () => theme.setChalkboard(!theme.isChalkboard),
                          ),
                          TextButton(
                            onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                            child: Text(context.canPop() ? 'Back' : 'Go to sign in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: mobile ? FlSpace.xxl : FlSpace.huge),
                  Semantics(
                    header: true,
                    child: Text('Canteen Token',
                        style: mobile ? context.text.displaySmall : context.text.displayLarge),
                  ),
                  const SizedBox(height: FlSpace.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      'Every piece of the FoodLoop interface, in one place. '
                      'Listings are token slips, statuses are stamps, histories are receipts.',
                      style: context.text.bodyLarge?.copyWith(color: fl.inkSoft),
                    ),
                  ),

                  // ---- Token cards -----------------------------------------
                  _Section(
                    title: 'Token cards',
                    note: 'The food listing. None of these has a photo: the printed block is the default.',
                    child: _Columns(
                      children: [
                        TokenCard(
                          title: 'Chicken Biryani',
                          donorName: 'Main Block Canteen',
                          tokenNumber: 'FL-0003',
                          quantity: 20,
                          reservedQuantity: 8,
                          unit: 'boxes',
                          deadline: _in(const Duration(hours: 3, minutes: 59)),
                          foodType: FoodType.nonVeg,
                          stamp: StampKind.available,
                          onTap: () => showSlip(context, 'Token FL-0003 tapped.', note: true),
                        ),
                        TokenCard(
                          title: 'Veg Grilled Sandwiches',
                          donorName: 'Main Block Canteen',
                          tokenNumber: 'FL-0004',
                          quantity: 12,
                          reservedQuantity: 5,
                          unit: 'packets',
                          deadline: _in(const Duration(minutes: 45)),
                          foodType: FoodType.veg,
                          stamp: StampKind.available,
                          onTap: () => showSlip(context, 'Token FL-0004 tapped.', note: true),
                        ),
                        TokenCard(
                          title: 'Samosa and Chutney',
                          donorName: 'Main Block Canteen',
                          tokenNumber: 'FL-0005',
                          quantity: 10,
                          reservedQuantity: 2,
                          unit: 'plates',
                          deadline: _in(const Duration(minutes: 12)),
                          foodType: FoodType.veg,
                          stamp: StampKind.available,
                          onTap: () => showSlip(context, 'Token FL-0005 tapped.', note: true),
                        ),
                        TokenCard(
                          title: 'Mixed Lunch Thali with Rice, Dal, Sabzi, Egg Curry and Roti',
                          donorName: 'Engineering Block Night Canteen and Juice Centre',
                          tokenNumber: 'FL-0006',
                          quantity: 10,
                          reservedQuantity: 10,
                          unit: 'plates',
                          deadline: _in(const Duration(hours: 2)),
                          foodType: FoodType.mixed,
                          stamp: StampKind.reserved,
                          onTap: () => showSlip(context, 'Token FL-0006 tapped.', note: true),
                        ),
                        TokenCard(
                          title: 'Curd Rice',
                          donorName: 'Main Block Canteen',
                          tokenNumber: 'FL-0007',
                          quantity: 15,
                          reservedQuantity: 0,
                          unit: 'boxes',
                          deadline: _opened.subtract(const Duration(hours: 2)),
                          foodType: FoodType.veg,
                          stamp: StampKind.expired,
                        ),
                        const SkeletonToken(),
                      ],
                    ),
                  ),

                  // ---- Stamps ----------------------------------------------
                  _Section(
                    title: 'Status stamps',
                    note: 'A status is always a word, so it never depends on colour alone.',
                    child: Wrap(
                      spacing: FlSpace.xl,
                      runSpacing: FlSpace.xl,
                      children: [for (final kind in StampKind.values) StatusStamp(kind)],
                    ),
                  ),

                  // ---- Meters, clocks, markers -------------------------------
                  _Section(
                    title: 'Portions, deadlines and food marks',
                    child: Wrap(
                      spacing: FlSpace.xxxl,
                      runSpacing: FlSpace.xl,
                      children: [
                        const PortionMeter(total: 10, reserved: 3, unit: 'plates'),
                        const PortionMeter(total: 8, reserved: 8, unit: 'boxes'),
                        const PortionMeter(total: 40, reserved: 22, unit: 'plates'),
                        const PortionMeter(total: 8, reserved: 2, unit: 'kg'),
                        DeadlineClock(deadline: _in(const Duration(hours: 4, minutes: 30))),
                        DeadlineClock(deadline: _in(const Duration(minutes: 45))),
                        DeadlineClock(deadline: _in(const Duration(minutes: 9))),
                        DeadlineClock(deadline: _opened.subtract(const Duration(minutes: 5))),
                        const VegMarker(type: FoodType.veg, showLabel: true),
                        const VegMarker(type: FoodType.nonVeg, showLabel: true),
                        const VegMarker(type: FoodType.mixed, showLabel: true),
                      ],
                    ),
                  ),

                  // ---- Chalkboard + impact ----------------------------------
                  _Section(
                    title: 'Chalkboard and impact number',
                    note: 'The board stays dark in both themes.',
                    child: _Columns(
                      children: [
                        Chalkboard(
                          title: "Today's Surplus",
                          caption: '3 items on the board',
                          child: Column(
                            children: [
                              const ChalkItem(name: 'Chicken Biryani', trailing: '12 boxes', note: 'CLOSES 4:30 PM'),
                              const ChalkItem(name: 'Veg Sandwiches', trailing: '7 packets', note: 'CLOSES 1:15 PM'),
                              const ChalkItem(name: 'Dal and Jeera Rice', trailing: '8 kg', note: 'CLOSES 6:00 PM'),
                              const SizedBox(height: FlSpace.md),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: PortionMeter(total: 12, reserved: 5, unit: 'boxes', onDark: true),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ImpactNumber(
                              value: 1240,
                              caption: 'Sample figure: meals delivered',
                              color: fl.leaf,
                              fontSize: mobile ? 72 : 96,
                            ),
                            const SizedBox(height: FlSpace.xl),
                            const ImpactNumber(value: 86, suffix: 'kg', caption: 'Sample figure: kept out of the bin', fontSize: 44),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ---- Receipt -----------------------------------------------
                  _Section(
                    title: 'Receipt timeline',
                    child: _Columns(
                      children: [
                        const ReceiptTimeline(
                          title: 'Chicken Biryani, 8 boxes',
                          heading: 'Request receipt',
                          reference: '#FL-0003',
                          stamp: StatusStamp(StampKind.approved),
                          entries: [
                            ReceiptEntry('Requested', '12:40 PM'),
                            ReceiptEntry('Approved', '12:52 PM'),
                            ReceiptEntry('Volunteer', 'Kiran Kumar'),
                            ReceiptEntry('Picked up', null, emphasis: true),
                            ReceiptEntry('Delivered', null),
                          ],
                          footer: 'Check freshness before serving',
                        ),
                        const ReceiptTimeline(
                          title: 'Idli Sambar, 40 plates',
                          heading: 'Pickup receipt',
                          reference: '#FL-0002',
                          stamp: StatusStamp(StampKind.delivered),
                          entries: [
                            ReceiptEntry('Assigned', '8:05 AM'),
                            ReceiptEntry('Picked up', '8:40 AM'),
                            ReceiptEntry('Delivered', '9:10 AM', emphasis: true),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ---- Buttons and feedback -----------------------------------
                  _Section(
                    title: 'Buttons and slips',
                    note: 'Chilli is kept for the single most important action on a screen.',
                    child: Wrap(
                      spacing: FlSpace.md,
                      runSpacing: FlSpace.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FlButton(label: 'Request food', variant: FlButtonVariant.accent, onPressed: () {}),
                        FlButton(label: 'Approve', icon: Icons.check, onPressed: () {}),
                        FlButton(label: 'Reject', variant: FlButtonVariant.outline, onPressed: () {}),
                        const FlButton(label: 'Disabled', onPressed: null),
                        FlButton(
                          label: 'Show loading',
                          loadingLabel: 'Saving',
                          loading: _buttonLoading,
                          onPressed: _fakeLoad,
                        ),
                        FlButton(
                          label: 'Success slip',
                          variant: FlButtonVariant.outline,
                          onPressed: () => showSlip(context, 'Request sent to Main Block Canteen.'),
                        ),
                        FlButton(
                          label: 'Note slip',
                          variant: FlButtonVariant.outline,
                          onPressed: () => showSlip(context, 'Still in the queue.', note: true),
                        ),
                        FlButton(
                          label: 'Error slip',
                          variant: FlButtonVariant.outline,
                          onPressed: () =>
                              showSlip(context, 'Only 4 boxes are left. Ask for fewer.', error: true),
                        ),
                      ],
                    ),
                  ),

                  // ---- Empty states -------------------------------------------
                  _Section(
                    title: 'Empty and error states',
                    child: _Columns(
                      children: [
                        const EmptyState(
                          art: EmptyArt.counter,
                          title: "The counter's clear",
                          message: 'Nothing is on offer right now. Check back after lunch service.',
                        ),
                        const EmptyState(
                          art: EmptyArt.plate,
                          title: 'No requests yet',
                          message: 'When you ask for food, your receipt will be kept here.',
                        ),
                        EmptyState.error(
                          message: 'Could not reach the FoodLoop server. Check that it is running.',
                          onRetry: () => showSlip(context, 'Tried again.', note: true),
                        ),
                      ],
                    ),
                  ),

                  // ---- Colour and type -----------------------------------------
                  _Section(
                    title: 'Palette',
                    child: Wrap(
                      spacing: FlSpace.md,
                      runSpacing: FlSpace.md,
                      children: [
                        _Swatch('paper', fl.paper),
                        _Swatch('surface', fl.surface),
                        _Swatch('sunken', fl.surfaceSunken),
                        _Swatch('ink', fl.ink),
                        _Swatch('ink soft', fl.inkSoft),
                        _Swatch('chilli', fl.chilli),
                        _Swatch('chilli deep', fl.chilliDeep),
                        _Swatch('leaf', fl.leaf),
                        _Swatch('turmeric', fl.turmeric),
                        _Swatch('board', fl.board),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Type',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bricolage Grotesque', style: context.text.displayMedium),
                        const SizedBox(height: FlSpace.sm),
                        Text('Instrument Sans carries body copy and every control label.',
                            style: context.text.bodyLarge),
                        const SizedBox(height: FlSpace.sm),
                        Text('#FL-0042  18 / 20  12:40 PM', style: fl.monoLarge),
                        Text('JETBRAINS MONO FOR NUMBERS, TIMES AND RECEIPTS', style: fl.monoSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled block of the gallery.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});
  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // More space above a heading than below it.
      padding: const EdgeInsets.only(top: FlSpace.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: context.text.headlineMedium)),
          if (note != null) ...[
            const SizedBox(height: FlSpace.xs),
            Text(note!, style: context.text.bodyMedium?.copyWith(color: context.fl.inkSoft)),
          ],
          const SizedBox(height: FlSpace.xl),
          child,
        ],
      ),
    );
  }
}

/// Lays children out in one column on phones and two on wider screens.
class _Columns extends StatelessWidget {
  const _Columns({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 720 ? 2 : 1;
        const gap = FlSpace.xl;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(FlRadius.stamp),
              border: Border.all(color: fl.line),
            ),
          ),
          const SizedBox(height: FlSpace.xs),
          Text(name.toUpperCase(), style: fl.monoSmall),
        ],
      ),
    );
  }
}
