import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../repositories/connections_repository.dart';

class ConnectionsProvider with ChangeNotifier {
  final ConnectionsRepository _repository;

  ConnectionsProvider(this._repository);

  List<Map<String, dynamic>> _incomingRequests = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  bool get isLoading => _isLoading;

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
