import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class ApiService {
  late final Dio _dio;
  PersistCookieJar? _cookieJar;
  String? _csrfToken;
  bool _initialized = false;
  bool _isRefreshing = false;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );
  }

  Dio get dio {
    assert(
      _initialized,
      'ApiService must be initialized before use. Call init() first.',
    );
    return _dio;
  }

  /// Get cookies as a string for socket authentication
  Future<String> getCookieString([String? url]) async {
    if (_cookieJar == null) return '';

    try {
      final targetUrl = url ?? AppConstants.baseUrl;
      final uri = Uri.parse(targetUrl);
      final cookies = await _cookieJar!.loadForRequest(uri);

      if (cookies.isEmpty) {
        debugPrint('[API] No cookies found for socket auth');
        return '';
      }

      final cookieString = cookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');
      debugPrint(
        '[API] Socket cookie string generated (${cookies.length} cookies)',
      );
      return cookieString;
    } catch (e) {
      debugPrint('[API] Error getting cookies: $e');
      return '';
    }
  }

  /// Extract the access_token from cookies for Socket.IO authentication
  /// Returns the JWT token value or null if not found
  Future<String?> getAccessTokenFromCookies() async {
    if (_cookieJar == null) {
      debugPrint('[API] Cookie jar not initialized');
      return null;
    }

    try {
      // Use socket URL to ensure we get cookies for the correct domain
      final uri = Uri.parse(AppConstants.socketUrl);
      final cookies = await _cookieJar!.loadForRequest(uri);

      if (cookies.isEmpty) {
        debugPrint('[API] No cookies found for token extraction');
        return null;
      }

      // Find the access_token cookie
      final accessTokenCookie = cookies.firstWhere(
        (cookie) => cookie.name == 'access_token',
        orElse: () => Cookie('', ''),
      );

      if (accessTokenCookie.value.isEmpty) {
        debugPrint('[API] access_token cookie not found');
        return null;
      }

      debugPrint('[API] Access token extracted successfully');
      debugPrint(
        '[API] Token preview: ${accessTokenCookie.value.substring(0, 20)}...',
      );
      return accessTokenCookie.value;
    } catch (e) {
      debugPrint('[API] Error extracting access token: $e');
      return null;
    }
  }

  /// Initialize the API service - MUST be called before using
  Future<void> init() async {
    if (_initialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/.cookies/';

    _cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    debugPrint('[API] Cookie storage initialized at: $cookiePath');
    _setupInterceptors();
    _initialized = true;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(CookieManager(_cookieJar!));

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['withCredentials'] == true) {
            debugPrint('[API] withCredentials enabled - cookies will be sent');
          }

          final mutatingMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
          if (mutatingMethods.contains(options.method.toUpperCase()) &&
              _csrfToken != null) {
            options.headers['X-CSRF-Token'] = _csrfToken;
            debugPrint('[API] Added X-CSRF-Token header');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) async {
          debugPrint('[API] ========== RESPONSE ==========');
          debugPrint('[API] Status: ${response.statusCode}');

          final cookies = response.headers['set-cookie'];
          if (cookies != null && cookies.isNotEmpty) {
            debugPrint('[API] Cookies received: ${cookies.length}');
            for (var cookie in cookies) {
              if (cookie.contains('access_token')) {
                debugPrint('[API] access_token cookie set');
              }
              if (cookie.contains('refresh_token')) {
                debugPrint('[API] refresh_token cookie set');
              }
              if (cookie.contains('csrf_token')) {
                final parts = cookie.split(';')[0].split('=');
                if (parts.length > 1) {
                  _csrfToken = parts[1];
                  debugPrint('[API] csrf_token extracted');
                }
              }
            }
          }

          debugPrint('[API] ==================================');

          // Handle 401 Unauthorized or 403 Forbidden - try to refresh token
          if ((response.statusCode == 401 || response.statusCode == 403) &&
              !_isRefreshing) {
            debugPrint(
              '[API] ${response.statusCode} detected, attempting token refresh...',
            );
            _isRefreshing = true;

            try {
              // Call refresh endpoint with refresh_token cookie
              final refreshResponse = await _dio.post(
                AppConstants.refreshToken,
                options: Options(extra: {'withCredentials': true}),
              );

              if (refreshResponse.statusCode == 200) {
                debugPrint('[API] Token refreshed successfully');
                _isRefreshing = false;

                // Retry the original request
                final retryResponse = await _retry(response.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (refreshError) {
              debugPrint('[API] Token refresh failed: $refreshError');
              _isRefreshing = false;
              // Let the 401 propagate - user needs to re-login
            }

            _isRefreshing = false;
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          debugPrint('[API] ========== ERROR ==========');
          debugPrint('[API] Type: ${e.type}');
          debugPrint('[API] Status Code: ${e.response?.statusCode}');
          debugPrint('[API] Message: ${e.message}');
          debugPrint('[API] ===============================');

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown) {
            debugPrint('[API] Network connectivity issue');
          }

          return handler.next(e);
        },
      ),
    );
  }

  /// Retry a failed request with fresh credentials
  Future<Response> _retry(RequestOptions requestOptions) async {
    // Remove the 'Cookie' header to force Dio to load fresh cookies from the jar
    final newHeaders = Map<String, dynamic>.from(requestOptions.headers);
    newHeaders.remove('cookie');
    newHeaders.remove('Cookie');

    final options = Options(
      method: requestOptions.method,
      headers: newHeaders,
      extra: requestOptions.extra,
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> clearCookies() async {
    if (_cookieJar != null) {
      await _cookieJar!.deleteAll();
      debugPrint('[API] Cookies cleared');
    } else {
      debugPrint('[API] Cookie jar not initialized, nothing to clear');
    }
  }
}
