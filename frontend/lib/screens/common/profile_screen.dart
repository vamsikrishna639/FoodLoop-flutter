// Profile and settings: who you are, the paper/chalkboard switch, sign out.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/fl_button.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/receipt_timeline.dart';
import '../../widgets/status_stamp.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return PageFrame(
      title: 'Profile',
      maxWidth: 560,
      children: [
        // The account, printed as a member slip with the role stamped on it.
        ReceiptTimeline(
          title: user.name,
          heading: 'Member slip',
          stamp: StatusStamp.custom(user.role.label.toUpperCase(), color: fl.chilliDeep),
          entries: [
            ReceiptEntry('Email', user.email),
            ReceiptEntry('Phone', user.phone),
            if (user.organization.isNotEmpty) ReceiptEntry('From', user.organization),
            ReceiptEntry('Account', user.isApproved ? 'Approved' : 'Waiting', emphasis: true),
          ],
        ),
        const SizedBox(height: FlSpace.xxl),

        Text('Appearance', style: context.text.headlineSmall),
        const SizedBox(height: FlSpace.sm),
        // The whole row toggles the switch, giving a large tap target.
        MergeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(FlRadius.control),
            onTap: () => theme.setChalkboard(!theme.isChalkboard),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FlSpace.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chalkboard mode', style: context.text.titleMedium),
                        Text(
                          theme.isChalkboard
                              ? 'Dark slate with chalk text'
                              : 'Warm paper with ink text',
                          style: context.text.bodyMedium?.copyWith(color: fl.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: theme.isChalkboard, onChanged: theme.setChalkboard),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: FlSpace.xxl),

        Wrap(
          spacing: FlSpace.md,
          runSpacing: FlSpace.md,
          children: [
            FlButton(
              label: 'Sign out',
              icon: Icons.logout,
              variant: FlButtonVariant.outline,
              onPressed: () => auth.logout(),
            ),
            TextButton(
              onPressed: () => context.push('/gallery'),
              child: const Text('Component gallery'),
            ),
          ],
        ),
      ],
    );
  }
}
