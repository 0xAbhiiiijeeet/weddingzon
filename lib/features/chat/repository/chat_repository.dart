import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/api_service.dart';

class ChatRepository {
  final ApiService _apiService;

  ChatRepository(this._apiService);

  // =====================================================
  // GET CONVERSATIONS
  // GET /chat/conversations
  // =====================================================
  Future<ApiResponse<List<Conversation>>> getConversations() async {
    try {
      final response = await _apiService.dio.get(
        AppConstants.chatConversations,
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final conversations = data
            .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: conversations);
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  // =====================================================
  // GET CHAT HISTORY
  // GET /chat/history/:userId
  // =====================================================
  Future<ApiResponse<List<Message>>> getChatHistory(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '${AppConstants.chatHistory}/$userId',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(extra: {'withCredentials': true}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final messages = data
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: messages);
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  // =====================================================
  // UPLOAD CHAT IMAGE
  // POST /chat/upload
  // =====================================================
  Future<ApiResponse<String>> uploadChatImage(File file) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      });

      final response = await _apiService.dio.post(
        AppConstants.chatUpload,
        data: formData,
        options: Options(
          extra: {'withCredentials': true},
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200) {
        final url = response.data['url']?.toString();
        if (url != null) {
          return ApiResponse(success: true, data: url);
        }
        return ApiResponse(success: false, message: 'No URL in response');
      }

      return _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  // =====================================================
  // MARK AS READ
  // POST /chat/read
  // =====================================================
  Future<ApiResponse<void>> markAsRead(String senderId) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.chatMarkRead,
        data: {'senderId': senderId},
        options: Options(extra: {'withCredentials': true}),
      );

      return response.statusCode == 200
          ? ApiResponse(success: true)
          : _error(response);
    } on DioException catch (e) {
      return _dioError(e);
    }
  }

  // =====================================================
  // ERROR HANDLING
  // =====================================================
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
