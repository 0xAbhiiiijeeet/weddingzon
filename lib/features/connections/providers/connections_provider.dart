import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/connections_repository.dart';

class ConnectionsProvider with ChangeNotifier {
  final ConnectionsRepository _repository;

  ConnectionsProvider(this._repository);

  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _myConnections = [];
  bool _isLoading = false;
  bool _isLoadingConnections = false;

  final Map<String, Map<String, String>> _statusCache = {};

  final Map<String, bool> _requestingStates = {};
  final Map<String, bool> _requestingDetailsStates = {};
  final Map<String, bool> _sendingInterestStates = {};
  final Map<String, bool> _cancellingStates = {};

  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get myConnections => _myConnections;
  bool get isLoading => _isLoading;
  bool get isLoadingConnections => _isLoadingConnections;


  String getStatus(String username) {
    return _statusCache[username]?['photoStatus'] ?? 'none';
  }

  String getConnectionStatus(String username) {
    return _statusCache[username]?['friendStatus'] ?? 'none';
  }

  String getDetailsStatus(String username) {
    return _statusCache[username]?['detailsStatus'] ?? 'none';
  }

  bool isRequesting(String username) {
    return _requestingStates[username] ?? false;
  }

  bool isRequestingDetails(String username) {
    return _requestingDetailsStates[username] ?? false;
  }

  bool isSendingInterest(String username) {
    return _sendingInterestStates[username] ?? false;
  }

  bool isCancellingRequest(String username) {
    return _cancellingStates[username] ?? false;
  }


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


  Future<void> sendInterest(String username) async {
    _sendingInterestStates[username] = true;
    notifyListeners();

    final response = await _repository.sendConnectionRequest(username);

    if (response.success) {
      Fluttertoast.showToast(msg: 'Interest sent successfully');
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
    _isLoading = false;
    notifyListeners();
  }

  void handleRealTimeRequest(Map<String, dynamic> data) {
    if (_incomingRequests.any((r) => r['_id'] == data['requestId'])) {
      return;
    }

    loadIncomingRequests();
  }


  Future<void> loadMyConnections() async {
    _isLoadingConnections = true;
    notifyListeners();

    final response = await _repository.getMyConnections();

    if (response.success && response.data != null) {
      final rawList = List<Map<String, dynamic>>.from(response.data!);
      final seenIds = <String>{};
      _myConnections = rawList
          .where((u) => seenIds.add(u['_id'] ?? u['username']))
          .toList();
    } else {
      _myConnections = [];
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to load connections',
      );
    }

    _isLoadingConnections = false;
    notifyListeners();
  }
}