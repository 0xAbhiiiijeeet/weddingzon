import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _signIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId:
          '294108253572-oih80rbj00t8rrntjincau7hi6cbji4f.apps.googleusercontent.com',
    );
    return _googleSignIn!;
  }

  AuthRepository(this._apiService, this._storageService);

  Future<ApiResponse<User>> googleLogin() async {
    try {
      debugPrint('[AUTH] ===== GOOGLE SIGN-IN (ID TOKEN FLOW) =====');

      final googleUser = await _signIn.signIn();

      if (googleUser == null) {
        return ApiResponse(success: false, message: 'Sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('[AUTH] idToken is null');
        return ApiResponse(
          success: false,
          message: 'Failed to get Google ID token',
        );
      }

      debugPrint('[AUTH] idToken obtained');
      return await _loginWithIdToken(idToken);
    } catch (e, stackTrace) {
      debugPrint('[AUTH] Google login failed: $e');
      debugPrint('$stackTrace');
      return ApiResponse(success: false, message: 'Google sign-in failed');
    }
  }

  Future<ApiResponse<User>> _loginWithIdToken(String idToken) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.authGoogle,
        data: {'idToken': idToken},
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[AUTH] Backend response: ${response.statusCode}');
      return _handleStatusCodeAndResponse(response);
    } on DioException catch (e) {
      debugPrint('[AUTH] Backend error: ${e.response?.statusCode}');
      return _handleDioException(e);
    } catch (e) {
      debugPrint('[AUTH] _loginWithIdToken failed: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to authenticate with Google',
      );
    }
  }

  Future<ApiResponse<String>> sendOtp(String phoneNumber) async {
    try {
      debugPrint('[AUTH] Phone: $phoneNumber');

      final response = await _apiService.dio.post(
        AppConstants.authSendOtp,
        data: {'phone': phoneNumber},
      );

      debugPrint('[AUTH] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('[AUTH] OTP sent successfully');
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'OTP sent successfully',
        );
      } else if (response.statusCode == 400) {
        debugPrint('[AUTH] 400 Bad Request');
        return ApiResponse(
          success: false,
          message: response.data?['message'] ?? 'Invalid phone number',
        );
      } else if (response.statusCode == 429) {
        debugPrint('[AUTH] 429 Too Many Requests');
        return ApiResponse(
          success: false,
          message: response.data?['message'] ?? 'Too many attempts',
        );
      } else {
        debugPrint('[AUTH] Unexpected status: ${response.statusCode}');
        return ApiResponse(success: false, message: 'Failed to send OTP');
      }
    } on DioException catch (e) {
      debugPrint('[AUTH] Send OTP error: ${e.response?.statusCode}');
      return _handleDioException(e, defaultMessage: 'Failed to send OTP');
    }
  }

  Future<ApiResponse<User>> verifyOtp(String phoneNumber, String otp) async {
    try {
      debugPrint('[AUTH] Phone: $phoneNumber');
      debugPrint('[AUTH] OTP length: ${otp.length}');

      final response = await _apiService.dio.post(
        AppConstants.authVerifyOtp,
        data: {'phone': phoneNumber, 'code': otp},
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[AUTH] Response status: ${response.statusCode}');
      return _handleStatusCodeAndResponse(response);
    } on DioException catch (e) {
      debugPrint('[AUTH] Verify OTP error: ${e.response?.statusCode}');
      return _handleDioException(e, defaultMessage: 'OTP verification failed');
    }
  }

  Future<ApiResponse<User>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      debugPrint('[AUTH] Profile data keys: ${profileData.keys}');

      final response = await _apiService.dio.post(
        AppConstants.authRegisterDetails,
        data: profileData,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[AUTH] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('[AUTH] Profile updated successfully');
        final userData = response.data['user'];
        if (userData != null) {
          return ApiResponse(
            success: true,
            data: User.fromJson(Map<String, dynamic>.from(userData)),
          );
        }
        return ApiResponse(success: false, message: 'No user data in response');
      } else {
        return _handleStatusCodeAndResponse(response);
      }
    } on DioException catch (e) {
      debugPrint('[AUTH] Update profile error: ${e.response?.statusCode}');
      return _handleDioException(e, defaultMessage: 'Failed to update profile');
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      debugPrint('[AUTH] ========== FETCHING CURRENT USER ==========');

      final response = await _apiService.dio.get(
        AppConstants.authMe,
        queryParameters: {'full': true},
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[AUTH] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          debugPrint('[AUTH] Response data is null');
          return ApiResponse(success: false, message: 'No user data received');
        }
        debugPrint('[AUTH] User data received');
        return ApiResponse(success: true, data: User.fromJson(response.data));
      } else if (response.statusCode == 401) {
        debugPrint('[AUTH] 401 Unauthorized');
        return ApiResponse(success: false, message: 'Session expired');
      } else {
        debugPrint('[AUTH] Unexpected status: ${response.statusCode}');
        return ApiResponse(success: false, message: 'Failed to fetch user');
      }
    } on DioException catch (e) {
      debugPrint('[AUTH] Get user error: ${e.type}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('[AUTH] Network error');
        return ApiResponse(success: false, message: 'Network error');
      }

      return _handleDioException(e, defaultMessage: 'Failed to fetch user');
    } catch (e) {
      debugPrint('[AUTH] Unexpected error: $e');
      return ApiResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('[AUTH] ========== LOGGING OUT ==========');

      final response = await _apiService.dio.post(
        AppConstants.authLogout,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[AUTH] Logout status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('[AUTH] Backend logout successful');
      } else {
        debugPrint('[AUTH] Backend logout returned: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AUTH] Logout error: $e');
    }

    try {
      await _signIn.signOut();
      debugPrint('[AUTH] Google sign out successful');
    } catch (e) {
      debugPrint('[AUTH] Google sign out error: $e');
    }

    await _storageService.clearTokens();
    await _apiService.clearCookies();
    debugPrint('[AUTH] Local cleanup complete');
  }

  ApiResponse<User> _handleStatusCodeAndResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _handleAuthResponse(response);
    } else if (response.statusCode == 400) {
      debugPrint('[AUTH] 400 Bad Request');
      return ApiResponse<User>(
        success: false,
        message: response.data?['message'] ?? 'Invalid request',
      );
    } else if (response.statusCode == 401) {
      debugPrint('[AUTH] 401 Unauthorized');
      return ApiResponse<User>(
        success: false,
        message: response.data?['message'] ?? 'Authentication failed',
      );
    } else if (response.statusCode == 403) {
      debugPrint('[AUTH] 403 Forbidden');
      return ApiResponse<User>(
        success: false,
        message: response.data?['message'] ?? 'Access denied',
      );
    } else if (response.statusCode == 404) {
      debugPrint('[AUTH] 404 Not Found');
      return ApiResponse<User>(success: false, message: 'Resource not found');
    } else if (response.statusCode == 429) {
      debugPrint('[AUTH] 429 Too Many Requests');
      return ApiResponse<User>(success: false, message: 'Too many requests');
    } else if (response.statusCode != null && response.statusCode! >= 500) {
      debugPrint('[AUTH] ${response.statusCode} Server Error');
      return ApiResponse<User>(success: false, message: 'Server error');
    } else {
      debugPrint('[AUTH] Unexpected status: ${response.statusCode}');
      return ApiResponse<User>(success: false, message: 'Request failed');
    }
  }

  ApiResponse<T> _handleDioException<T>(
    DioException e, {
    String? defaultMessage,
  }) {
    if (e.type == DioExceptionType.connectionTimeout) {
      debugPrint('[AUTH] Connection timeout');
      return ApiResponse<T>(success: false, message: 'Connection timeout');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      debugPrint('[AUTH] Receive timeout');
      return ApiResponse<T>(success: false, message: 'Request timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      debugPrint('[AUTH] Connection error');
      return ApiResponse<T>(success: false, message: 'Network error');
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      debugPrint('[AUTH] Bad response: $statusCode');

      if (statusCode == 400) {
        return ApiResponse<T>(
          success: false,
          message: e.response?.data['message'] ?? 'Invalid request',
        );
      } else if (statusCode == 401) {
        return ApiResponse<T>(
          success: false,
          message: e.response?.data['message'] ?? 'Unauthorized',
        );
      } else if (statusCode == 403) {
        return ApiResponse<T>(success: false, message: 'Access denied');
      } else if (statusCode == 404) {
        return ApiResponse<T>(success: false, message: 'Not found');
      } else if (statusCode == 429) {
        return ApiResponse<T>(success: false, message: 'Too many requests');
      } else if (statusCode != null && statusCode >= 500) {
        return ApiResponse<T>(success: false, message: 'Server error');
      }
    } else if (e.type == DioExceptionType.cancel) {
      debugPrint('[AUTH] Request cancelled');
      return ApiResponse<T>(success: false, message: 'Request cancelled');
    }

    return ApiResponse<T>(
      success: false,
      message:
          e.response?.data?['message'] ??
          e.message ??
          defaultMessage ??
          'Request failed',
    );
  }

  ApiResponse<User> _handleAuthResponse(Response response) {
    debugPrint('[AUTH] Response Data: ${response.data}');

    final data = response.data;

    if (data == null) {
      debugPrint('[AUTH] Response data is null');
      return ApiResponse(success: false, message: 'Empty response from server');
    }

    if (data is! Map) {
      debugPrint('[AUTH] Response data is not a Map: ${data.runtimeType}');
      return ApiResponse(success: false, message: 'Invalid response format');
    }

    final isSuccess = data['success'] == true;
    debugPrint('[AUTH] Success flag: $isSuccess');

    if (!isSuccess) {
      debugPrint('[AUTH] Success flag is false');
      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Authentication failed',
      );
    }

    final accessToken =
        data['accessToken'] ?? data['access_token'] ?? data['token'];
    final refreshToken = data['refreshToken'] ?? data['refresh_token'];

    if (accessToken != null) {
      debugPrint('[AUTH] Access token found in response, saving...');
      _storageService.saveTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken?.toString() ?? '',
      );
    } else {
      debugPrint(
        '[AUTH] No access token in response body (using cookies only)',
      );
    }

    final userData = data['user'];

    if (userData == null) {
      debugPrint('[AUTH] No user data in response');
      debugPrint('[AUTH] Available keys: ${data.keys}');
      return ApiResponse(success: false, message: 'No user data received');
    }

    if (userData is! Map) {
      debugPrint('[AUTH] User data is not a Map: ${userData.runtimeType}');
      return ApiResponse(success: false, message: 'Invalid user data format');
    }

    debugPrint('[AUTH] User data found');
    debugPrint('[AUTH] User email: ${userData['email']}');
    debugPrint('[AUTH] User ID: ${userData['_id']}');
    debugPrint('[AUTH] ==============================================');

    return ApiResponse(
      success: true,
      data: User.fromJson(Map<String, dynamic>.from(userData)),
    );
  }


  Future<String?>? _refreshTokenFuture;

  Future<String?> refreshToken() async {
    if (_refreshTokenFuture != null) {
      debugPrint('[AUTH] Refresh already in progress, joining wait...');
      return _refreshTokenFuture;
    }

    _refreshTokenFuture = _performTokenRefresh();
    final result = await _refreshTokenFuture;
    _refreshTokenFuture = null;
    return result;
  }

  Future<String?> _performTokenRefresh() async {
    try {
      debugPrint('[AUTH] ========== REFRESHING TOKEN ==========');


      final response = await _apiService.dio.post(
        AppConstants.refreshToken,
        options: Options(extra: {'withCredentials': true}),
      );

      debugPrint('[AUTH] Refresh status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final newAccessToken =
              data['accessToken'] ?? data['access_token'] ?? data['token'];

          if (newAccessToken != null) {
            debugPrint('[AUTH] Token refreshed successfully');
            await _storageService.saveTokens(
              accessToken: newAccessToken.toString(),
              refreshToken:
                  '',
            );
            return newAccessToken.toString();
          }
        }
      }

      debugPrint('[AUTH] Refresh failed or no token in response');
      return null;
    } catch (e) {
      debugPrint('[AUTH] Token refresh failed: $e');
      return null;
    }
  }

  Future<ApiResponse<User>> mockFranchiseLogin() async {
    debugPrint('[AUTH] ========== MOCK FRANCHISE LOGIN ==========');
    await Future.delayed(const Duration(seconds: 1));

    final mockUser = User(
      id: 'mock_franchise_id_123',
      email: 'franchise@test.com',
      username: 'testfranchise',
      role: 'franchise',
      phone: '+919876543210',
      isPhoneVerified: true,
      isProfileComplete: true,
      firstName: 'Test',
      lastName: 'Franchise',
    );

    return ApiResponse(success: true, data: mockUser);
  }

  Future<ApiResponse<User>> loginWithPassword(
    String username,
    String password,
  ) async {
    try {
      debugPrint('[AUTH] Logging in with password: $username');
      final response = await _apiService.dio.post(
        AppConstants.authLogin,
        data: {'username': username, 'password': password},
        options: Options(extra: {'withCredentials': true}),
      );

      return _handleStatusCodeAndResponse(response);
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}