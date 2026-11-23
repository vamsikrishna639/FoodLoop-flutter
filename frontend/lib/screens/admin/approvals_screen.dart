// Approvals: new accounts wait here until the admin lets them in.
//
// Wide content (640px or more): a printed table, like a register at the
// canteen office.
//   NAME / FROM        CONTACT            ROLE / JOINED   DECISION
//   Rohit Verma        rohit@...          RECIPIENT       [Approve] [Reject]
//   Hope Foundation    9000000007         Today
// Narrow content: the same facts as stacked slips, one per account.
//
// An account decided on this visit stays under "Waiting" with its stamp, so
// the admin sees the result where they clicked. It moves to "Decided" on
// the next visit.
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/filter_tag.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/skeleton_token.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  bool _showDecided = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final all = admin.accounts;
    // Waiting: still pending, plus anything decided on this visit.
    // Oldest registration first, so nobody waits longest.
    final waiting = [
      for (final u in all ?? const <AppUser>[])
        if (u.isPending || admin.decidedHere.contains(u.id)) u,
    ]..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    final decided = [
      for (final u in all ?? const <AppUser>[])
        if (!u.isPending && !admin.decidedHere.contains(u.id)) u,
    ];
    final shown = _showDecided ? decided : waiting;
    final pendingCount = waiting.where((u) => u.isPending).length;

    Widget body;
    if (all == null && admin.accountsError != null) {
      body = EmptyState.error(message: admin.accountsError!, onRetry: admin.loadAccounts);
    } else if (all == null) {
      body = const SkeletonToken();
    } else if (shown.isEmpty) {
      body = _showDecided
          ? const EmptyState(
              art: EmptyArt.slip,
              title: 'No decisions yet',
              message: 'Approved and rejected accounts are listed here as a record.',
            )
          : const EmptyState(
              art: EmptyArt.clock,
              title: 'Nobody is waiting',
              message: 'New sign-ups appear here. Until you approve them they only see a waiting screen.',
            );
    } else {
      body = LayoutBuilder(
        builder: (context, box) => box.maxWidth >= 640 ? _Register(users: shown) : _Slips(users: shown),
      );
    }

    return PageFrame(
      title: 'Approvals',
      lede: 'Check that each person belongs to a real campus group before letting them in.',
      maxWidth: 1040,
      children: [
        Wrap(
          spacing: FlSpace.sm,
          children: [
            FilterTag(
              label: 'Waiting  ${all == null ? '' : pendingCount}'.trim(),
              selected: !_showDecided,
              onTap: () => setState(() => _showDecided = false),
            ),
            FilterTag(
              label: 'Decided  ${all == null ? '' : decided.length}'.trim(),
              selected: _showDecided,
              onTap: () => setState(() => _showDecided = true),
            ),
          ],
        ),
        const SizedBox(height: FlSpace.xl),
        body,
      ],
    );
  }
}

/// The printed table for wide screens.
class _Register extends StatelessWidget {
  const _Register({required this.users});
  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    Widget head(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: FlSpace.md, vertical: FlSpace.sm),
          child: Text(text, style: fl.monoSmall.copyWith(color: fl.ink, fontWeight: FontWeight.w700)),
        );
    Widget cell(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: FlSpace.md, vertical: FlSpace.md),
          child: child,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fl.surface,
        borderRadius: BorderRadius.circular(FlRadius.sharp),
        border: Border.all(color: fl.line),
      ),
      child: Table(
        // Fits the ~690px left beside the desktop activity rail.
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.2),
          2: FixedColumnWidth(124),
          3: FixedColumnWidth(236),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(horizontalInside: BorderSide(color: fl.line)),
        children: [
          TableRow(
            decoration: BoxDecoration(color: fl.surfaceSunken),
            children: [head('NAME / FROM'), head('CONTACT'), head('ROLE / JOINED'), head('DECISION')],
          ),
          for (final u in users)
            TableRow(
              key: ValueKey(u.id),
              children: [
                cell(_NameBlock(user: u)),
                cell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.email, style: fl.mono, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(u.phone, style: fl.mono.copyWith(color: fl.inkSoft)),
                  ],
                )),
                cell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoleStamp(role: u.role),
                    const SizedBox(height: FlSpace.sm),
                    Text(u.createdAt == null ? '--' : Fmt.day(u.createdAt!), style: fl.monoSmall),
                  ],
                )),
                cell(_Decision(user: u, compact: true)),
              ],
            ),
        ],
      ),
    );
  }
}

/// The same facts as stacked slips for phones and narrow tablets.
class _Slips extends StatelessWidget {
  const _Slips({required this.users});
  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final u in users)
          Container(
            key: ValueKey(u.id),
            margin: const EdgeInsets.only(bottom: FlSpace.md),
            padding: const EdgeInsets.all(FlSpace.lg),
            decoration: BoxDecoration(
              color: fl.surface,
              borderRadius: BorderRadius.circular(FlRadius.sharp),
              border: Border.all(color: fl.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _NameBlock(user: u)),
                    const SizedBox(width: FlSpace.md),
                    Padding(padding: const EdgeInsets.only(top: FlSpace.xs), child: _RoleStamp(role: u.role)),
                  ],
                ),
                const SizedBox(height: FlSpace.md),
                Text(u.email, style: fl.mono),
                Text(
                  '${u.phone}${u.createdAt == null ? '' : ' · joined ${Fmt.day(u.createdAt!)}'}',
                  style: fl.mono.copyWith(color: fl.inkSoft),
                ),
                const SizedBox(height: FlSpace.md),
                _Decision(user: u),
              ],
            ),
          ),
      ],
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.name, style: context.text.titleMedium),
        if (user.organization.isNotEmpty)
          Text(user.organization, style: context.text.bodySmall?.copyWith(color: context.fl.inkSoft)),
      ],
    );
  }
}

/// The role as a small ink stamp ("VOLUNTEER"), the way it is on the profile.
class _RoleStamp extends StatelessWidget {
  const _RoleStamp({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) =>
      StatusStamp.custom(role.label.toUpperCase(), color: context.fl.ink, scale: 0.85, angle: -3);
}

/// Approve / Reject while pending; afterwards the decision as a stamp.
class _Decision extends StatefulWidget {
  const _Decision({required this.user, this.compact = false});
  final AppUser user;

  /// In the table the Approve button drops its icon so both buttons fit
  /// on one line beside the activity rail.
  final bool compact;

  @override
  State<_Decision> createState() => _DecisionState();
}

class _DecisionState extends State<_Decision> {
  bool? _busyApproving; // null = idle

  Future<void> _decide({required bool approve}) async {
    final u = widget.user;
    if (!approve) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Reject ${u.name}?'),
          content: Text(
            '${u.name} will not be able to use FoodLoop. Their waiting screen will say the account was not approved.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep waiting')),
            FlButton(label: 'Reject', onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }

    final admin = context.read<AdminProvider>();
    final dashboard = context.read<DashboardProvider>();
    setState(() => _busyApproving = approve);
    try {
      final message = await admin.verify(u, approve: approve);
      dashboard.load(); // the "accounts waiting" count changed
      if (mounted) showSlip(context, message);
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
      admin.loadAccounts();
    }
    if (mounted) setState(() => _busyApproving = null);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    if (!u.isPending) {
      final stamp = StatusStamp(u.isApproved ? StampKind.approved : StampKind.rejected);
      // Only a decision made just now fades in; older ones are simply printed.
      final justNow = context.read<AdminProvider>().decidedHere.contains(u.id);
      return Align(alignment: Alignment.centerLeft, child: justNow ? FadeIn(child: stamp) : stamp);
    }
    final idle = _busyApproving == null;
    return Wrap(
      spacing: FlSpace.sm,
      runSpacing: FlSpace.sm,
      children: [
        FlButton(
          label: 'Approve',
          icon: widget.compact ? null : Icons.check,
          loading: _busyApproving == true,
          loadingLabel: 'Approving',
          onPressed: idle ? () => _decide(approve: true) : null,
        ),
        FlButton(
          label: 'Reject',
          variant: FlButtonVariant.outline,
          loading: _busyApproving == false,
          loadingLabel: 'Rejecting',
          onPressed: idle ? () => _decide(approve: false) : null,
        ),
      ],
    );
  }
}
