import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_page.dart';
import '../../features/device/device_detail_page.dart';
import '../../features/history/history_page.dart';
import '../../features/map/map_page.dart';
import '../../features/onboarding/splash_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/onboarding/welcome_page.dart';
import '../../features/onboarding/register.dart';
import '../../features/onboarding/enter_device.dart';
import '../../features/onboarding/verifying_device.dart';
import '../../features/onboarding/bluetooth_connection.dart';
import '../../features/onboarding/connection_success.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/enter-device',
      builder: (context, state) => const EnterDevicePage(),
    ),
    GoRoute(
      path: '/verifying-device/:deviceCode',
      builder: (context, state) {
        final deviceCode = state.pathParameters['deviceCode'] ?? 'UNKNOWN';
        return DeviceVerificationPage(
          deviceCode: deviceCode,
          onContinue: () => context.go('/bluetooth/$deviceCode?auto=1'),
        );
      },
    ),
    GoRoute(
      path: '/bluetooth/:deviceCode',
      builder: (context, state) {
        final deviceCode = state.pathParameters['deviceCode'] ?? 'UNKNOWN';
        final auto =
            state.uri.queryParameters['auto'] == '1' ||
            state.uri.queryParameters['auto'] == 'true';
        // If auto=true, immediately continue to the success page to
        // simulate a connected device (useful for demo/dev builds).
        if (auto) {
          // schedule navigation after the current microtask so builder can finish
          Future.microtask(
            () => context.go('/connection-success/$deviceCode'),
          );
        }

        return BluetoothConnectionPage(
          deviceNamePrefix: 'TAGANA',
          onConnected: (info) => context.go(
            '/connection-success/${info.deviceId}',
            extra: info,
          ),
        );
      },
    ),
    GoRoute(
      path: '/connection-success/:deviceId',
      builder: (context, state) {
        final deviceId = state.pathParameters['deviceId'] ?? 'UNKNOWN';
        // Passed from the bluetooth page via `extra` when a real device
        // just connected. Falls back to defaults for direct/deeplink or
        // the auto=1 demo flow where no real device info exists yet.
        final info = state.extra is BluetoothDeviceInfo
            ? state.extra as BluetoothDeviceInfo
            : null;

        return ConnectionSuccessPage(
          deviceName: info?.name ?? 'TAGANA-001',
          deviceId: info?.deviceId ?? deviceId,
          onContinue: () => context.go('/dashboard'),
        );
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    GoRoute(path: '/map', builder: (context, state) => const MapPage()),

    GoRoute(path: '/history', builder: (context, state) => const HistoryPage()),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    GoRoute(
      path: '/device/:id',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;

        return DeviceDetailPage(deviceId: deviceId);
      },
    ),
  ],
);