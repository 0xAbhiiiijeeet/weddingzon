import 'package:dio/dio.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/api_service.dart';
import '../models/feed_response.dart';

class FeedRepository {
  final ApiService _apiService;

  FeedRepository(this._apiService);

  Future<ApiResponse<FeedResponse>> getFeed({String? cursor}) async {
    try {
      final queryParams = cursor != null
          ? {'cursor': cursor}
          : <String, dynamic>{};

      final response = await _apiService.dio.get(
        '/users/feed',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ApiResponse(
          success: true,
          data: FeedResponse.fromJson(response.data),
        );
      }
      return ApiResponse(success: false, message: 'Failed to load feed');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    }
  }
}
