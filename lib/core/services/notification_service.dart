import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes/app_routes.dart';
import 'navigation_service.dart';
import 'notification_storage_service.dart';
import '../../features/notifications/models/notification_model.dart';

/// Top-level function for background messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint('[NOTIFICATION] Background message: ${message.messageId}');

  // NOTE: Saving background notifications to local storage might be tricky
  // because SharedPreferences/FlutterSecureStorage may not be accessible in isolate
  // without re-initializing dependencies.
  // For simplicity MVP, we'll focus on foreground/opened.
  // If needed, we'd initialize NotificationStorageService here too.
}

class NotificationService {
  late final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NavigationService _navigationService;
  final NotificationStorageService _storageService;

  NotificationService(this._navigationService, this._storageService) {
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  Future<void> initialize() async {
    await _requestPermission();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _handleNavigation(data);
          } catch (e) {
            debugPrint('[NOTIFICATION] Payload decode error: $e');
          }
        }
      },
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(
      const AndroidNotificationChannel(
        'weddingzon_channel',
        'WeddingZon Notifications',
        description: 'Notifications for WeddingZon updates',
        importance: Importance.max,
      ),
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[NOTIFICATION] Foreground message: ${message.notification?.title}',
      );
      _showLocalNotification(message);
      _saveNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[NOTIFICATION] App opened from terminated: ${initialMessage.data}',
      );
      _saveNotification(initialMessage);
      // Delay navigation slightly to ensure app is ready
      Future.delayed(const Duration(seconds: 1), () {
        _handleNavigation(initialMessage.data);
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[NOTIFICATION] App opened from background: ${message.data}');
      _saveNotification(message);
      _handleNavigation(message.data);
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      '[NOTIFICATION] Permission status: ${settings.authorizationStatus}',
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('[NOTIFICATION] FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('[NOTIFICATION] Failed to get token: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      debugPrint('[NOTIFICATION] Token deleted');
    } catch (e) {
      debugPrint('[NOTIFICATION] Delete token error: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // Only show if notification has title/body
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'weddingzon_channel', // id
            'WeddingZon Notifications', // name
            channelDescription: 'Notifications for WeddingZon updates',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> _saveNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification.title ?? 'New Notification',
      body: notification.body ?? '',
      type: message.data['type'] ?? 'general',
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
    );

    await _storageService.saveNotification(model);
  }

  void _handleNavigation(Map<String, dynamic> data) {
    debugPrint('[NOTIFICATION] Handling navigation for payload: $data');
    final type = data['type'];

    if (type == 'connection_request') {
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.feed);
    } else if (type == 'request_accepted') {
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.feed);
    } else if (type == 'chat_message') {
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.chatTab);
    } else {
      debugPrint('[NOTIFICATION] Unknown notification type: $type');
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.feed);
    }
  }
}
