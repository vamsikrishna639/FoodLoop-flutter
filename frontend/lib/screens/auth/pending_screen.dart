// Shown to accounts that are not approved yet. They can sign in, but this
// is all they see until an admin approves them.
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/slip_snackbar.dart';
import '../../widgets/status_stamp.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.refreshUser();
      // If approved, the router has already moved on; otherwise say so.
      if (mounted && !(auth.user?.isApproved ?? false)) {
        showSlip(context, 'Still in the queue. An admin has not reviewed it yet.', note: true);
      }
    } on ApiException catch (e) {
      if (mounted) showSlip(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink(); // signing out

    final rejected = user.isRejected;
    final gutter = Breakpoints.gutter(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final message = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: EmptyStateArt(art: rejected ? EmptyArt.slip : EmptyArt.clock),
        ),
        const SizedBox(height: FlSpace.xl),
        Semantics(
          header: true,
          child: Text(
            rejected ? 'This token was not approved' : 'Your token is in the queue',
            style: wide ? context.text.displayMedium : context.text.displaySmall,
          ),
        ),
        const SizedBox(height: FlSpace.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            rejected
                ? 'An admin reviewed your account and could not approve it. '
                    'If you think that is a mistake, speak to the campus office.'
                : 'Thanks, ${user.name.split(' ').first}. An admin checks every new account '
                    'before it can post or request food. This usually takes less than a day.',
            style: context.text.bodyLarge?.copyWith(color: fl.inkSoft),
          ),
        ),
        const SizedBox(height: FlSpace.xl),
        Wrap(
          spacing: FlSpace.md,
          runSpacing: FlSpace.md,
          children: [
            if (!rejected)
              FlButton(
                label: 'Check again',
                loadingLabel: 'Checking',
                icon: Icons.refresh,
                loading: _checking,
                onPressed: _checkAgain,
              ),
            FlButton(
              label: 'Sign out',
              variant: FlButtonVariant.outline,
              onPressed: _checking ? null : () => auth.logout(),
            ),
          ],
        ),
      ],
    );

    final receipt = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: ReceiptTimeline(
        title: user.name,
        heading: 'Account slip',
        stamp: rejected
            ? const StatusStamp(StampKind.rejected)
            : const StatusStamp(StampKind.pending),
        entries: [
          ReceiptEntry('Role', user.role.label),
          if (user.organization.isNotEmpty) ReceiptEntry('From', user.organization),
          ReceiptEntry('Email', user.email),
          const ReceiptEntry('Registered', 'Done'),
          ReceiptEntry('Admin review', rejected ? 'Declined' : null, emphasis: true),
        ],
        footer: rejected ? null : 'Keep this slip',
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, FlSpace.xl, gutter, FlSpace.xxxl),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 28),
                  SizedBox(height: wide ? FlSpace.huge : FlSpace.xxl),
                  // Side by side on wide screens, stacked on phones.
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: message),
                        const SizedBox(width: FlSpace.xxxl),
                        Expanded(flex: 4, child: Align(alignment: Alignment.topLeft, child: receipt)),
                      ],
                    )
                  else ...[
                    message,
                    const SizedBox(height: FlSpace.xxl),
                    receipt,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
