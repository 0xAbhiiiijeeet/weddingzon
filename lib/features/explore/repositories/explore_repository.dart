import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/api_service.dart';

class ExploreRepository {
  final ApiService _apiService;

  ExploreRepository(this._apiService);

  Future<ApiResponse<List<dynamic>>> getFeed({String? cursor}) async {
    try {
      debugPrint('[EXPLORE_REPO] ========== GET FEED ==========');
      debugPrint('[EXPLORE_REPO] Cursor: $cursor');

      final queryParams = <String, dynamic>{'limit': 20};
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _apiService.dio.get(
        AppConstants.usersFeed,
        queryParameters: queryParams,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[EXPLORE_REPO] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>?;
        debugPrint('[EXPLORE_REPO] Fetched ${data?.length ?? 0} users');
        return ApiResponse(
          success: true,
          data: data ?? [],
          nextCursor: response.data['nextCursor'],
        );
      } else {
        return _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Search users with query
  /// GET /api/users/search?q=query&page=1&limit=20
  Future<ApiResponse<List<dynamic>>> searchUsers({
    required String query,
    int page = 1,
  }) async {
    try {
      debugPrint('[EXPLORE_REPO] ========== SEARCH USERS ==========');
      debugPrint('[EXPLORE_REPO] Query: $query');
      debugPrint('[EXPLORE_REPO] Page: $page');

      final response = await _apiService.dio.get(
        AppConstants.usersSearch,
        queryParameters: {'q': query, 'page': page, 'limit': 20},
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[EXPLORE_REPO] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>?;
        debugPrint('[EXPLORE_REPO] Search returned ${data?.length ?? 0} users');
        return ApiResponse(success: true, data: data ?? []);
      } else {
        return _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      debugPrint('[EXPLORE_REPO] Search error: ${e.message}');
      return _handleDioException(e);
    }
  }

  /// Get feed with filters
  /// GET /api/users/search with filter parameters
  Future<ApiResponse<List<dynamic>>> getFeedWithFilters({
    required Map<String, dynamic> filters,
    int page = 1,
  }) async {
    try {
      debugPrint('[EXPLORE_REPO] ========== GET FILTERED FEED ==========');
      debugPrint('[EXPLORE_REPO] Filters: $filters');
      debugPrint('[EXPLORE_REPO] Page: $page');

      final queryParams = {'page': page, 'limit': 20, ...filters};

      final response = await _apiService.dio.get(
        AppConstants.usersSearch,
        queryParameters: queryParams,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[EXPLORE_REPO] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>?;
        debugPrint(
          '[EXPLORE_REPO] Filtered feed returned ${data?.length ?? 0} users',
        );
        return ApiResponse(success: true, data: data ?? []);
      } else {
        return _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      debugPrint('[EXPLORE_REPO] Filtered feed error: ${e.message}');
      return _handleDioException(e);
    }
  }

  ApiResponse<T> _handleErrorResponse<T>(Response response) {
    if (response.statusCode == 400) {
      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Bad request',
      );
    } else if (response.statusCode == 401) {
      return ApiResponse(success: false, message: 'Unauthorized');
    } else if (response.statusCode == 404) {
      return ApiResponse(success: false, message: 'Not found');
    } else if (response.statusCode == 429) {
      return ApiResponse(success: false, message: 'Too many requests');
    } else if (response.statusCode != null && response.statusCode! >= 500) {
      return ApiResponse(success: false, message: 'Server error');
    } else {
      return ApiResponse(success: false, message: 'Request failed');
    }
  }

  ApiResponse<T> _handleDioException<T>(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return ApiResponse(success: false, message: 'Connection timeout');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return ApiResponse(success: false, message: 'Request timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return ApiResponse(success: false, message: 'Network error');
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return ApiResponse(success: false, message: 'Unauthorized');
      } else if (statusCode == 404) {
        return ApiResponse(success: false, message: 'Not found');
      } else if (statusCode != null && statusCode >= 500) {
        return ApiResponse(success: false, message: 'Server error');
      }
    }

    return ApiResponse(
      success: false,
      message: e.response?.data?['message'] ?? e.message ?? 'Request failed',
    );
  }
}
