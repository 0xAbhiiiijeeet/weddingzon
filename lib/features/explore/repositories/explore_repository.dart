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

  // Search users (MISSING API - backend needs to implement)
  Future<ApiResponse<List<dynamic>>> searchUsers({
    required String query,
    int page = 1,
  }) async {
    try {
      debugPrint('[EXPLORE_REPO] ========== SEARCH USERS ==========');
      debugPrint('[EXPLORE_REPO] Query: $query');
      debugPrint('[EXPLORE_REPO] Page: $page');

      // THIS API DOESN'T EXIST YET - Backend needs to add:
      // GET /api/users/search?query=john&page=1&limit=20

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
      debugPrint('[EXPLORE_REPO] Search error');

      // If 404, API doesn't exist yet
      if (e.response?.statusCode == 404) {
        debugPrint(
          '[EXPLORE_REPO] Search API not found - backend needs to implement',
        );
        return ApiResponse(
          success: false,
          message: 'Search feature not yet available',
          data: [], // Return empty list instead of failing
        );
      }

      return _handleDioException(e);
    }
  }

  // Get feed with filters (MISSING API - backend needs enhanced endpoint)
  Future<ApiResponse<List<dynamic>>> getFeedWithFilters({
    required Map<String, dynamic> filters,
    int page = 1,
  }) async {
    try {
      debugPrint('[EXPLORE_REPO] ========== GET FILTERED FEED ==========');
      debugPrint('[EXPLORE_REPO] Filters: $filters');
      debugPrint('[EXPLORE_REPO] Page: $page');

      // Backend needs to enhance /api/users/feed to accept filters:
      // GET /api/users/feed?minAge=25&maxAge=35&minHeight=5.5&religion=Hindu&page=1

      final queryParams = {'page': page, 'limit': 20, ...filters};

      final response = await _apiService.dio.get(
        AppConstants.usersFeed,
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
      debugPrint('[EXPLORE_REPO] Filtered feed error');

      // If backend doesn't support filters yet, just return regular feed
      if (e.response?.statusCode == 400) {
        debugPrint(
          '[EXPLORE_REPO] Backend doesn\'t support filters yet, falling back to regular feed',
        );
        return getFeed();
      }

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
