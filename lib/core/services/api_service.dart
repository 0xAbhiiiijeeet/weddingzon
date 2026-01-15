import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class ApiService {
  late final Dio _dio;
  late final PersistCookieJar _cookieJar;
  String? _csrfToken;
  bool _initialized = false;

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

  Dio get dio => _dio;

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
    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
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
        onResponse: (response, handler) {
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

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
    debugPrint('[API] Cookies cleared');
  }
}
