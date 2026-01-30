import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';

class ProfileRepository {
  final ApiService _apiService;

  ProfileRepository(this._apiService);

  Future<ApiResponse<User>> registerDetails(
    Map<String, dynamic> profileData,
  ) async {
    try {
      debugPrint('[PROFILE_REPO] Registering details: $profileData');
      final response = await _apiService.dio.post(
        AppConstants.authRegisterDetails,
        data: profileData,
      );

      debugPrint('[PROFILE_REPO] Response status: ${response.statusCode}');
      debugPrint('[PROFILE_REPO] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['user'] != null) {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data['user']),
          message: response.data['message'] ?? 'Profile updated',
        );
      }
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message,
      );
    }
  }

  Future<ApiResponse<void>> updateLocation(double lat, double lng) async {
    try {
      final response = await _apiService.dio.patch(
        '${AppConstants.users}/location',
        data: {'latitude': lat, 'longitude': lng},
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update location',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
      );
    }
  }
}