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

  /// Load from local storage + fetch backend history (my-connections pseudo-history)
  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    // Only show loading indicator if we don't have data or explicitly forcing
    if (_notifications.isEmpty || forceRefresh) {
      _isLoading = true;
      notifyListeners();
    }

    // 1. Load Local
    final local = await _storageService.getNotifications();
    // Create a temporary list to avoid clearing state affecting UI immediately
    List<NotificationModel> tempList = List.from(local);

    // 2. Load "Accepted Connections" as pseudo-notifications if needed
    await _loadAcceptedConnections(tempList);

    _notifications = tempList;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAcceptedConnections(
    List<NotificationModel> targetList,
  ) async {
    final response = await _connectionsRepository.getMyConnections();
    if (response.success && response.data != null) {
      final connections = response.data as List<dynamic>;

      // Convert connections to pseudo-notifications
      final connectionNotifications = connections.map((c) {
        final username = c['username'] ?? 'User';
        return NotificationModel(
          id: 'conn_${c['_id'] ?? username}', // Pseudo ID
          title: 'Connection Accepted',
          body: '$username accepted your connection request',
          type: 'request_accepted',
          data: {'username': username},
          timestamp: DateTime.now(), // Unknown time, keeping as now
          isRead: true,
        );
      }).toList();

      for (var n in connectionNotifications) {
        // Avoid duplicates checking against the target list
        if (!targetList.any((existing) => existing.body == n.body)) {
          targetList.add(n);
        }
      }
    }
  }

  /// Internal filter to ensure we only show desired notification types
  List<NotificationModel> get filteredNotifications {
    return _notifications.where((n) {
      // User requested ONLY connection accept notifications
      // Types: 'request_accepted' (connection), 'photo_access_granted', 'details_access_granted'
      return n.type == 'request_accepted';
    }).toList();
  }

  // Expose filtered list by default
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

  void handleRealTimeNotification(NotificationModel notification) {
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.insert(0, notification);
      notifyListeners();
    }
  }
}
