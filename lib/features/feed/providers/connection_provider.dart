import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../connections/repositories/connections_repository.dart';

class ConnectionProvider extends ChangeNotifier {
  final ConnectionsRepository _repository;

  ConnectionProvider(this._repository);

  // Track connection status: username -> status
  final Map<String, String> _connectionStatuses = {}; // none, pending, accepted

  // Loading states
  final Set<String> _sendingInterest = {};
  final Set<String> _cancellingRequest = {};

  // Connection/Interest Status (none, pending, accepted)
  String getConnectionStatus(String username) {
    return _connectionStatuses[username] ?? 'none';
  }

  bool isSendingInterest(String username) {
    return _sendingInterest.contains(username);
  }

  bool isCancellingRequest(String username) {
    return _cancellingRequest.contains(username);
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

  // Fetch full connection status from server
  Future<void> fetchStatus(String username) async {
    debugPrint('[CONNECTION] Fetching status for: $username');

    final response = await _repository.getConnectionStatus(username);

    if (response.success && response.data != null) {
      final data = response.data!;
      _connectionStatuses[username] = data['friendStatus'] ?? 'none';

      debugPrint(
        '[CONNECTION] Status for $username: friend=${data['friendStatus']}',
      );
      notifyListeners();
    }
  }

  // Update statuses from Feed items
  void updateStatusesFromFeed(List<dynamic> users) {
    bool changed = false;
    for (final user in users) {
      if (user.username.isNotEmpty) {
        if (user.connectionStatus != null) {
          _connectionStatuses[user.username] = user.connectionStatus!;
          changed = true;
        }
      }
    }

    if (changed) {
      debugPrint('[CONNECTION] Updated statuses from feed data');
      notifyListeners();
    }
  }

  void reset() {
    _connectionStatuses.clear();
    _sendingInterest.clear();
    _cancellingRequest.clear();
    notifyListeners();
  }
}
