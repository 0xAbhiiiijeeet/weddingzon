import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../connections/repositories/connections_repository.dart';

class ConnectionProvider extends ChangeNotifier {
  final ConnectionsRepository _repository;

  ConnectionProvider(this._repository);

  // Track statuses: username -> status
  final Map<String, String> _photoAccessStatuses = {};
  final Map<String, String> _detailsStatuses = {};
  final Map<String, String> _connectionStatuses = {}; // none, pending, accepted

  // Loading states
  final Set<String> _requestingPhotoAccess = {};
  final Set<String> _requestingDetails = {};
  final Set<String> _sendingInterest = {};
  final Set<String> _cancellingRequest = {};

  // Photo Access Status
  String getStatus(String username) {
    return _photoAccessStatuses[username] ?? 'none';
  }

  // Details Access Status
  String getDetailsStatus(String username) {
    return _detailsStatuses[username] ?? 'none';
  }

  // Connection/Interest Status (none, pending, accepted)
  String getConnectionStatus(String username) {
    return _connectionStatuses[username] ?? 'none';
  }

  bool isRequesting(String username) {
    return _requestingPhotoAccess.contains(username);
  }

  bool isRequestingDetails(String username) {
    return _requestingDetails.contains(username);
  }

  bool isSendingInterest(String username) {
    return _sendingInterest.contains(username);
  }

  bool isCancellingRequest(String username) {
    return _cancellingRequest.contains(username);
  }

  // Request Photo Access
  Future<void> requestAccess(String username) async {
    if (_requestingPhotoAccess.contains(username)) return;

    _requestingPhotoAccess.add(username);
    notifyListeners();

    debugPrint('[CONNECTION] Requesting photo access for: $username');

    final response = await _repository.requestPhotoAccess(username);

    _requestingPhotoAccess.remove(username);

    if (response.success) {
      _photoAccessStatuses[username] = 'pending';
      debugPrint('[CONNECTION] Photo status set to: pending');
      Fluttertoast.showToast(
        msg: response.message ?? "Request sent successfully",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Failed to send request",
        backgroundColor: Colors.red,
      );
    }

    notifyListeners();
  }

  // Request Details Access
  Future<void> requestDetailsAccess(String username) async {
    if (_requestingDetails.contains(username)) return;

    _requestingDetails.add(username);
    notifyListeners();

    debugPrint('[CONNECTION] Requesting details access for: $username');

    final response = await _repository.requestDetailsAccess(username);

    _requestingDetails.remove(username);

    if (response.success) {
      _detailsStatuses[username] = 'pending';
      Fluttertoast.showToast(
        msg: "Details access request sent",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Failed to send request",
        backgroundColor: Colors.red,
      );
    }

    notifyListeners();
  }

  // Send Interest/Connection Request
  Future<void> sendInterest(String username) async {
    if (_sendingInterest.contains(username)) return;

    _sendingInterest.add(username);
    notifyListeners();

    debugPrint('[CONNECTION] Sending interest to: $username');

    final response = await _repository.sendConnectionRequest(username);

    _sendingInterest.remove(username);

    if (response.success) {
      _connectionStatuses[username] = 'pending';
      Fluttertoast.showToast(
        msg: "Interest sent successfully",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Failed to send interest",
        backgroundColor: Colors.red,
      );
    }

    notifyListeners();
  }

  // Cancel Connection Request
  Future<void> cancelConnectionRequest(String username) async {
    if (_cancellingRequest.contains(username)) return;

    _cancellingRequest.add(username);
    notifyListeners();

    debugPrint('[CONNECTION] Cancelling request for: $username');

    final response = await _repository.cancelRequest(
      targetUsername: username,
      type: 'connection',
    );

    _cancellingRequest.remove(username);

    if (response.success) {
      _connectionStatuses[username] = 'none';
      Fluttertoast.showToast(
        msg: "Request cancelled",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Failed to cancel request",
        backgroundColor: Colors.red,
      );
    }

    notifyListeners();
  }

  // Cancel Photo Access Request
  Future<void> cancelPhotoAccessRequest(String username) async {
    if (_cancellingRequest.contains(username)) return;

    _cancellingRequest.add(username);
    notifyListeners();

    debugPrint('[CONNECTION] Cancelling photo access request for: $username');

    final response = await _repository.cancelRequest(
      targetUsername: username,
      type: 'photo',
    );

    _cancellingRequest.remove(username);

    if (response.success) {
      _photoAccessStatuses[username] = 'none';
      debugPrint('[CONNECTION] Photo status set to: none (cancelled)');
      Fluttertoast.showToast(
        msg: "Photo access request cancelled",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Failed to cancel request",
        backgroundColor: Colors.red,
      );
    }

    notifyListeners();
  }

  // Cancel Details Access Request
  Future<void> cancelDetailsAccessRequest(String username) async {
    if (_cancellingRequest.contains(username)) return;

    _cancellingRequest.add(username);
    notifyListeners();

    debugPrint('[CONNECTION] Cancelling details access request for: $username');

    final response = await _repository.cancelRequest(
      targetUsername: username,
      type: 'details',
    );

    _cancellingRequest.remove(username);

    if (response.success) {
      _detailsStatuses[username] = 'none';
      debugPrint('[CONNECTION] Details status set to: none (cancelled)');
      Fluttertoast.showToast(
        msg: "Details access request cancelled",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? "Failed to cancel request",
        backgroundColor: Colors.red,
      );
    }

    notifyListeners();
  }

  // Fetch full connection status from server
  Future<void> fetchStatus(String username) async {
    debugPrint('[CONNECTION] Fetching status for: $username');

    final response = await _repository.getConnectionStatus(username);

    if (response.success && response.data != null) {
      // Parse all statuses from response
      final data = response.data!;
      _photoAccessStatuses[username] = data['photoStatus'] ?? 'none';
      _connectionStatuses[username] = data['friendStatus'] ?? 'none';
      _detailsStatuses[username] = data['detailsStatus'] ?? 'none';

      debugPrint(
        '[CONNECTION] Status for $username: photo=${data['photoStatus']}, friend=${data['friendStatus']}, details=${data['detailsStatus']}',
      );
      notifyListeners();
    }
  }

  void reset() {
    _photoAccessStatuses.clear();
    _detailsStatuses.clear();
    _connectionStatuses.clear();
    _requestingPhotoAccess.clear();
    _requestingDetails.clear();
    _sendingInterest.clear();
    _cancellingRequest.clear();
    notifyListeners();
  }
}
