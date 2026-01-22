import 'package:flutter/foundation.dart';
import '../../../core/services/socket_service.dart';
import '../../chat/provider/chat_provider.dart';
import '../../connections/providers/connections_provider.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notifications_provider.dart';

class BadgeProvider extends ChangeNotifier {
  final ChatProvider _chatProvider;
  final ConnectionsProvider _connectionsProvider;
  final NotificationsProvider _notificationsProvider;
  final SocketService _socketService;

  int _chatBadgeCount = 0;
  int _connectionBadgeCount = 0;

  BadgeProvider(
    this._chatProvider,
    this._connectionsProvider,
    this._notificationsProvider,
    this._socketService,
  ) {
    _initListeners();
  }

  int get chatBadgeCount => _chatBadgeCount;
  int get connectionBadgeCount => _connectionBadgeCount;

  void _initListeners() {
    _chatProvider.addListener(_updateChatCount);
    _connectionsProvider.addListener(_updateConnectionCount);
    _notificationsProvider.addListener(_updateConnectionCount);

    // Listen to socket notifications
    // NOTE: This overrides any previous listener. Ensure this is the only one or handle chaining if needed.
    _socketService.onNotificationReceived = _handleSocketNotification;

    // Initial update
    _updateChatCount();
    _updateConnectionCount();
  }

  void _updateChatCount() {
    final count = _chatProvider.totalUnreadCount;
    if (count != _chatBadgeCount) {
      _chatBadgeCount = count;
      debugPrint('[BadgeProvider] Chat count updated: $_chatBadgeCount');
      notifyListeners();
    }
  }

  void _updateConnectionCount() {
    final requestCount = _connectionsProvider.incomingRequests.length;
    final unreadNotes = _notificationsProvider.notifications
        .where((n) => !n.isRead)
        .length;

    final total = requestCount + unreadNotes;

    if (total != _connectionBadgeCount) {
      _connectionBadgeCount = total;
      debugPrint(
        '[BadgeProvider] Connection count updated: $_connectionBadgeCount',
      );
      notifyListeners();
    }
  }

  void _handleSocketNotification(Map<String, dynamic> data) {
    debugPrint('[BadgeProvider] Received socket notification: $data');
    final type = data['type'];

    // Route incoming requests to ConnectionsProvider for Invites tab
    if (type == 'connection_request' ||
        type == 'photo_access_request' ||
        type == 'details_access_request') {
      debugPrint('[BadgeProvider] Routing $type to ConnectionsProvider');
      _connectionsProvider.handleRealTimeRequest(data);
    } else {
      // Route granted/accepted notifications to NotificationsProvider for Notifications tab
      debugPrint('[BadgeProvider] Routing $type to NotificationsProvider');
      final model = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: data['title'] ?? 'New Notification',
        body: data['body'] ?? '',
        type: type ?? 'general',
        data: data,
        timestamp: DateTime.now(),
        isRead: false,
      );
      _notificationsProvider.handleRealTimeNotification(model);
    }
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_updateChatCount);
    _connectionsProvider.removeListener(_updateConnectionCount);
    _notificationsProvider.removeListener(_updateConnectionCount);
    super.dispose();
  }
}
