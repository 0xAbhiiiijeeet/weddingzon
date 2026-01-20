import 'package:flutter/foundation.dart';

import '../../../core/services/api_service.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository(this._apiService);

  Future<bool> registerToken(String token) async {
    try {
      final response = await _apiService.dio.post(
        '/notifications/register-token',
        data: {'token': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NOTIFICATION REPO] Register Token Error: $e');
      return false;
    }
  }

  Future<bool> unregisterToken(String token) async {
    try {
      final response = await _apiService.dio.post(
        '/notifications/unregister-token',
        data: {'token': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NOTIFICATION REPO] Unregister Token Error: $e');
      return false;
    }
  }
}
