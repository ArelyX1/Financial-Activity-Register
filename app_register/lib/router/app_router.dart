import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/executive_dashboard_page.dart';
import '../pages/activity_history_page.dart';
import '../pages/activity_registration_form_page.dart';
import '../pages/executive_profile_page.dart';
import '../pages/executive_onboarding_page.dart';
import '../pages/navigation_menu_page.dart';
import '../pages/settings_notifications_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const ExecutiveDashboardPage(),
    ),
    GoRoute(
      path: '/activity/history',
      name: 'activityHistory',
      builder: (context, state) => const ActivityHistoryPage(),
    ),
    GoRoute(
      path: '/activity/register',
      name: 'activityRegister',
      builder: (context, state) => const ActivityRegistrationFormPage(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ExecutiveProfilePage(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const ExecutiveOnboardingPage(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (context, state) => const NavigationMenuPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsNotificationsPage(),
    ),
  ],
);
