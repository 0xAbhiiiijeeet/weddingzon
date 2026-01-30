import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import 'package:http_parser/http_parser.dart';

class FranchiseRepository {
  final ApiService _apiService;

  FranchiseRepository(this._apiService);

  Future<ApiResponse<bool>> submitPayment() async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 submitPayment - Starting payment submission',
      );

      final response = await _apiService.dio.post(
        AppConstants.franchisePayment,
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 submitPayment - Response received: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 submitPayment - Response data: ${response.data}',
      );

      if (response.data is! Map) {
        return ApiResponse(success: false, message: 'Invalid server response');
      }

      if (response.statusCode == 200) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          debugPrint(
            '[FRANCHISE_REPO] ✅ submitPayment - Payment submitted successfully',
          );
          return ApiResponse(success: true, data: true);
        }
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ submitPayment - Payment submission failed: ${response.data['message']}',
      );
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Payment submission failed',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FRANCHISE_REPO] ❌ submitPayment - DioException: ${e.message}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 submitPayment - Error response: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 submitPayment - Status code: ${e.response?.statusCode}',
      );
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ submitPayment - Unexpected error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<List<User>>> getProfiles() async {
    try {
      debugPrint('[FRANCHISE_REPO] 🔵 getProfiles - Fetching all profiles');

      final response = await _apiService.dio.get(
        AppConstants.franchiseProfiles,
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 getProfiles - Response received: ${response.statusCode}',
      );

      if (response.data is! Map) {
        debugPrint(
          '[FRANCHISE_REPO] ❌ getProfiles - Invalid response type: ${response.data.runtimeType}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 📄 getProfiles - Response content: ${response.data}',
        );

        if (response.statusCode == 404) {
          return ApiResponse(
            success: false,
            message:
                'Franchise profiles endpoint not found. Please contact support.',
          );
        }

        return ApiResponse(
          success: false,
          message: 'Invalid server response format',
        );
      }

      debugPrint(
        '[FRANCHISE_REPO] 📦 getProfiles - Response data keys: ${response.data.keys}',
      );

      if (response.statusCode == 200) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          final List<dynamic> list = response.data['profiles'];
          debugPrint(
            '[FRANCHISE_REPO] 📊 getProfiles - Found ${list.length} profiles',
          );

          final profiles = list.map((e) => User.fromJson(e)).toList();
          debugPrint(
            '[FRANCHISE_REPO] ✅ getProfiles - Successfully parsed ${profiles.length} profiles',
          );

          return ApiResponse(success: true, data: profiles);
        }
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ getProfiles - Failed to fetch profiles: ${response.data['message']}',
      );
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch profiles',
      );
    } on DioException catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ getProfiles - DioException: ${e.message}');
      debugPrint(
        '[FRANCHISE_REPO] 📛 getProfiles - Error response: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 getProfiles - Status code: ${e.response?.statusCode}',
      );

      if (e.response?.statusCode == 404) {
        return ApiResponse(
          success: false,
          message:
              'Franchise profiles endpoint not found on server. Please contact your administrator.',
        );
      }

      if (e.response?.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Unauthorized. Please login again.',
        );
      }

      if (e.response?.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Access denied. You may not have franchise permissions.',
        );
      }

      final errorData = e.response?.data;
      return ApiResponse(
        success: false,
        message: errorData is Map
            ? errorData['message'] ?? e.message ?? 'Network Error'
            : e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ getProfiles - Unexpected error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('[FRANCHISE_REPO] 🔵 createProfile - Creating new profile');

      const requiredKeys = [
        'first_name',
        'last_name',
        'gender',
        'dob',
        'phone',
        'about_me',
        'height',
        'marital_status',
        'mother_tongue',
        'created_for',
      ];

      for (final key in requiredKeys) {
        if (!data.containsKey(key) ||
            data[key] == null ||
            (data[key] is String && data[key].isEmpty)) {
          return ApiResponse(
            success: false,
            message: 'Missing required field: $key',
          );
        }
      }

      // Normalize gender
      if (data['gender'] != null) {
        final g = data['gender'].toString().toLowerCase();
        data['gender'] = g == 'male' ? 'Male' : 'Female';
      }

      // Format DOB
      if (data['dob'] != null) {
        String dobStr = data['dob'].toString();
        if (dobStr.contains('T')) {
          dobStr = dobStr.split('T').first;
        } else if (dobStr.contains(' ')) {
          dobStr = dobStr.split(' ').first;
        }
        data['dob'] = dobStr;
      }

      // Prepare complete data payload with all basic details fields
      final payload = {
        // Required fields
        'first_name': data['first_name'],
        'last_name': data['last_name'],
        'gender': data['gender'],
        'dob': data['dob'],
        'phone': data['phone'],
        'about_me': data['about_me'],
        'height': data['height'],
        'marital_status': data['marital_status'],
        'mother_tongue': data['mother_tongue'],
        'created_for': data['created_for'],

        // Optional fields (only include if present)
        if (data['email'] != null && data['email'].toString().isNotEmpty)
          'email': data['email'],
        if (data['disability'] != null &&
            data['disability'].toString().isNotEmpty)
          'disability': data['disability'],
        if (data['disability_description'] != null &&
            data['disability_description'].toString().isNotEmpty)
          'disability_description': data['disability_description'],
        if (data['aadhar_number'] != null &&
            data['aadhar_number'].toString().isNotEmpty)
          'aadhar_number': data['aadhar_number'],
        if (data['blood_group'] != null &&
            data['blood_group'].toString().isNotEmpty)
          'blood_group': data['blood_group'],
      };

      debugPrint(
        '[FRANCHISE_REPO] 📤 createProfile - Payload keys: ${payload.keys}',
      );
      debugPrint('[FRANCHISE_REPO] 📦 createProfile - Full payload: $payload');
      debugPrint(
        '[FRANCHISE_REPO] 🌐 createProfile - Endpoint: ${AppConstants.franchiseCreateProfile}',
      );

      final response = await _apiService.dio.post(
        AppConstants.franchiseCreateProfile,
        data: payload,
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 createProfile - Response received: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 createProfile - Response type: ${response.data.runtimeType}',
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        debugPrint(
          '[FRANCHISE_REPO] ❌ createProfile - Unexpected status code: ${response.statusCode}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 📛 createProfile - Response body: ${response.data}',
        );
        return ApiResponse(
          success: false,
          message: 'Server returned status ${response.statusCode}',
        );
      }

      if (response.data is! Map) {
        debugPrint(
          '[FRANCHISE_REPO] ❌ createProfile - Invalid response type: ${response.data.runtimeType}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 📛 createProfile - Response body: ${response.data}',
        );
        return ApiResponse(
          success: false,
          message: 'Invalid server response format',
        );
      }

      if (response.data['success'] == true) {
        debugPrint(
          '[FRANCHISE_REPO] ✅ createProfile - Profile created successfully',
        );
        debugPrint(
          '[FRANCHISE_REPO] 🔑 createProfile - User ID: ${response.data['profile']?['_id']}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 🔐 createProfile - Has credentials: ${response.data['credentials'] != null}',
        );

        return ApiResponse(success: true, data: response.data);
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ createProfile - Failed to create profile: ${response.data['message']}',
      );
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to create profile',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FRANCHISE_REPO] ❌ createProfile - DioException: ${e.message}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 createProfile - Status code: ${e.response?.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 createProfile - Response data: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 createProfile - Response type: ${e.response?.data.runtimeType}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 createProfile - Request URL: ${e.requestOptions.uri}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 createProfile - Request data: ${e.requestOptions.data}',
      );

      if (e.response?.statusCode == 404) {
        return ApiResponse(
          success: false,
          message:
              'API endpoint not found. Please check the server configuration.',
        );
      }

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        return ApiResponse(
          success: false,
          message: errorData is Map
              ? errorData['message'] ?? 'Invalid request data'
              : 'Invalid request data',
        );
      }

      if (e.response?.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Unauthorized. Please login again.',
        );
      }

      if (e.response?.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Access denied. You may not have franchise permissions.',
        );
      }

      if (e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        return ApiResponse(
          success: false,
          message: errorData is Map
              ? errorData['message'] ?? 'Phone or email already exists'
              : 'Phone or email already exists',
        );
      }

      final errorData = e.response?.data;
      return ApiResponse(
        success: false,
        message: errorData is Map
            ? errorData['message'] ?? e.message ?? 'Network Error'
            : e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ createProfile - Unexpected error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<User>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('[FRANCHISE_REPO] ========================================');
      debugPrint('[FRANCHISE_REPO] 🔵 updateProfile - Starting update');
      debugPrint('[FRANCHISE_REPO] 👤 User ID: $userId');
      debugPrint(
        '[FRANCHISE_REPO] 🌐 Endpoint: ${AppConstants.franchiseProfiles}/$userId',
      );
      debugPrint('[FRANCHISE_REPO] 📤 updateProfile - Data keys: ${data.keys}');
      debugPrint('[FRANCHISE_REPO] 📦 Full request body:');
      data.forEach((key, value) {
        debugPrint('[FRANCHISE_REPO]   - $key: $value (${value.runtimeType})');
      });
      debugPrint('[FRANCHISE_REPO] ========================================');

      final response = await _apiService.dio.patch(
        '${AppConstants.franchiseProfiles}/$userId',
        data: data,
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 updateProfile - Response received: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 updateProfile - Response data type: ${response.data.runtimeType}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 updateProfile - Response data: ${response.data}',
      );

      if (response.data is! Map) {
        return ApiResponse(success: false, message: 'Invalid server response');
      }

      if (response.statusCode == 200) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          debugPrint('[FRANCHISE_REPO] ✅ updateProfile - Update successful');

          final userData = response.data['profile'] ?? response.data['user'];
          if (userData == null) {
            debugPrint(
              '[FRANCHISE_REPO] ⚠️ updateProfile - No user/profile data in response',
            );
            debugPrint(
              '[FRANCHISE_REPO] 🔑 Response keys: ${response.data.keys}',
            );
            debugPrint(
              '[FRANCHISE_REPO] ========================================',
            );
            return ApiResponse(
              success: false,
              message: 'No profile data in response',
            );
          }

          debugPrint('[FRANCHISE_REPO] 📥 Profile data from response:');
          if (userData is Map) {
            debugPrint('[FRANCHISE_REPO]   - _id: ${userData['_id']}');
            debugPrint(
              '[FRANCHISE_REPO]   - first_name: ${userData['first_name']}',
            );
            debugPrint(
              '[FRANCHISE_REPO]   - last_name: ${userData['last_name']}',
            );
            debugPrint(
              '[FRANCHISE_REPO]   - username: ${userData['username']}',
            );
          }

          final user = User.fromJson(userData);
          debugPrint('[FRANCHISE_REPO] 📊 Parsed User object:');
          debugPrint('[FRANCHISE_REPO]   - ID: ${user.id}');
          debugPrint('[FRANCHISE_REPO]   - Full Name: ${user.fullName}');
          debugPrint('[FRANCHISE_REPO]   - First Name: ${user.firstName}');
          debugPrint('[FRANCHISE_REPO]   - Last Name: ${user.lastName}');
          debugPrint(
            '[FRANCHISE_REPO] ========================================',
          );

          return ApiResponse(success: true, data: user);
        }
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ updateProfile - Failed to update profile: ${response.data['message']}',
      );
      debugPrint('[FRANCHISE_REPO] ========================================');
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FRANCHISE_REPO] ❌ updateProfile - DioException: ${e.message}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 updateProfile - Error response: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 updateProfile - Status code: ${e.response?.statusCode}',
      );
      debugPrint('[FRANCHISE_REPO] ========================================');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ updateProfile - Unexpected error: $e');
      debugPrint('[FRANCHISE_REPO] ========================================');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<bool>> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 updatePreferences - Updating preferences for user: $userId',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📤 updatePreferences - Preferences data: $preferences',
      );
      debugPrint(
        '[FRANCHISE_REPO] 🔢 updatePreferences - Data types: ${preferences.map((k, v) => MapEntry(k, '${v.runtimeType}'))}',
      );

      // API: PUT /api/franchise/profiles/:profileId/preferences (backend uses PUT)
      // Body format: { "preferences": { ...preferences } }
      final endpoint = '${AppConstants.franchiseProfiles}/$userId/preferences';
      debugPrint('[FRANCHISE_REPO] 🌐 updatePreferences - Endpoint: $endpoint');
      debugPrint(
        '[FRANCHISE_REPO] 📦 updatePreferences - Request body: ${{'preferences': preferences}}',
      );

      final response = await _apiService.dio.put(
        endpoint,
        data: {
          'preferences': preferences,
        }, // Wrap in preferences object per API spec
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 updatePreferences - Response received: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 updatePreferences - Response data: ${response.data}',
      );

      if (response.statusCode == 200) {
        debugPrint(
          '[FRANCHISE_REPO] ✅ updatePreferences - Preferences updated successfully',
        );
        return ApiResponse(success: true, data: true);
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ updatePreferences - Failed to update preferences',
      );
      return ApiResponse(
        success: false,
        message: 'Failed to update preferences',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FRANCHISE_REPO] ❌ updatePreferences - DioException: ${e.message}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 updatePreferences - Error response: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 updatePreferences - Status code: ${e.response?.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 updatePreferences - Request data: ${e.requestOptions.data}',
      );

      String errorMsg = 'Network Error';
      try {
        if (e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        }
      } catch (_) {}

      return ApiResponse(success: false, message: errorMsg);
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ updatePreferences - Unexpected error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPreferences(
    String userId,
  ) async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 getPreferences - Fetching preferences for user: $userId',
      );

      final response = await _apiService.dio.get(
        '${AppConstants.franchiseProfiles}/$userId',
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 getPreferences - Response received: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 getPreferences - Response data type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200) {
        final profileData = response.data;

        if (profileData is Map) {
          final prefs = profileData['partner_preferences'];
          debugPrint(
            '[FRANCHISE_REPO] 📦 getPreferences - Raw preferences: $prefs',
          );

          final prefsMap = prefs is Map
              ? Map<String, dynamic>.from(prefs)
              : <String, dynamic>{};
          debugPrint(
            '[FRANCHISE_REPO] ✅ getPreferences - Fetched preferences: $prefsMap',
          );
          debugPrint(
            '[FRANCHISE_REPO] 🔢 getPreferences - Preference types: ${prefsMap.map((k, v) => MapEntry(k, '${v.runtimeType}'))}',
          );

          return ApiResponse(success: true, data: prefsMap);
        }
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ getPreferences - Unexpected response format',
      );
      return ApiResponse(success: true, data: {});
    } on DioException catch (e) {
      debugPrint(
        '[FRANCHISE_REPO] ❌ getPreferences - DioException: ${e.message}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 getPreferences - Error response: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 getPreferences - Status code: ${e.response?.statusCode}',
      );

      if (e.response?.statusCode == 404) {
        debugPrint(
          '[FRANCHISE_REPO] ℹ️ getPreferences - No preferences found (404), returning empty map',
        );
        return ApiResponse(success: true, data: {});
      }
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ getPreferences - Unexpected error: $e');
      return ApiResponse(success: true, data: {});
    }
  }

  Future<ApiResponse<bool>> uploadPhotos(
    String userId,
    List<String> filePaths,
  ) async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 uploadPhotos - Uploading photos for user: $userId',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📸 uploadPhotos - Number of photos: ${filePaths.length}',
      );
      debugPrint('[FRANCHISE_REPO] 📁 uploadPhotos - File paths: $filePaths');

      final formData = FormData();
      for (var path in filePaths) {
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(
              path,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      debugPrint(
        '[FRANCHISE_REPO] 📤 uploadPhotos - FormData prepared with ${formData.files.length} files',
      );

      final response = await _apiService.dio.post(
        '${AppConstants.franchiseProfiles}/$userId/photos',
        data: formData,
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 uploadPhotos - Response received: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 uploadPhotos - Response data: ${response.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 uploadPhotos - Response type: ${response.data.runtimeType}',
      );

      if (response.data is Map) {
        debugPrint(
          '[FRANCHISE_REPO] 🔑 uploadPhotos - Response keys: ${response.data.keys}',
        );
        if (response.data['data'] != null) {
          debugPrint(
            '[FRANCHISE_REPO] 📸 uploadPhotos - Photos array in response: ${response.data['data']}',
          );
        }
        if (response.data['errors'] != null) {
          debugPrint(
            '[FRANCHISE_REPO] ⚠️ uploadPhotos - Errors in response: ${response.data['errors']}',
          );
        }
      }

      if (response.data is! Map) {
        return ApiResponse(success: false, message: 'Invalid server response');
      }

      if (response.statusCode == 200) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          debugPrint(
            '[FRANCHISE_REPO] ✅ uploadPhotos - Photos uploaded successfully',
          );
          return ApiResponse(success: true, data: true);
        }
      }

      debugPrint(
        '[FRANCHISE_REPO] ⚠️ uploadPhotos - Failed to upload photos: ${response.data['message']}',
      );
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to upload photos',
      );
    } on DioException catch (e) {
      debugPrint(
        '[FRANCHISE_REPO] ❌ uploadPhotos - DioException: ${e.message}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 uploadPhotos - Error response: ${e.response?.data}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📛 uploadPhotos - Status code: ${e.response?.statusCode}',
      );
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ uploadPhotos - Unexpected error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<List<int>>> getMatchPdf(
    String profileId,
    String language,
  ) async {
    try {
      final response = await _apiService.dio.get(
        '${AppConstants.franchisePdf}/$profileId/pdf',
        queryParameters: {'language': language},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ApiResponse(success: true, data: response.data);
      }
      return ApiResponse(success: false, message: 'Failed to download PDF');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<User>> getProfile(String userId) async {
    try {
      debugPrint('[FRANCHISE_REPO] 🔵 getProfile - Fetching profile: $userId');

      final response = await _apiService.dio.get(
        '${AppConstants.franchiseProfiles}/$userId',
      );

      debugPrint(
        '[FRANCHISE_REPO] 🟢 getProfile - Response: ${response.statusCode}',
      );
      debugPrint(
        '[FRANCHISE_REPO] 📦 getProfile - Data type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200) {
        final userData = response.data;

        if (userData is! Map) {
          debugPrint('[FRANCHISE_REPO] ⚠️ getProfile - Response is not a Map');
          return ApiResponse(
            success: false,
            message: 'Invalid response format',
          );
        }

        debugPrint(
          '[FRANCHISE_REPO] 🔑 getProfile - Response keys: ${userData.keys}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 📸 getProfile - Photos in response: ${userData['photos']}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 📸 getProfile - Profile photo: ${userData['profile_photo']}',
        );
        debugPrint(
          '[FRANCHISE_REPO] ✅ getProfile - Profile fetched: ${userData['_id']}',
        );

        final user = User.fromJson(Map<String, dynamic>.from(userData));
        debugPrint(
          '[FRANCHISE_REPO] 📊 getProfile - Parsed user photos count: ${user.photos.length}',
        );
        debugPrint(
          '[FRANCHISE_REPO] 📊 getProfile - Parsed profile photo: ${user.profilePhoto}',
        );

        return ApiResponse(success: true, data: user);
      }

      return ApiResponse(success: false, message: 'Failed to fetch profile');
    } on DioException catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ getProfile - DioException: ${e.message}');
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ getProfile - Error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<bool>> deletePhoto(String userId, String photoId) async {
    try {
      final response = await _apiService.dio.delete(
        '${AppConstants.franchiseProfiles}/$userId/photos/$photoId',
      );

      if (response.statusCode == 200 && response.data is Map) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          return ApiResponse(success: true, data: true);
        }
      }
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete photo',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<User>> updateFranchiseOwnerProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 updateFranchiseOwnerProfile - Updating owner profile',
      );
      debugPrint('[FRANCHISE_REPO] 📤 Data: $data');

      final response = await _apiService.dio.post(
        AppConstants.authRegisterDetails,
        data: data,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[FRANCHISE_REPO] 🟢 Response: ${response.statusCode}');
      debugPrint(
        '[FRANCHISE_REPO] 📦 Response data type: ${response.data.runtimeType}',
      );
      debugPrint('[FRANCHISE_REPO] 📦 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data is Map) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          final userData = response.data['user'];
          debugPrint('[FRANCHISE_REPO] 👤 User data: $userData');

          if (userData != null) {
            final user = User.fromJson(Map<String, dynamic>.from(userData));
            debugPrint('[FRANCHISE_REPO] ✅ Profile updated successfully');
            return ApiResponse(success: true, data: user);
          }

          debugPrint('[FRANCHISE_REPO] ⚠️ No user data in response');
          return ApiResponse(
            success: false,
            message: 'No user data in response',
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile',
      );
    } on DioException catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ DioException: ${e.message}');
      debugPrint('[FRANCHISE_REPO] 📛 Error response: ${e.response?.data}');
      debugPrint('[FRANCHISE_REPO] 📛 Status code: ${e.response?.statusCode}');

      final errorData = e.response?.data;
      return ApiResponse(
        success: false,
        message: errorData is Map
            ? errorData['message'] ?? e.message ?? 'Network Error'
            : e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ Error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<bool>> updateFranchiseStatus(String status) async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 updateFranchiseStatus - Updating status to: $status',
      );

      final response = await _apiService.dio.post(
        AppConstants.authRegisterDetails,
        data: {'franchise_status': status},
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[FRANCHISE_REPO] 🟢 Response: ${response.statusCode}');
      debugPrint('[FRANCHISE_REPO] 📦 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data is Map) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          debugPrint('[FRANCHISE_REPO] ✅ Status updated successfully');
          return ApiResponse(success: true, data: true);
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update status',
      );
    } on DioException catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ DioException: ${e.message}');
      debugPrint('[FRANCHISE_REPO] 📛 Error response: ${e.response?.data}');
      debugPrint('[FRANCHISE_REPO] 📛 Status code: ${e.response?.statusCode}');

      final errorData = e.response?.data;
      return ApiResponse(
        success: false,
        message: errorData is Map
            ? errorData['message'] ?? e.message ?? 'Network Error'
            : e.message ?? 'Network Error',
      );
    } catch (e) {
      debugPrint('[FRANCHISE_REPO] ❌ Error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<bool>> setProfilePhoto(
    String userId,
    String photoId,
  ) async {
    try {
      debugPrint(
        '[FRANCHISE_REPO] 🔵 setProfilePhoto - Setting profile photo: $photoId for user: $userId',
      );

      final response = await _apiService.dio.patch(
        '${AppConstants.franchiseProfiles}/$userId/photos/$photoId/set-profile',
      );

      if (response.statusCode == 200 && response.data is Map) {
        // Check if success field exists and is true (handle null case)
        final success = response.data['success'];
        debugPrint(
          '[FRANCHISE_REPO] 📊 Success field: $success (${success.runtimeType})',
        );

        if (success == true || success == null) {
          // If success is null, assume success if status is 200
          return ApiResponse(success: true, data: true);
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to set profile photo',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
