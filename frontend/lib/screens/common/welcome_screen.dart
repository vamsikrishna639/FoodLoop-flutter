// First-run welcome, shown once before the first sign-in.
//
//   Phones (< 900):  the logo and three short slides, with Skip and Next.
//   Wide (>= 900):   a split layout - the chalkboard on the left with one
//                    big real number (portions delivered so far), and the
//                    three steps listed on the right.
//
// The number comes from the public /api/impact endpoint. If the server
// cannot be reached the board shows a line of text instead; nothing is made up.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_service.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/chalkboard.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/impact_number.dart';
import '../../widgets/status_stamp.dart';

/// One step of "how it works".
class _Step {
  const _Step(this.title, this.body, this.art);
  final String title;
  final String body;
  final Widget art;
}

const _steps = [
  _Step(
    "The canteen posts what's left",
    'After each service the surplus goes on the counter as a numbered token, with a time it must be collected by.',
    EmptyStateArt(art: EmptyArt.slip),
  ),
  _Step(
    'You ask for a share',
    'Shelters, hostel messes and student groups request what they can use. The canteen stamps each request.',
    _StampArt(),
  ),
  _Step(
    'A volunteer carries it over',
    'Approved food is picked up and delivered before the deadline. Only food that arrives is counted.',
    EmptyStateArt(art: EmptyArt.clock),
  ),
];

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Remember that the welcome was seen, then go to sign in or register.
  /// The router allows /login and /register from now on.
  static void finish(BuildContext context, String path) {
    context.read<AuthProvider>().markWelcomeSeen();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900; // same split as sign in
    return wide ? const _WideWelcome() : const _SlidesWelcome();
  }
}

// ---------------------------------------------------------------------------
// Phones: three slides
// ---------------------------------------------------------------------------

class _SlidesWelcome extends StatefulWidget {
  const _SlidesWelcome();

  @override
  State<_SlidesWelcome> createState() => _SlidesWelcomeState();
}

class _SlidesWelcomeState extends State<_SlidesWelcome> {
  final _pages = PageController();
  int _page = 0;

  bool get _last => _page == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    // A short slide confirms where the next card came from; instant under
    // reduced motion.
    if (FlMotion.reduced(context)) {
      _pages.jumpToPage(_page + 1);
    } else {
      _pages.nextPage(duration: FlMotion.slow, curve: FlMotion.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final gutter = Breakpoints.gutter(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo on the left, Skip on the right.
            // Fixed height, so the logo does not move when Skip disappears.
            Container(
              height: 48,
              margin: EdgeInsets.fromLTRB(gutter, FlSpace.md, FlSpace.sm, 0),
              child: Row(
                children: [
                  const BrandMark(size: 28),
                  const Spacer(),
                  if (!_last)
                    TextButton(onPressed: () => WelcomeScreen.finish(context, '/login'), child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final s in _steps)
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(gutter, FlSpace.huge, gutter, FlSpace.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 110, child: Align(alignment: Alignment.bottomLeft, child: s.art)),
                          const SizedBox(height: FlSpace.xxl),
                          Semantics(header: true, child: Text(s.title, style: context.text.displaySmall)),
                          const SizedBox(height: FlSpace.md),
                          Text(s.body, style: context.text.bodyLarge?.copyWith(color: fl.inkSoft)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, FlSpace.xl),
              child: _last
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Dots(count: _steps.length, current: _page),
                        const SizedBox(height: FlSpace.xl),
                        FlButton(
                          label: 'Sign in',
                          variant: FlButtonVariant.accent,
                          expand: true,
                          onPressed: () => WelcomeScreen.finish(context, '/login'),
                        ),
                        const SizedBox(height: FlSpace.md),
                        OutlinedButton(
                          onPressed: () => WelcomeScreen.finish(context, '/register'),
                          child: const Text('Create an account'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _Dots(count: _steps.length, current: _page),
                        const Spacer(),
                        FlButton(label: 'Next', onPressed: _next),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page indicator: short ink dashes, the current one longer (shape, not just colour).
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Semantics(
      label: 'Step ${current + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: FlMotion.of(context, FlMotion.base),
                curve: FlMotion.easeOut,
                margin: const EdgeInsets.only(right: 6),
                width: i == current ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: i == current ? fl.ink : fl.perforation,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide screens: split layout
// ---------------------------------------------------------------------------

class _WideWelcome extends StatelessWidget {
  const _WideWelcome();

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: (width * 0.44).clamp(380, 620)),
            child: const _ImpactBoard(),
          ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(FlSpace.huge, FlSpace.huge, FlSpace.xxxl, FlSpace.xxxl),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('How the counter works', style: context.text.displaySmall),
                        ),
                        const SizedBox(height: FlSpace.xxl),
                        for (final s in _steps) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // The drawings are 132 wide; shown smaller here.
                              SizedBox(
                                width: 92,
                                height: 68,
                                child: FittedBox(alignment: Alignment.topLeft, child: s.art),
                              ),
                              const SizedBox(width: FlSpace.xl),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.title, style: context.text.headlineSmall),
                                    const SizedBox(height: FlSpace.xs),
                                    Text(s.body, style: context.text.bodyLarge?.copyWith(color: fl.inkSoft)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: FlSpace.xxl),
                        ],
                        const SizedBox(height: FlSpace.sm),
                        Wrap(
                          spacing: FlSpace.md,
                          runSpacing: FlSpace.md,
                          children: [
                            FlButton(
                              label: 'Sign in',
                              variant: FlButtonVariant.accent,
                              onPressed: () => WelcomeScreen.finish(context, '/login'),
                            ),
                            OutlinedButton(
                              onPressed: () => WelcomeScreen.finish(context, '/register'),
                              child: const Text('Create an account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The left board with the real impact number.
class _ImpactBoard extends StatefulWidget {
  const _ImpactBoard();

  @override
  State<_ImpactBoard> createState() => _ImpactBoardState();
}

class _ImpactBoardState extends State<_ImpactBoard> {
  int? _portions;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    context.read<FoodService>().portionsDelivered().then(
      (v) {
        if (mounted) setState(() => _portions = v);
      },
      onError: (_) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;

    // While loading, the number's space is kept so nothing jumps.
    final Widget figure = _portions != null
        ? ImpactNumber(
            value: _portions!,
            caption: 'portions delivered on campus so far',
            color: fl.chalk,
            captionColor: fl.chalkSoft,
            fontSize: 96,
          )
        : _failed
            ? Text('Surplus food, served before the bell.', style: context.text.displayLarge?.copyWith(color: fl.chalk))
            : const SizedBox(height: 130);

    return Container(
      color: fl.board,
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FlSpace.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(onDark: true, size: 34),
              const SizedBox(height: FlSpace.huge),
              figure,
              const SizedBox(height: FlSpace.xl),
              Text(
                'Counted only when a volunteer marks the food delivered, never when it is posted.',
                style: context.text.bodyLarge?.copyWith(color: fl.chalkSoft),
              ),
              const SizedBox(height: FlSpace.xxxl),
              const ChalkItem(name: 'Canteen', trailing: 'posts surplus'),
              const ChalkItem(name: 'Recipient', trailing: 'requests a share'),
              const ChalkItem(name: 'Volunteer', trailing: 'picks up, delivers'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide 2's drawing: the APPROVED stamp, large.
class _StampArt extends StatelessWidget {
  const _StampArt();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 132,
        height: 96,
        // scaleDown keeps the stamp on one line inside the 132px drawing box.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: StatusStamp(StampKind.approved, scale: 1.9),
        ),
      );
}
