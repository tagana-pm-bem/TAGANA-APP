import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'core/supabase/supabase_config.dart';
import 'features/auth/data/user_repository.dart';
import 'core/services/push_notification_service.dart';
import 'core/navigation/app_router.dart';
import 'core/services/device_alert_service.dart';
import 'core/services/local_offline_detection_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/error_handler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.load();
  await SupabaseClientService.initialize();
  // Initialize push notifications first so token can be obtained
  // during session restore and other early flows.
  await PushNotificationService.instance.init();
  await UserRepository.restoreSessionProfile();

  // Start connectivity monitoring
  ConnectivityService.instance.startMonitoring();

  // Start local offline detection (for fallback when HP offline)
  LocalOfflineDetectionService.instance.startMonitoring();
  DeviceAlertService.instance.startMonitoring();
  PushNotificationService.instance.onNotificationClick = (payload) {
    appRouter.go('/history');
  };

  // Always listen for token refresh and update server when available.
  PushNotificationService.instance.onTokenRefresh((newToken) {
    UserRepository.updateFcmToken(newToken);
  });

  if (UserRepository.currentUser != null) {
    // If user session exists, try to fetch token immediately and save it.
    final token = await PushNotificationService.instance.getToken();
    if (token != null) {
      await UserRepository.updateFcmToken(token);
    }
  }

  runApp(const ProviderScope(child: TaganaApp()));
}
