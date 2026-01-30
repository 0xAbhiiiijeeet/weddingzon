import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/api_service.dart';

class ConnectionsRepository {
  final ApiService _apiService;

  ConnectionsRepository(this._apiService);

  Future<ApiResponse<Map<String, dynamic>>> sendConnectionRequest(
    String targetUsername,
  ) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsSend,
        data: {'targetUsername': targetUsername},
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, data: response.data['data']);
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<void>> acceptConnection(String requestId) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsAccept,
        data: {'requestId': requestId},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<void>> rejectConnection(String requestId) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsReject,
        data: {'requestId': requestId},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<void>> cancelRequest({
    required String targetUsername,
    required String type,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsCancel,
        data: {'targetUsername': targetUsername, 'type': type},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<String>> requestPhotoAccess(String targetUsername) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsRequestPhotoAccess,
        data: {'targetUsername': targetUsername},
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        final status =
            response.data['data']?['status'] ??
            response.data['status'] ??
            'pending';
        return ApiResponse(
          success: true,
          data: status,
          message: response.data['message'],
        );
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<void>> requestDetailsAccess(String targetUsername) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsRequestDetailsAccess,
        data: {'targetUsername': targetUsername},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<void>> respondPhotoRequest({
    required String requestId,
    required String action,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsRespondPhoto,
        data: {'requestId': requestId, 'action': action},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<void>> respondDetailsRequest({
    required String requestId,
    required String action,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.connectionsRespondDetails,
        data: {'requestId': requestId, 'action': action},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getIncomingRequests() async {
    try {
      final response = await _apiService.dio.get(
        AppConstants.connectionsRequests,
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: response.data['data'] ?? []);
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getMyConnections() async {
    try {
      final response = await _apiService.dio.get(
        AppConstants.connectionsMyConnections,
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: response.data['data'] ?? []);
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getNotifications() async {
    try {
      final response = await _apiService.dio.get(
        AppConstants.connectionsNotifications,
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: response.data['data'] ?? []);
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  Future<ApiResponse<Map<String, String>>> getConnectionStatus(
    String username,
  ) async {
    try {
      final response = await _apiService.dio.get(
        '${AppConstants.connectionsStatus}/$username',
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: {
            'photoStatus': response.data['status']?.toString() ?? 'none',
            'friendStatus': response.data['friendStatus']?.toString() ?? 'none',
            'detailsStatus':
                response.data['detailsStatus']?.toString() ?? 'none',
          },
        );
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  ApiResponse<T> _error<T>(Response response) {
    return ApiResponse(
      success: false,
      message: response.data?['message'] ?? 'Request failed',
    );
  }

  ApiResponse<T> _dioError<T>(DioException e) {
    return ApiResponse(
      success: false,
      message: e.response?.data?['message'] ?? e.message ?? 'Network error',
    );
  }
}