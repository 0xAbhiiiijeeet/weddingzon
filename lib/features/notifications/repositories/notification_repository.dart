import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository(this._apiService);

  Future<bool> registerToken(String token) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.notificationsRegister,
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
        AppConstants.notificationsUnregister,
        data: {'token': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NOTIFICATION REPO] Unregister Token Error: $e');
      return false;
    }
  }
}