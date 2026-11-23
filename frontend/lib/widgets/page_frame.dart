// The standard page layout inside the shell: a large left-aligned title,
// an optional line of supporting text, optional actions, then the content.
import 'package:material_ui/material_ui.dart';

import '../core/responsive/breakpoints.dart';
import '../core/theme/tokens.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.lede,
    this.actions = const [],
    required this.children,
    this.maxWidth = 880,
  });

  final String title;
  final String? lede; // one supporting sentence under the title
  final List<Widget> actions;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(context);
    final mobile = context.isMobile;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, mobile ? FlSpace.xl : FlSpace.xxxl, gutter, FlSpace.xxxl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and actions share a row; actions wrap below on small screens.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: FlSpace.lg,
                runSpacing: FlSpace.md,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title,
                        style: mobile ? context.text.displaySmall : context.text.displayMedium),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: FlSpace.sm, runSpacing: FlSpace.sm, children: actions),
                ],
              ),
              if (lede != null) ...[
                const SizedBox(height: FlSpace.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(lede!, style: context.text.bodyLarge?.copyWith(color: context.fl.inkSoft)),
                ),
              ],
              SizedBox(height: mobile ? FlSpace.xl : FlSpace.xxl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
