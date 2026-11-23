// All routes, plus the rules that decide who may see what.
//
// The redirect function runs before every navigation and again whenever
// AuthProvider changes (login, logout, approval), so users are always moved
// to the correct place without each screen having to check.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../screens/admin/approvals_screen.dart';
import '../../screens/admin/overview_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/pending_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/common/alerts_screen.dart';
import '../../screens/common/gallery_screen.dart';
import '../../screens/common/profile_screen.dart';
import '../../screens/common/splash_screen.dart';
import '../../screens/common/welcome_screen.dart';
import '../../screens/donor/board_screen.dart';
import '../../screens/donor/listing_form.dart';
import '../../screens/donor/manage_listings_screen.dart';
import '../../screens/recipient/feed_screen.dart';
import '../../screens/recipient/listing_detail.dart';
import '../../screens/recipient/my_requests_screen.dart';
import '../../screens/volunteer/pickups_screen.dart';
import '../../widgets/activity_rail.dart';
import '../../widgets/responsive_shell.dart';
import '../theme/tokens.dart';

/// Pages each role may open inside the shell. Anything else goes to /home.
/// Sub-pages are allowed with their parent: '/home' also allows
/// '/home/listing/42'.
const Map<UserRole, Set<String>> _allowed = {
  UserRole.recipient: {'/home', '/requests', '/notifications', '/profile'},
  UserRole.donor: {'/home', '/listings', '/notifications', '/profile'},
  UserRole.volunteer: {'/home', '/notifications', '/profile'},
  UserRole.admin: {'/home', '/approvals', '/listings', '/notifications', '/profile'},
};

/// The navigation shown to each role. [unread] is the number on the bell.
List<ShellDestination> destinationsFor(UserRole role, {int unread = 0}) {
  final alerts = ShellDestination(
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    path: '/notifications',
    badge: unread,
  );
  return switch (role) {
      UserRole.recipient => [
          const ShellDestination(label: 'Counter', icon: Icons.storefront_outlined, path: '/home'),
          const ShellDestination(label: 'Requests', icon: Icons.receipt_long_outlined, path: '/requests'),
          alerts,
          const ShellDestination(label: 'Profile', icon: Icons.person_outline, path: '/profile'),
        ],
      UserRole.donor => [
          const ShellDestination(label: 'Board', icon: Icons.dashboard_outlined, path: '/home'),
          const ShellDestination(label: 'Listings', icon: Icons.confirmation_number_outlined, path: '/listings'),
          alerts,
          const ShellDestination(label: 'Profile', icon: Icons.person_outline, path: '/profile'),
        ],
      UserRole.volunteer => [
          const ShellDestination(label: 'Pickups', icon: Icons.pedal_bike_outlined, path: '/home'),
          alerts,
          const ShellDestination(label: 'Profile', icon: Icons.person_outline, path: '/profile'),
        ],
      UserRole.admin => [
          const ShellDestination(label: 'Overview', icon: Icons.insights_outlined, path: '/home'),
          const ShellDestination(label: 'Approvals', icon: Icons.how_to_reg_outlined, path: '/approvals'),
          const ShellDestination(label: 'Listings', icon: Icons.confirmation_number_outlined, path: '/listings'),
          alerts,
          const ShellDestination(label: 'Profile', icon: Icons.person_outline, path: '/profile'),
        ],
    };
}

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.matchedLocation;

      // The gallery is open to everyone, signed in or not.
      if (path == '/gallery') return null;

      switch (auth.status) {
        case AuthStatus.restoring:
          // Wait on the splash screen while the saved session is checked, and
          // remember the page that was asked for (e.g. after a browser
          // refresh on /profile) so the user can be sent back to it.
          if (path == '/splash') return null;
          return Uri(path: '/splash', queryParameters: {'from': state.uri.toString()}).toString();

        case AuthStatus.signedOut:
          // First visit on this device: show the welcome slides once.
          if (!auth.seenWelcome) return path == '/welcome' ? null : '/welcome';
          return const {'/login', '/register', '/welcome'}.contains(path) ? null : '/login';

        case AuthStatus.signedIn:
          final user = auth.user!;
          // Pending and rejected accounts only ever see the waiting screen.
          if (!user.isApproved) return path == '/pending' ? null : '/pending';
          // Session restored: go back to the page that was asked for. The
          // redirect runs again on that page, so the role check below still
          // applies to it.
          if (path == '/splash') {
            final from = state.uri.queryParameters['from'];
            if (from != null && from.startsWith('/') && !from.startsWith('/splash')) return from;
            return '/home';
          }
          // Approved users have no business on the entry screens.
          if (const {'/login', '/register', '/pending', '/welcome'}.contains(path)) return '/home';
          // Role-based access: e.g. a recipient typing /approvals goes home.
          final allowed = _allowed[user.role]!;
          if (!allowed.any((p) => path == p || path.startsWith('$p/'))) return '/home';
          // The listing detail page belongs to the recipient's counter.
          if (path.startsWith('/home/listing/') && user.role != UserRole.recipient) return '/home';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', pageBuilder: (_, s) => _fade(s, const WelcomeScreen())),
      GoRoute(path: '/login', pageBuilder: (_, s) => _fade(s, const LoginScreen())),
      GoRoute(path: '/register', pageBuilder: (_, s) => _fade(s, const RegisterScreen())),
      GoRoute(path: '/pending', pageBuilder: (_, s) => _fade(s, const PendingScreen())),
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),

      // Everything below is wrapped in the ResponsiveShell.
      ShellRoute(
        builder: (context, state, child) {
          final user = auth.user;
          if (user == null) return const SizedBox.shrink(); // mid sign-out
          // Only the unread count rebuilds the shell, not every notification.
          final unread = context.select<NotificationsProvider, int>((n) => n.unread);
          return ResponsiveShell(
            user: user,
            destinations: destinationsFor(user.role, unread: unread),
            currentPath: state.matchedLocation,
            onNavigate: (path) => context.go(path),
            action: _actionFor(context, user.role),
            activityRail: const ActivityRail(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, s) => _fade(s, _HomeForRole(auth: auth)),
            routes: [
              // Phones open a token's details as its own page; the card
              // flies into it (Hero). Wider screens use a side panel instead.
              GoRoute(
                path: 'listing/:id',
                pageBuilder: (_, s) => _fade(s, ListingDetailScreen(id: s.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(path: '/requests', pageBuilder: (_, s) => _fade(s, const MyRequestsScreen())),
          GoRoute(
            path: '/listings',
            // Donors manage their own tokens; the admin sees every listing.
            pageBuilder: (_, s) => _fade(
              s,
              ManageListingsScreen(admin: auth.user?.role == UserRole.admin),
            ),
          ),
          GoRoute(path: '/approvals', pageBuilder: (_, s) => _fade(s, const ApprovalsScreen())),
          GoRoute(path: '/notifications', pageBuilder: (_, s) => _fade(s, const AlertsScreen())),
          GoRoute(path: '/profile', pageBuilder: (_, s) => _fade(s, const ProfileScreen())),
        ],
      ),
    ],
  );
}

/// A short cross-fade between pages: 200ms in, 120ms back. It only changes
/// opacity, so it stays under reduced motion (the Hero, which moves, does not).
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: FlMotion.base,
    reverseTransitionDuration: FlMotion.fast,
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: FlMotion.easeOut),
        child: child,
      );
    },
  );
}

/// The raised centre action on mobile / the red button in the sidebar.
ShellAction? _actionFor(BuildContext context, UserRole role) => switch (role) {
      UserRole.donor => ShellAction(
          label: 'Post food',
          icon: Icons.add,
          onTap: () => showListingForm(context),
        ),
      // Browse goes to the counter and puts the cursor in its search field
      // (on phones this also opens the keyboard).
      UserRole.recipient => ShellAction(
          label: 'Browse',
          icon: Icons.search,
          onTap: () {
            context.read<FeedProvider>().requestSearchFocus();
            context.go('/home');
          },
        ),
      _ => null,
    };

/// Home differs per role.
class _HomeForRole extends StatelessWidget {
  const _HomeForRole({required this.auth});
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return switch (auth.user?.role) {
      UserRole.donor => const BoardScreen(),
      UserRole.volunteer => const PickupsScreen(),
      UserRole.admin => const OverviewScreen(),
      _ => const FeedScreen(),
    };
  }
}
