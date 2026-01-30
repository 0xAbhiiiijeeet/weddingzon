import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import 'logging_service.dart';

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

  Future<String?> getAccessTokenFromCookies() async {
    if (_cookieJar == null) {
      debugPrint('[API] Cookie jar not initialized');
      return null;
    }

    try {
      final uri = Uri.parse(AppConstants.socketUrl);
      final cookies = await _cookieJar!.loadForRequest(uri);

      if (cookies.isEmpty) {
        debugPrint('[API] No cookies found for token extraction');
        return null;
      }

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
    final logger = LoggingService();
    _dio.interceptors.add(CookieManager(_cookieJar!));

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        logPrint: (obj) => logger.logNetwork(obj.toString()),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['withCredentials'] == true) {
            logger.debug(
              '[API] withCredentials enabled - cookies will be sent',
            );
          }

          try {
            final token = await getAccessTokenFromCookies();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
          }

          final mutatingMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
          if (mutatingMethods.contains(options.method.toUpperCase()) &&
              _csrfToken != null) {
            options.headers['X-CSRF-Token'] = _csrfToken;
            logger.debug('[API] Added X-CSRF-Token header');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) async {
          logger.logNetwork('[API] ========== RESPONSE ==========');
          logger.logNetwork('[API] Status: ${response.statusCode}');

          final cookies = response.headers['set-cookie'];
          if (cookies != null && cookies.isNotEmpty) {
            logger.debug('[API] Cookies received: ${cookies.length}');
            for (var cookie in cookies) {
              if (cookie.contains('access_token')) {
                logger.debug('[API] access_token cookie set');
              }
              if (cookie.contains('refresh_token')) {
                logger.debug('[API] refresh_token cookie set');
              }
              if (cookie.contains('csrf_token')) {
                final parts = cookie.split(';')[0].split('=');
                if (parts.length > 1) {
                  _csrfToken = parts[1];
                  logger.debug('[API] csrf_token extracted');
                }
              }
            }
          }

          logger.logNetwork('[API] ==================================');

          if ((response.statusCode == 401 || response.statusCode == 403) &&
              !_isRefreshing &&
              response.requestOptions.extra['_isRetry'] != true) {
            logger.warning(
              '[API] ${response.statusCode} detected, attempting token refresh...',
            );
            _isRefreshing = true;

            try {
              final refreshResponse = await _dio.post(
                AppConstants.refreshToken,
                options: Options(extra: {'withCredentials': true}),
              );

              if (refreshResponse.statusCode == 200) {
                logger.info('[API] Token refreshed successfully');
                _isRefreshing = false;

                final retryResponse = await _retry(response.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (refreshError) {
              logger.error('[API] Token refresh failed: $refreshError');
              _isRefreshing = false;
            }

            _isRefreshing = false;
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          logger.error('[API] ========== ERROR ==========');
          logger.error('[API] Type: ${e.type}');
          logger.error('[API] Status Code: ${e.response?.statusCode}');
          logger.error('[API] Message: ${e.message}');
          logger.error('[API] ===============================');

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown) {
            logger.error('[API] Network connectivity issue');
          }

          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final newHeaders = Map<String, dynamic>.from(requestOptions.headers);
    newHeaders.remove('cookie');
    newHeaders.remove('Cookie');

    final newExtra = Map<String, dynamic>.from(requestOptions.extra);
    newExtra['_isRetry'] = true;

    final options = Options(
      method: requestOptions.method,
      headers: newHeaders,
      extra: newExtra,
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