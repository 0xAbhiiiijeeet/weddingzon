import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes/app_routes.dart';
import 'navigation_service.dart';
import 'notification_storage_service.dart';
import '../../features/notifications/models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint('[NOTIFICATION] Background message: ${message.messageId}');

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
      _showRemoteNotification(message);
      _saveNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[NOTIFICATION] App opened from terminated: ${initialMessage.data}',
      );
      _saveNotification(initialMessage);
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

  void _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) {
    _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weddingzon_channel',
          'WeddingZon Notifications',
          channelDescription: 'Notifications for WeddingZon updates',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _showRemoteNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
        id: notification.hashCode,
      );
    }
  }

  Future<void> handleSocketNotification(Map<String, dynamic> data) async {
    debugPrint('[NOTIFICATION] Handling socket notification: $data');

    final title = data['title'] ?? 'New Notification';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'general';

    _showLocalNotification(title: title, body: body, payload: jsonEncode(data));

    final model = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    await _storageService.saveNotification(model);
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
      _navigationService.pushNamedAndRemoveUntil(
        AppRoutes.connections,
        arguments: {'initialIndex': 0},
      );
    } else if (type == 'photo_access_request') {
      debugPrint(
        '[NOTIFICATION] Routing to Invites tab for photo access request',
      );
      _navigationService.pushNamedAndRemoveUntil(
        AppRoutes.connections,
        arguments: {'initialIndex': 0},
      );
    } else if (type == 'details_access_request') {
      debugPrint(
        '[NOTIFICATION] Routing to Invites tab for details access request',
      );
      _navigationService.pushNamedAndRemoveUntil(
        AppRoutes.connections,
        arguments: {'initialIndex': 0},
      );
    } else if (type == 'request_accepted') {
      _navigationService.pushNamedAndRemoveUntil(
        AppRoutes.connections,
        arguments: {'initialIndex': 1},
      );
    } else if (type == 'photo_access_granted') {
      debugPrint(
        '[NOTIFICATION] Routing to Notifications tab for photo access granted',
      );
      _navigationService.pushNamedAndRemoveUntil(
        AppRoutes.connections,
        arguments: {'initialIndex': 1},
      );
    } else if (type == 'details_access_granted') {
      debugPrint(
        '[NOTIFICATION] Routing to Notifications tab for details access granted',
      );
      _navigationService.pushNamedAndRemoveUntil(
        AppRoutes.connections,
        arguments: {'initialIndex': 1},
      );
    } else if (type == 'chat_message') {
      debugPrint(
        '[NOTIFICATION] Routing to conversations screen for chat message',
      );
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.chatTab);
    } else if (type == 'profile_view') {
      debugPrint('[NOTIFICATION] Routing to profile viewers screen');
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.profileViewers);
    } else {
      debugPrint('[NOTIFICATION] Unknown notification type: $type');
      _navigationService.pushNamedAndRemoveUntil(AppRoutes.feed);
    }
  }
}