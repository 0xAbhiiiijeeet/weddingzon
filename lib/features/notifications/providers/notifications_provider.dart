import 'package:flutter/material.dart';
import '../../../../core/services/notification_storage_service.dart';
import '../models/notification_model.dart';
import '../../connections/repositories/connections_repository.dart';

class NotificationsProvider with ChangeNotifier {
  final NotificationStorageService _storageService;
  final ConnectionsRepository _connectionsRepository;

  NotificationsProvider(this._storageService, this._connectionsRepository);

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    if (_notifications.isEmpty || forceRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    final local = await _storageService.getNotifications();
    List<NotificationModel> tempList = List.from(local);

    await _loadAcceptedConnections(tempList);

    _notifications = tempList;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAcceptedConnections(
    List<NotificationModel> targetList,
  ) async {
    final response = await _connectionsRepository.getNotifications();
    if (response.success && response.data != null) {
      final notifications = response.data as List<dynamic>;
      debugPrint(
        '[NOTIFICATIONS] Fetched ${notifications.length} notifications from backend',
      );

      final backendNotifications = notifications.map((n) {
        debugPrint('[NOTIFICATIONS] Raw notification data: $n');

        final otherUser =
            n['otherUser'] ?? n['targetUser'] ?? n['recipient'] ?? {};
        final username = otherUser['username'] ?? 'UnknownUser';
        final displayName =
            otherUser['displayName'] ??
            otherUser['display_name'] ??
            '${otherUser['first_name'] ?? ''} ${otherUser['last_name'] ?? ''}'
                .trim();
        final finalName = displayName.isNotEmpty ? displayName : username;

        DateTime timestamp = DateTime.now();
        if (n['grantedAt'] != null) {
          timestamp =
              DateTime.tryParse(n['grantedAt'].toString()) ?? DateTime.now();
        } else if (n['updatedAt'] != null) {
          timestamp =
              DateTime.tryParse(n['updatedAt'].toString()) ?? DateTime.now();
        }

        final apiType =
            n['type'] ?? 'connection';
        final status = n['status'] ?? 'accepted';

        String notificationType;
        String actionText;
        String requestTypeText;
        String title;

        if (apiType == 'connection' && status == 'accepted') {
          notificationType = 'request_accepted';
          actionText = 'accepted your';
          requestTypeText = 'connection request';
          title = 'Connection Accepted';
        } else if (apiType == 'photo' && status == 'granted') {
          notificationType = 'photo_access_granted';
          actionText = 'granted your';
          requestTypeText = 'photo request';
          title = 'Photo Access Granted';
        } else if (apiType == 'details' && status == 'granted') {
          notificationType = 'details_access_granted';
          actionText = 'granted your';
          requestTypeText = 'details request';
          title = 'Details Access Granted';
        } else {
          notificationType = 'request_accepted';
          actionText = 'accepted your';
          requestTypeText = 'request';
          title = 'Request Accepted';
        }

        return NotificationModel(
          id: n['_id'] ?? 'notif_${n['otherUser']?['_id'] ?? username}',
          title: title,
          body: '$finalName $actionText $requestTypeText',
          type: notificationType,
          data: {
            'username': username,
            'name': finalName,
            'firstName': otherUser['first_name'],
            'lastName': otherUser['last_name'],
            'userId': otherUser['_id'],
            'user_id': otherUser['_id'],
            'action': actionText,
            'type_text': requestTypeText,
            'profilePhoto':
                otherUser['profilePhoto'] ?? otherUser['profile_photo'],
            'occupation': otherUser['occupation'],
            'city': otherUser['city'],
            'apiType': apiType,
            'status': status,
          },
          timestamp: timestamp,
          isRead: true,
        );
      }).toList();

      debugPrint(
        '[NOTIFICATIONS] Converted ${backendNotifications.length} backend notifications',
      );

      int addedCount = 0;
      for (var n in backendNotifications) {
        if (!_isDuplicate(n, targetList)) {
          targetList.add(n);
          addedCount++;
        } else {
          debugPrint(
            '[NOTIFICATIONS] Skipped duplicate notification: ${n.id} - ${n.body}',
          );
        }
      }

      debugPrint(
        '[NOTIFICATIONS] Added $addedCount new notifications, total count: ${targetList.length}',
      );
    }
  }

  List<NotificationModel> get filteredNotifications {
    return _notifications.where((n) {
      return n.type == 'request_accepted' ||
          n.type == 'photo_access_granted' ||
          n.type == 'details_access_granted';
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<NotificationModel> get notifications => filteredNotifications;

  Future<void> markAsRead(String id) async {
    await _storageService.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  bool _isDuplicate(
    NotificationModel newNotification,
    List<NotificationModel> existingList,
  ) {
    final newUsername = newNotification.data['username']
        ?.toString()
        .toLowerCase()
        .trim();
    final newUserId =
        newNotification.data['userId'] ?? newNotification.data['user_id'];

    return existingList.any((existing) {
      if (existing.type != newNotification.type) return false;

      final existingUserId =
          existing.data['userId'] ?? existing.data['user_id'];
      if (newUserId != null &&
          existingUserId != null &&
          newUserId == existingUserId) {
        return true;
      }

      final existingUsername = existing.data['username']
          ?.toString()
          .toLowerCase()
          .trim();
      if (newUsername != null &&
          existingUsername != null &&
          newUsername == existingUsername) {
        return true;
      }

      if (newUsername != null &&
          existing.body.toLowerCase().contains(newUsername)) {
        return true;
      }

      return false;
    });
  }

  void handleRealTimeNotification(NotificationModel notification) {
    if (notification.type == 'request_accepted') {
      final username = notification.data['username']
          ?.toString()
          .toLowerCase()
          .trim();
      final userId =
          notification.data['userId'] ?? notification.data['user_id'];

      _notifications.removeWhere((existing) {
        if (existing.type != 'request_accepted') return false;
        if (existing.id.startsWith('conn_')) {
          final existingUsername = existing.data['username']
              ?.toString()
              .toLowerCase()
              .trim();
          final existingUserId =
              existing.data['userId'] ?? existing.data['user_id'];

          return (userId != null && existingUserId == userId) ||
              (username != null && existingUsername == username);
        }
        return false;
      });
    }

    if (!_isDuplicate(notification, _notifications)) {
      _notifications.insert(0, notification);
      notifyListeners();
    }
  }
}