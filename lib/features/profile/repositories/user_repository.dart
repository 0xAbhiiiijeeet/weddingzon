import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/photo_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  /// Upload photos with proper MIME type
  /// POST /users/upload-photos (multipart/form-data)
  Future<ApiResponse<List<Photo>>> uploadPhotos(
    List<File> photos, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData();

      for (var file in photos) {
        final fileName = file.path.split(Platform.pathSeparator).last;

        // Detect MIME type
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        final mimeTypeParts = mimeType.split('/');

        debugPrint('[UPLOAD] Adding file: $fileName, MIME: $mimeType');

        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
              contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
            ),
          ),
        );
      }

      final response = await _apiService.dio.post(
        '/users/upload-photos',
        data: formData,
        onSendProgress: onProgress,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List<dynamic>?;
        final uploadedPhotos =
            data
                ?.map((p) => Photo.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];

        return ApiResponse(
          success: true,
          data: uploadedPhotos,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Upload failed',
      );
    } on DioException catch (e) {
      debugPrint('[UPLOAD ERROR] ${e.message}');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }

  /// Delete a photo
  /// DELETE /users/photos/:photoId
  Future<ApiResponse<void>> deletePhoto(String photoId) async {
    try {
      final response = await _apiService.dio.delete('/users/photos/$photoId');

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: response.data['message']);
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Delete failed',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }

  /// Update photo properties (if backend supports)
  /// This is a placeholder - API contract doesn't show this endpoint
  Future<ApiResponse<Photo>> updatePhoto(
    String photoId, {
    bool? isProfile,
    bool? restricted,
  }) async {
    try {
      final response = await _apiService.dio.patch(
        '/users/photos/$photoId',
        data: {
          if (isProfile != null) 'isProfile': isProfile,
          if (restricted != null) 'restricted': restricted,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return ApiResponse(
          success: true,
          data: Photo.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Update failed',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }

  // Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      debugPrint('[USER_REPO] ========== GET CURRENT USER ==========');

      final response = await _apiService.dio.get(
        AppConstants.authMe,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[USER_REPO] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('[USER_REPO] User data received');
        return ApiResponse(success: true, data: User.fromJson(response.data));
      }

      return ApiResponse(
        success: false,
        message: response.statusMessage ?? 'Failed to get user',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }

  // Update profile details
  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    try {
      debugPrint('[USER_REPO] ========== UPDATE PROFILE ==========');

      final response = await _apiService.dio.post(
        AppConstants
            .authRegisterDetails, // Ensure this constant exists/is correct
        data: data,
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: User.fromJson(response.data['user']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.statusMessage ?? 'Failed to update profile',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }

  /// Get user profile by username
  /// GET /users/:username
  Future<ApiResponse<Map<String, dynamic>>> getUserByUsername(
    String username,
  ) async {
    try {
      debugPrint('[USER_REPO] ========== GET USER BY USERNAME ==========');
      debugPrint('[USER_REPO] Username: $username');

      final response = await _apiService.dio.get(
        '${AppConstants.usersProfile}/$username',
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[USER_REPO] Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('[USER_REPO] User profile data received');
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
        );
      }

      return ApiResponse(
        success: false,
        message: response.statusMessage ?? 'Failed to get user profile',
      );
    } on DioException catch (e) {
      debugPrint('[USER_REPO] Error: ${e.message}');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }
}
