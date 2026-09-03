import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ");
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  static PushNotificationService get instance => _instance;
  PushNotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Function(String payload)? onNotificationClick;

  Future<void> init() async {
    if (_isInitialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && onNotificationClick != null) {
          onNotificationClick!(response.payload!);
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty && onNotificationClick != null) {
        onNotificationClick!(jsonEncode(message.data));
      }
    });

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null &&
        initialMessage.data.isNotEmpty &&
        onNotificationClick != null) {
      // Need a slight delay to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        onNotificationClick!(jsonEncode(initialMessage.data));
      });
    }

    _isInitialized = true;
  }

  Future<String?> getToken() async {
    // Ensure service initialized before requesting token.
    if (!_isInitialized) {
      try {
        await init();
      } catch (e) {
        print('[FCM] Failed to initialize before getToken: $e');
        return null;
      }
    }

    try {
      final token = await _fcm.getToken();
      print('[FCM] Token: $token');
      return token;
    } catch (e) {
      print('[FCM] Error getting token: $e');
      return null;
    }
  }

  void onTokenRefresh(void Function(String token) callback) {
    _fcm.onTokenRefresh.listen(callback);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    final notificationId = id == 0
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000
        : id;
    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Notifikasi penting TAGANA.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload ?? '{}',
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await showLocalNotification(
        title: notification.title ?? 'TAGANA',
        body: notification.body ?? 'Ada notifikasi baru',
        payload: jsonEncode(message.data),
      );
    }
  }
}
