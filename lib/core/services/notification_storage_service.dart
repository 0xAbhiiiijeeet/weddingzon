import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/models/notification_model.dart';

class NotificationStorageService {
  static const String _notificationsKey = 'user_notifications';

  /// Save a new notification to local storage
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getNotifications();

      // Add new notification to the beginning of the list
      notifications.insert(0, notification);

      // Limit to 50 stored notifications to manage size
      if (notifications.length > 50) {
        notifications.removeLast();
      }

      final String jsonList = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );

      await prefs.setString(_notificationsKey, jsonList);
      debugPrint(
        '[NOTIFICATION_STORAGE] Saved notification: ${notification.id}',
      );
    } catch (e) {
      debugPrint('[NOTIFICATION_STORAGE] Failed to save notification: $e');
    }
  }

  /// Retrieve all stored notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonList = prefs.getString(_notificationsKey);

      if (jsonList == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonList);
      return decoded.map((item) => NotificationModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[NOTIFICATION_STORAGE] Failed to load notifications: $e');
      return [];
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == id);

      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);

        final prefs = await SharedPreferences.getInstance();
        final String jsonList = jsonEncode(
          notifications.map((n) => n.toJson()).toList(),
        );
        await prefs.setString(_notificationsKey, jsonList);
      }
    } catch (e) {
      debugPrint('[NOTIFICATION_STORAGE] Failed to mark as read: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      debugPrint('[NOTIFICATION_STORAGE] Failed to clear notifications: $e');
    }
  }
}
