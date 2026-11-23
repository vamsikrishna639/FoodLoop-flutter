// FoodLoop - app entry point.
// Creates the shared objects (API client, services, providers, router) and
// starts the UI.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/token_store.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/activity_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/claims_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/listings_provider.dart';
import 'providers/live_updates.dart';
import 'providers/notifications_provider.dart';
import 'providers/pickups_provider.dart';
import 'providers/theme_provider.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/claim_service.dart';
import 'services/dashboard_service.dart';
import 'services/food_service.dart';
import 'services/notification_service.dart';
import 'services/pickup_service.dart';
import 'widgets/impact_number.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // One API client for the whole app, so the token is set in one place.
  final api = ApiClient();
  final auth = AuthProvider(api, AuthService(api), TokenStore());
  final theme = ThemeProvider();
  final foods = FoodService(api);
  final feed = FeedProvider(foods);
  final listings = ListingsProvider(foods);
  final claims = ClaimsProvider(ClaimService(api));
  final dashboardService = DashboardService(api);
  final pickupService = PickupService(api);
  final notifications = NotificationsProvider(NotificationService(api));
  final activity = ActivityProvider(dashboardService);
  final dashboard = DashboardProvider(dashboardService);
  final pickups = PickupsProvider(pickupService);
  final admin = AdminProvider(pickupService, AdminService(api));

  // Bell badge and activity feed, refreshed only while the app is in front.
  final live = LiveUpdates(notifications: notifications, activity: activity);

  auth.addListener(() {
    // Poll only for approved accounts (pending ones see the waiting screen).
    live.setSignedIn(auth.status == AuthStatus.signedIn && (auth.user?.isApproved ?? false));

    // On sign-out, forget the previous user's lists so the next user never
    // sees them, even for a moment.
    if (auth.status == AuthStatus.signedOut) {
      feed.reset();
      listings.reset();
      claims.reset();
      notifications.reset();
      activity.reset();
      dashboard.reset();
      pickups.reset();
      admin.reset();
      ImpactNumber.forget(); // the next user's figures count up afresh
    }
  });

  // Start both in the background; the splash screen shows until auth is known.
  theme.load();
  auth.restore();

  runApp(FoodLoopApp(
    api: api,
    auth: auth,
    theme: theme,
    foods: foods,
    feed: feed,
    listings: listings,
    claims: claims,
    notifications: notifications,
    activity: activity,
    dashboard: dashboard,
    pickups: pickups,
    admin: admin,
  ));
}

class FoodLoopApp extends StatefulWidget {
  const FoodLoopApp({
    super.key,
    required this.api,
    required this.auth,
    required this.theme,
    required this.foods,
    required this.feed,
    required this.listings,
    required this.claims,
    required this.notifications,
    required this.activity,
    required this.dashboard,
    required this.pickups,
    required this.admin,
  });

  final ApiClient api;
  final AuthProvider auth;
  final ThemeProvider theme;
  final FoodService foods;
  final FeedProvider feed;
  final ListingsProvider listings;
  final ClaimsProvider claims;
  final NotificationsProvider notifications;
  final ActivityProvider activity;
  final DashboardProvider dashboard;
  final PickupsProvider pickups;
  final AdminProvider admin;

  @override
  State<FoodLoopApp> createState() => _FoodLoopAppState();
}

class _FoodLoopAppState extends State<FoodLoopApp> {
  // Built once: rebuilding the router would throw away the navigation state.
  late final GoRouter _router = buildRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: widget.api),
        Provider<FoodService>.value(value: widget.foods),
        ChangeNotifierProvider<AuthProvider>.value(value: widget.auth),
        ChangeNotifierProvider<ThemeProvider>.value(value: widget.theme),
        ChangeNotifierProvider<FeedProvider>.value(value: widget.feed),
        ChangeNotifierProvider<ListingsProvider>.value(value: widget.listings),
        ChangeNotifierProvider<ClaimsProvider>.value(value: widget.claims),
        ChangeNotifierProvider<NotificationsProvider>.value(value: widget.notifications),
        ChangeNotifierProvider<ActivityProvider>.value(value: widget.activity),
        ChangeNotifierProvider<DashboardProvider>.value(value: widget.dashboard),
        ChangeNotifierProvider<PickupsProvider>.value(value: widget.pickups),
        ChangeNotifierProvider<AdminProvider>.value(value: widget.admin),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp.router(
          title: 'FoodLoop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.paper,
          darkTheme: AppTheme.chalkboard,
          themeMode: theme.mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
