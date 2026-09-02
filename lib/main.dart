import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'core/supabase/supabase_config.dart';
import 'features/auth/data/user_repository.dart';
import 'core/services/push_notification_service.dart';
import 'core/navigation/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.load();
  await SupabaseClientService.initialize();
  await UserRepository.restoreSessionProfile();

  await PushNotificationService.instance.init();
  PushNotificationService.instance.onNotificationClick = (payload) {
    appRouter.go('/history');
  };

  if (UserRepository.currentUser != null) {
    // Langsung coba ambil token
    final token = await PushNotificationService.instance.getToken();
    if (token != null) {
      await UserRepository.updateFcmToken(token);
    }

    // Listener untuk token refresh (token baru saat rotasi kunci FCM, dll)
    PushNotificationService.instance.onTokenRefresh((newToken) {
      UserRepository.updateFcmToken(newToken);
    });
  }

  runApp(const ProviderScope(child: TaganaApp()));
}
