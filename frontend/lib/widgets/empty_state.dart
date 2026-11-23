// Shown when a list has nothing in it, or when loading failed.
// The illustrations are drawn with plain Flutter shapes - no image files.
import 'package:material_ui/material_ui.dart';

import '../core/theme/tokens.dart';

enum EmptyArt { plate, counter, slip, clock }

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.art,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// A failed load, with a retry button.
  const EmptyState.error({super.key, required this.message, required VoidCallback onRetry})
      : art = EmptyArt.slip,
        title = 'That did not go through',
        actionLabel = 'Try again',
        onAction = onRetry;

  final EmptyArt art;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      // Left-aligned on purpose: the app avoids centred-everything layouts.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyStateArt(art: art),
          const SizedBox(height: FlSpace.xl),
          Text(title, style: context.text.headlineMedium),
          const SizedBox(height: FlSpace.sm),
          Text(message, style: context.text.bodyLarge?.copyWith(color: fl.inkSoft)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: FlSpace.xl),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Just the drawing, for screens that lay out their own text around it.
class EmptyStateArt extends StatelessWidget {
  const EmptyStateArt({super.key, required this.art});
  final EmptyArt art;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(132, 96),
        painter: _ArtPainter(art: art, ink: fl.ink, soft: fl.perforation, accent: fl.turmeric, fill: fl.surface),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter({
    required this.art,
    required this.ink,
    required this.soft,
    required this.accent,
    required this.fill,
  });

  final EmptyArt art;
  final Color ink, soft, accent, fill;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = soft;
    final paper = Paint()..color = fill;
    final w = size.width, h = size.height;

    switch (art) {
      case EmptyArt.plate:
        // An empty plate seen from above, with a spoon beside it.
        final c = Offset(w * 0.42, h * 0.52);
        canvas.drawCircle(c, 40, paper);
        canvas.drawCircle(c, 40, line);
        canvas.drawCircle(c, 26, faint);
        canvas.drawLine(Offset(w * 0.88, h * 0.3), Offset(w * 0.88, h * 0.92), line);
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.88, h * 0.2), width: 14, height: 22), line);
        canvas.drawCircle(Offset(w * 0.2, h * 0.12), 4, Paint()..color = accent);

      case EmptyArt.counter:
        // A clear counter top with a service bell.
        canvas.drawLine(Offset(0, h * 0.78), Offset(w, h * 0.78), line);
        canvas.drawLine(Offset(w * 0.08, h * 0.78), Offset(w * 0.08, h), faint);
        canvas.drawLine(Offset(w * 0.92, h * 0.78), Offset(w * 0.92, h), faint);
        final bell = Path()
          ..moveTo(w * 0.34, h * 0.7)
          ..arcToPoint(Offset(w * 0.66, h * 0.7), radius: const Radius.circular(22))
          ..close();
        canvas.drawPath(bell, paper);
        canvas.drawPath(bell, line);
        canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.38), line);
        canvas.drawCircle(Offset(w * 0.5, h * 0.24), 4, Paint()..color = accent);

      case EmptyArt.slip:
        // A blank token slip with a perforation.
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.1, w * 0.62, h * 0.8), const Radius.circular(8));
        canvas.drawRRect(r, paper);
        canvas.drawRRect(r, line);
        for (double x = w * 0.2; x < w * 0.72; x += 9) {
          canvas.drawCircle(Offset(x, h * 0.62), 1.6, Paint()..color = ink);
        }
        canvas.drawLine(Offset(w * 0.24, h * 0.28), Offset(w * 0.6, h * 0.28), faint);
        canvas.drawLine(Offset(w * 0.24, h * 0.42), Offset(w * 0.48, h * 0.42), faint);
        canvas.drawCircle(Offset(w * 0.88, h * 0.24), 5, Paint()..color = accent);

      case EmptyArt.clock:
        // A kitchen timer, for "waiting" screens.
        final c = Offset(w * 0.42, h * 0.55);
        canvas.drawCircle(c, 38, paper);
        canvas.drawCircle(c, 38, line);
        canvas.drawArc(Rect.fromCircle(center: c, radius: 28), -1.57, 4.2, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = accent);
        canvas.drawLine(c, Offset(c.dx, c.dy - 18), line);
        canvas.drawLine(c, Offset(c.dx + 12, c.dy + 6), line);
        canvas.drawLine(Offset(c.dx - 8, h * 0.06), Offset(c.dx + 8, h * 0.06), line);
        canvas.drawLine(Offset(c.dx, h * 0.06), Offset(c.dx, h * 0.15), line);
    }
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.art != art || old.ink != ink || old.fill != fill;
}
