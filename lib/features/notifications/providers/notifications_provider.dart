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

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  /// Load from local storage + fetch backend history (my-connections pseudo-history)
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load Local
    final local = await _storageService.getNotifications();
    _notifications = List.from(local);

    // 2. Load "Accepted Connections" as pseudo-notifications if needed
    // This makes sure historical connection acceptances are visible
    await _loadAcceptedConnections();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAcceptedConnections() async {
    final response = await _connectionsRepository.getMyConnections();
    if (response.success && response.data != null) {
      final connections = response.data as List<dynamic>;

      // Convert connections to pseudo-notifications
      // We don't have timestamps, so we just add them if not present by some ID logic
      // But simple way: just map them and show them.
      // The issue is duplication if we save them locally too.
      // Strategy: Only show "Accepted" from backend if we don't have a local record?
      // Or just mix them in?
      // User simplified requirement: Show them.

      final connectionNotifications = connections.map((c) {
        final username = c['username'] ?? 'User';
        return NotificationModel(
          id: 'conn_${c['_id'] ?? username}', // Pseudo ID
          title: 'Connection Accepted',
          body: '$username accepted your connection request',
          type: 'request_accepted',
          data: {'username': username},
          timestamp: DateTime.now(), // Unknown time
          isRead: true,
        );
      }).toList();

      for (var n in connectionNotifications) {
        // Avoid duplicates if possible (rudimentary check)
        if (!_notifications.any((existing) => existing.body == n.body)) {
          _notifications.add(n);
        }
      }

      // Sort by time (though backend ones have fake time 'now', so they appear top/bottom)
      // Ideally we'd put them at bottom if they are old.
    }
  }

  Future<void> markAsRead(String id) async {
    await _storageService.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }
}
