// The right-hand rail on desktop: recent activity printed like a till roll.
//
//   Activity
//   WHAT JUST HAPPENED
//   · · · · · · · · · · · · · · · ·
//   REQUEST            2 min ago
//   Ananya Rao requested 6 packets
//   of Veg Grilled Sandwiches
//   · · · · · · · · · · · · · · · ·
//
// The server decides what this user may see (admin: everything; donor:
// their own listings; recipient and volunteer: their own requests or runs).
// LiveUpdates reloads it every 20 seconds while the app is in front. Only
// lines that were not there on the previous load fade in, so the rail is
// still while nothing changes. It stays quiet (no illustration) so it never
// competes with the page beside it.
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme/tokens.dart';
import '../models/activity_event.dart';
import '../providers/activity_provider.dart';
import 'paper_shapes.dart';

class ActivityRail extends StatefulWidget {
  const ActivityRail({super.key});

  @override
  State<ActivityRail> createState() => _ActivityRailState();
}

class _ActivityRailState extends State<ActivityRail> {
  late final ActivityProvider _activity = context.read<ActivityProvider>();

  @override
  void initState() {
    super.initState();
    // Tell the poller a rail is showing, and fill it now rather than at the
    // next tick.
    _activity.attach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activity.load();
    });
  }

  @override
  void dispose() {
    _activity.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final activity = context.watch<ActivityProvider>();
    final events = activity.events;

    Widget body;
    if (events == null && activity.error != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activity.error!, style: context.text.bodyMedium?.copyWith(color: fl.inkSoft)),
          TextButton(onPressed: activity.load, child: const Text('Try again')),
        ],
      );
    } else if (events == null) {
      body = Text('READING THE ROLL...', style: fl.monoSmall);
    } else if (events.isEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTHING PRINTED YET', style: fl.monoSmall),
          const SizedBox(height: FlSpace.sm),
          Text(
            'Requests, approvals and deliveries will print here as they happen.',
            style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in events)
            _ArrivingLine(
              key: ValueKey(e.id),
              animate: activity.fresh.contains(e.id),
              child: _EventLine(event: e),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(FlSpace.xl, FlSpace.xxxl, FlSpace.xl, FlSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('Activity', style: context.text.titleLarge)),
          const SizedBox(height: FlSpace.xxs),
          Text('WHAT JUST HAPPENED', style: fl.monoSmall),
          const SizedBox(height: FlSpace.md),
          DottedLine(color: fl.perforation, dot: 2, gap: 4),
          // New lines are announced by screen readers without moving focus.
          Semantics(liveRegion: true, container: true, child: body),
        ],
      ),
    );
  }
}

/// One printed line: the kind in mono, how long ago, then the sentence.
class _EventLine extends StatelessWidget {
  const _EventLine({required this.event});
  final ActivityEvent event;

  /// The printed word in front of each line.
  static String wordFor(String kind) => switch (kind) {
        'posted' => 'POSTED',
        'requested' => 'REQUEST',
        'approved' => 'APPROVED',
        'rejected' => 'TURNED DOWN',
        'cancelled' => 'CANCELLED',
        'assigned' => 'ASSIGNED',
        'picked_up' => 'PICKED UP',
        'delivered' => 'DELIVERED',
        _ => 'NOTE',
      };

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    // The word always carries the meaning; colour only adds to it.
    final wordColor = switch (event.kind) {
      'delivered' => fl.leaf,
      'rejected' => fl.chilliDeep,
      'posted' => fl.ink,
      _ => fl.inkSoft,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: FlSpace.md),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: fl.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(wordFor(event.kind), style: fl.monoSmall.copyWith(color: wordColor, fontWeight: FontWeight.w700)),
              ),
              Text(Fmt.ago(event.at), style: fl.monoSmall),
            ],
          ),
          const SizedBox(height: FlSpace.xs),
          Text(event.text, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

/// Fades a new line in while it settles 6px down into place (200ms,
/// ease-out). Lines already on the roll are shown as they are. Under reduced
/// motion only the fade remains.
class _ArrivingLine extends StatelessWidget {
  const _ArrivingLine({super.key, required this.animate, required this.child});
  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    final move = !FlMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: FlMotion.base,
      curve: FlMotion.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, move ? -6 * (1 - t) : 0), child: child),
      ),
      child: child,
    );
  }
}
