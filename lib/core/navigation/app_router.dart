import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_page.dart';
import '../../features/device/ble_connect_page.dart';
import '../../features/device/device_detail_page.dart';
import '../../features/device/devices_page.dart';
import '../../features/device/test_connection_page.dart';
import '../../features/device/emergency_page.dart';
import '../../features/device/hotspot_page.dart';
import '../../features/device/webview_page.dart';
import '../../features/device/wifi_config_page.dart';
import '../../features/device/wifi_connecting_page.dart';
import '../../features/device/wifi_connected_page.dart';
import '../../features/history/history_page.dart';
import '../../features/map/map_page.dart';
import '../../features/onboarding/splash_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/pages/profile_page.dart';
import '../../features/settings/pages/phone_page.dart';
import '../../features/settings/pages/edit_profile_page.dart';
import '../../features/settings/pages/help_page.dart';
import '../../features/settings/pages/about_page.dart';
import '../../features/onboarding/welcome_page.dart';
import '../../features/onboarding/register.dart';
import '../../features/onboarding/login.dart';
import '../../features/onboarding/enter_device.dart';
import '../../features/onboarding/verifying_device.dart';
import '../../features/onboarding/bluetooth_connection.dart';
import '../../features/onboarding/connection_success.dart';
import '../services/device_service.dart';
import '../widgets/animated_branch_container.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
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
          // Verifikasi nyata: cek kode di Supabase dan pasangkan ke user
          verifyDevice: DeviceService.verifyAndPairDevice,
          // Setelah verifikasi sukses, lanjut ke halaman BLE scan
          onContinue: () => context.go('/bluetooth/$deviceCode'),
        );
      },
    ),
    GoRoute(
      path: '/bluetooth/:deviceCode',
      builder: (context, state) {
        final deviceCode = state.pathParameters['deviceCode'] ?? '';
        final expectedName = deviceCode.isNotEmpty ? deviceCode.replaceFirst('TGN_', 'TAGANA ') : 'TAGANA';
        return BluetoothConnectionPage(
          deviceNamePrefix: expectedName,
          onConnected: (info) =>
              context.go('/connection-success/${info.deviceId}', extra: info),
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
          bleDevice: info?.device,
          onContinue: () => context.go('/dashboard'),
        );
      },
    ),

    // ShellRoute for main app navigation with bottom bar
    StatefulShellRoute(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/devices',
              builder: (context, state) => const DevicesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // Detail pages outside the shell (hides bottom nav)
    // Settings detail routes (no bottom navigation)
    GoRoute(
      path: '/settings/profile',
      pageBuilder: (context, state) =>
          NoTransitionPage(child: const ProfilePage()),
    ),
    GoRoute(
      path: '/settings/phone',
      pageBuilder: (context, state) =>
          NoTransitionPage(child: const PhonePage()),
    ),
    GoRoute(
      path: '/settings/edit-profile',
      pageBuilder: (context, state) =>
          NoTransitionPage(child: const EditProfilePage()),
    ),
    GoRoute(
      path: '/settings/help',
      pageBuilder: (context, state) =>
          NoTransitionPage(child: const HelpPage()),
    ),
    GoRoute(
      path: '/settings/about',
      pageBuilder: (context, state) =>
          NoTransitionPage(child: const AboutPage()),
    ),
    GoRoute(
      path: '/device/:id',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        bool isOnline = true;
        String? deviceCode;

        if (state.extra is bool) {
          isOnline = state.extra as bool;
        } else if (state.extra is Map<String, dynamic>) {
          final extraMap = state.extra as Map<String, dynamic>;
          isOnline = extraMap['isOnline'] as bool? ?? true;
          deviceCode = extraMap['deviceCode'] as String?;
        }

        return DeviceDetailPage(
          deviceId: deviceId, 
          isOnline: isOnline, 
          initialDeviceCode: deviceCode
        );
      },
    ),
    GoRoute(
      path: '/device/:id/test-connection',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        return TestConnectionPage(deviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/device/:id/emergency',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        return EmergencyPage(deviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/device/:id/hotspot',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        return HotspotPage(deviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/device/:id/local-web',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        return LocalWebViewPage(deviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/device/:id/ble',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        final deviceCode = state.uri.queryParameters['code'];
        final deviceName = state.uri.queryParameters['name'];
        final returnTo = state.uri.queryParameters['returnTo'];
        return BleConnectPage(
          deviceId: deviceId, 
          deviceCode: deviceCode, 
          deviceName: deviceName,
          returnTo: returnTo
        );
      },
    ),
    GoRoute(
      path: '/device/:id/wifi-config',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        return WifiConfigPage(deviceId: deviceId);
      },
    ),
    GoRoute(
      path: '/device/:id/wifi-connecting',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        final ssid = state.uri.queryParameters['ssid'] ?? '';
        final password = state.uri.queryParameters['password'] ?? '';
        return WifiConnectingPage(deviceId: deviceId, ssid: ssid, password: password);
      },
    ),
    GoRoute(
      path: '/device/:id/wifi-connected',
      builder: (context, state) {
        final deviceId = state.pathParameters['id']!;
        final ssid = state.uri.queryParameters['ssid'] ?? '';
        return WifiConnectedPage(deviceId: deviceId, ssid: ssid);
      },
    ),
  ],
);
