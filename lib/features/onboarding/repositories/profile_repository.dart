import 'package:dio/dio.dart';
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
      final response = await _apiService.dio.post(
        AppConstants.authRegisterDetails,
        data: profileData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data['user']),
          message: response.data['message'],
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
}
