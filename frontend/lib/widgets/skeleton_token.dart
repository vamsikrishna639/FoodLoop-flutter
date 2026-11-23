// A loading placeholder in the exact shape of a TokenCard, so the page does
// not jump when real data arrives. Used instead of spinners.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';
import 'paper_shapes.dart';
import 'token_card.dart';

class SkeletonToken extends StatefulWidget {
  const SkeletonToken({super.key});

  @override
  State<SkeletonToken> createState() => _SkeletonTokenState();
}

class _SkeletonTokenState extends State<SkeletonToken> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A looping animation is allowed here because it signals loading,
    // but it is switched off entirely for reduced motion.
    if (FlMotion.reduced(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final stubHeight = TokenCard.stubHeightOf(context);

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: fl.line, borderRadius: BorderRadius.circular(FlRadius.stamp)),
        );

    return Semantics(
      label: 'Loading food listing',
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: TokenSlipPainter(stubHeight: stubHeight, lineColor: fl.line, shadowColor: fl.line),
          child: ClipPath(
            clipper: TokenSlipClipper(stubHeight),
            child: ColoredBox(
              color: fl.surface,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(FlSpace.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(68, 68),
                          const SizedBox(width: FlSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bar(64, 12),
                                const SizedBox(height: FlSpace.md),
                                FractionallySizedBox(widthFactor: 0.8, child: bar(double.infinity, 22)),
                                const SizedBox(height: FlSpace.sm),
                                FractionallySizedBox(widthFactor: 0.5, child: bar(double.infinity, 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: stubHeight,
                      child: ColoredBox(
                        color: fl.surfaceSunken,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: FlRadius.notch + 4),
                              child: DottedLine(color: fl.perforation, dot: 3, gap: 5, height: 3),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: FlSpace.lg),
                                child: Row(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [bar(92, 18), const SizedBox(height: FlSpace.sm), bar(140, 12)],
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: fl.line, width: 4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
