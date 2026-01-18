import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/connections_repository.dart';

class ConnectionsProvider with ChangeNotifier {
  final ConnectionsRepository _repository;

  ConnectionsProvider(this._repository);

  // Incoming requests
  List<Map<String, dynamic>> _incomingRequests = [];
  bool _isLoading = false;

  // Cache for connection statuses per username
  final Map<String, Map<String, String>> _statusCache = {};

  // Loading states per username
  final Map<String, bool> _requestingStates = {};
  final Map<String, bool> _requestingDetailsStates = {};
  final Map<String, bool> _sendingInterestStates = {};
  final Map<String, bool> _cancellingStates = {};

  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  bool get isLoading => _isLoading;

  // =====================================================
  // STATUS GETTERS
  // =====================================================

  /// Get photo access status for a username
  String getStatus(String username) {
    return _statusCache[username]?['photoStatus'] ?? 'none';
  }

  /// Get connection status for a username
  String getConnectionStatus(String username) {
    return _statusCache[username]?['friendStatus'] ?? 'none';
  }

  /// Get details access status for a username
  String getDetailsStatus(String username) {
    return _statusCache[username]?['detailsStatus'] ?? 'none';
  }

  /// Check if currently requesting photo access
  bool isRequesting(String username) {
    return _requestingStates[username] ?? false;
  }

  /// Check if currently requesting details access
  bool isRequestingDetails(String username) {
    return _requestingDetailsStates[username] ?? false;
  }

  /// Check if currently sending interest/connection request
  bool isSendingInterest(String username) {
    return _sendingInterestStates[username] ?? false;
  }

  /// Check if currently cancelling any request
  bool isCancellingRequest(String username) {
    return _cancellingStates[username] ?? false;
  }

  // =====================================================
  // FETCH CONNECTION STATUS
  // =====================================================

  Future<void> fetchStatus(String username) async {
    try {
      final response = await _repository.getConnectionStatus(username);

      if (response.success && response.data != null) {
        _statusCache[username] = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ConnectionProvider] Error fetching status: $e');
    }
  }

  // =====================================================
  // CONNECTION REQUESTS
  // =====================================================

  Future<void> sendInterest(String username) async {
    _sendingInterestStates[username] = true;
    notifyListeners();

    final response = await _repository.sendConnectionRequest(username);

    if (response.success) {
      Fluttertoast.showToast(msg: 'Interest sent successfully');
      // Update local cache
      _statusCache[username] = {
        ...?_statusCache[username],
        'friendStatus': 'pending',
      };
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to send interest',
      );
    }

    _sendingInterestStates[username] = false;
    notifyListeners();
  }

  Future<void> cancelConnectionRequest(String username) async {
    _cancellingStates[username] = true;
    notifyListeners();

    final response = await _repository.cancelRequest(
      targetUsername: username,
      type: 'connection',
    );

    if (response.success) {
      Fluttertoast.showToast(msg: 'Connection request cancelled');
      _statusCache[username] = {
        ...?_statusCache[username],
        'friendStatus': 'none',
      };
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to cancel request',
      );
    }

    _cancellingStates[username] = false;
    notifyListeners();
  }

  // =====================================================
  // PHOTO ACCESS REQUESTS
  // =====================================================

  Future<void> requestAccess(String username) async {
    _requestingStates[username] = true;
    notifyListeners();

    final response = await _repository.requestPhotoAccess(username);

    if (response.success) {
      Fluttertoast.showToast(msg: 'Photo access requested');
      _statusCache[username] = {
        ...?_statusCache[username],
        'photoStatus': response.data ?? 'pending',
      };
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to request access',
      );
    }

    _requestingStates[username] = false;
    notifyListeners();
  }

  Future<void> cancelPhotoAccessRequest(String username) async {
    _cancellingStates[username] = true;
    notifyListeners();

    final response = await _repository.cancelRequest(
      targetUsername: username,
      type: 'photo',
    );

    if (response.success) {
      Fluttertoast.showToast(msg: 'Photo access request cancelled');
      _statusCache[username] = {
        ...?_statusCache[username],
        'photoStatus': 'none',
      };
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to cancel request',
      );
    }

    _cancellingStates[username] = false;
    notifyListeners();
  }

  // =====================================================
  // DETAILS ACCESS REQUESTS
  // =====================================================

  Future<void> requestDetailsAccess(String username) async {
    _requestingDetailsStates[username] = true;
    notifyListeners();

    final response = await _repository.requestDetailsAccess(username);

    if (response.success) {
      Fluttertoast.showToast(msg: 'Details access requested');
      _statusCache[username] = {
        ...?_statusCache[username],
        'detailsStatus': 'pending',
      };
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to request details access',
      );
    }

    _requestingDetailsStates[username] = false;
    notifyListeners();
  }

  Future<void> cancelDetailsAccessRequest(String username) async {
    _cancellingStates[username] = true;
    notifyListeners();

    final response = await _repository.cancelRequest(
      targetUsername: username,
      type: 'details',
    );

    if (response.success) {
      Fluttertoast.showToast(msg: 'Details access request cancelled');
      _statusCache[username] = {
        ...?_statusCache[username],
        'detailsStatus': 'none',
      };
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to cancel request',
      );
    }

    _cancellingStates[username] = false;
    notifyListeners();
  }

  // =====================================================
  // INCOMING REQUESTS MANAGEMENT
  // =====================================================

  Future<void> loadIncomingRequests() async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.getIncomingRequests();

    if (response.success && response.data != null) {
      _incomingRequests = List<Map<String, dynamic>>.from(response.data!);
    } else {
      _incomingRequests = [];
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to load requests',
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> accept(String requestId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.acceptConnection(requestId);

    if (response.success) {
      Fluttertoast.showToast(msg: 'Connection accepted');
      _incomingRequests.removeWhere((r) => r['_id'] == requestId);
    } else {
      Fluttertoast.showToast(msg: response.message ?? 'Failed to accept');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reject(String requestId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.rejectConnection(requestId);

    if (response.success) {
      Fluttertoast.showToast(msg: 'Connection rejected');
      _incomingRequests.removeWhere((r) => r['_id'] == requestId);
    } else {
      Fluttertoast.showToast(msg: response.message ?? 'Failed to reject');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> respondPhotoRequest(String requestId, String action) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.respondPhotoRequest(
      requestId: requestId,
      action: action,
    );

    if (response.success) {
      final actionText = action == 'grant' ? 'granted' : 'denied';
      Fluttertoast.showToast(msg: 'Photo access $actionText');
      _incomingRequests.removeWhere((r) => r['_id'] == requestId);
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to respond to photo request',
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> respondDetailsRequest(String requestId, String action) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.respondDetailsRequest(
      requestId: requestId,
      action: action,
    );

    if (response.success) {
      final actionText = action == 'grant' ? 'granted' : 'denied';
      Fluttertoast.showToast(msg: 'Details access $actionText');
      _incomingRequests.removeWhere((r) => r['_id'] == requestId);
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to respond to details request',
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
