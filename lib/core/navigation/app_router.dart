import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_page.dart';
import '../../features/device/device_detail_page.dart';
import '../../features/history/history_page.dart';
import '../../features/map/map_page.dart';
import '../../features/onboarding/splash_page.dart';
import '../../features/settings/settings_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),

    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    GoRoute(
      path: '/map',
      builder: (context, state) => const MapPage(),
    ),

    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    GoRoute(
      path: '/device/:id',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;

        return DeviceDetailPage(
          deviceId: deviceId,
        );
      },
    ),
  ],
);