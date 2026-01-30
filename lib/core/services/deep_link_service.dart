import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'navigation_service.dart';

class DeepLinkService {
  final NavigationService _navigationService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isAuthenticated = false;

  String? _pendingUsername;

  DateTime? _lastNavigationTime;
  static const _debounceMilliseconds = 500;

  static const _allowedHosts = [
    'dev.d34g4kpybwb3xb.amplifyapp.com',
    'd34g4kpybwb3xb.amplifyapp.com',
  ];

  DeepLinkService(this._navigationService);

  String? get pendingUsername => _pendingUsername;

  void clearPendingUsername() {
    _pendingUsername = null;
  }

  void updateAuthStatus(bool isAuthenticated) {
    debugPrint('[DeepLink] Auth status updated: $isAuthenticated');
    _isAuthenticated = isAuthenticated;
  }

  Future<void> initialize({required bool isAuthenticated}) async {
    debugPrint('[DeepLink] ========================================');
    debugPrint('[DeepLink] INITIALIZING DEEP LINK SERVICE');
    debugPrint('[DeepLink] isAuthenticated: $isAuthenticated');
    debugPrint('[DeepLink] ========================================');

    _isAuthenticated = isAuthenticated;

    try {
      debugPrint('[DeepLink] Checking for initial link (cold start)...');
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DeepLink] ✅ COLD START LINK DETECTED!');
        debugPrint('[DeepLink] Full URL: $initialUri');
        debugPrint('[DeepLink] Scheme: ${initialUri.scheme}');
        debugPrint('[DeepLink] Host: ${initialUri.host}');
        debugPrint('[DeepLink] Path: ${initialUri.path}');
        debugPrint('[DeepLink] Path Segments: ${initialUri.pathSegments}');
        await _handleDeepLink(initialUri);
      } else {
        debugPrint('[DeepLink] ℹ️ No initial link found (normal app start)');
      }
    } catch (e, stackTrace) {
      debugPrint('[DeepLink] ❌ ERROR getting initial link: $e');
      debugPrint('[DeepLink] Stack trace: $stackTrace');
    }

    debugPrint('[DeepLink] Setting up warm start listener...');
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[DeepLink] ========================================');
        debugPrint('[DeepLink] ✅ WARM START LINK RECEIVED!');
        debugPrint('[DeepLink] Full URL: $uri');
        debugPrint('[DeepLink] Scheme: ${uri.scheme}');
        debugPrint('[DeepLink] Host: ${uri.host}');
        debugPrint('[DeepLink] Path: ${uri.path}');
        debugPrint('[DeepLink] Path Segments: ${uri.pathSegments}');
        debugPrint('[DeepLink] ========================================');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('[DeepLink] Error in link stream: $err');
      },
    );

    debugPrint('[DeepLink] ✅ Deep link service initialized successfully');
    debugPrint('[DeepLink] Warm start listener: ACTIVE');
    debugPrint('[DeepLink] ========================================');
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('[DeepLink] ----------------------------------------');
    debugPrint('[DeepLink] PROCESSING DEEP LINK');
    debugPrint('[DeepLink] URL: $uri');
    debugPrint('[DeepLink] isAuthenticated: $_isAuthenticated');

    debugPrint('[DeepLink] Step 1: Validating domain...');
    if (!_isValidHost(uri.host)) {
      debugPrint('[DeepLink] ❌ INVALID HOST: ${uri.host}');
      debugPrint('[DeepLink] Allowed hosts: $_allowedHosts');
      debugPrint('[DeepLink] Link REJECTED for security');
      return;
    }
    debugPrint('[DeepLink] ✅ Domain validated: ${uri.host}');

    debugPrint('[DeepLink] Step 2: Checking debounce...');
    if (_shouldDebounce()) {
      final timeSinceLastNav = DateTime.now()
          .difference(_lastNavigationTime!)
          .inMilliseconds;
      debugPrint(
        '[DeepLink] ⏸️ DEBOUNCED! Last navigation was ${timeSinceLastNav}ms ago',
      );
      debugPrint('[DeepLink] Ignoring duplicate navigation');
      return;
    }
    debugPrint('[DeepLink] ✅ Debounce check passed');

    debugPrint('[DeepLink] Step 3: Extracting username...');
    debugPrint('[DeepLink] Path segments: ${uri.pathSegments}');
    final username = _extractUsername(uri);
    if (username == null) {
      debugPrint('[DeepLink] ❌ NO USERNAME found in URL');
      debugPrint('[DeepLink] Path: ${uri.path}');
      debugPrint('[DeepLink] Link REJECTED');
      return;
    }
    debugPrint('[DeepLink] ✅ Username extracted: "$username"');

    debugPrint('[DeepLink] Step 4: Sanitizing username...');
    final sanitizedUsername = _sanitizeUsername(username);
    debugPrint('[DeepLink] Original: "$username"');
    debugPrint('[DeepLink] Sanitized: "$sanitizedUsername"');

    if (sanitizedUsername.isEmpty) {
      debugPrint('[DeepLink] ❌ USERNAME EMPTY after sanitization');
      debugPrint('[DeepLink] Link REJECTED for security');
      return;
    }
    debugPrint('[DeepLink] ✅ Username sanitized and valid');

    debugPrint('[DeepLink] Step 5: Checking authentication...');
    if (!_isAuthenticated) {
      debugPrint('[DeepLink] ⚠️ USER NOT AUTHENTICATED');
      debugPrint('[DeepLink] Storing pending username: $sanitizedUsername');
      _pendingUsername = sanitizedUsername;
      debugPrint('[DeepLink] User will be redirected to login');
      debugPrint(
        '[DeepLink] After login, will navigate to: $sanitizedUsername',
      );
      debugPrint('[DeepLink] ----------------------------------------');
      return;
    }
    debugPrint('[DeepLink] ✅ User is authenticated');

    debugPrint('[DeepLink] Step 6: Navigating to profile...');
    _navigateToProfile(sanitizedUsername);
    debugPrint('[DeepLink] ----------------------------------------');
  }

  void _navigateToProfile(String username) {
    debugPrint('[DeepLink] ========================================');
    debugPrint('[DeepLink] 🚀 NAVIGATING TO PROFILE');
    debugPrint('[DeepLink] Username: $username');
    debugPrint('[DeepLink] Route: ${AppRoutes.userProfile}');
    _lastNavigationTime = DateTime.now();

    try {
      _navigationService.navigateTo(AppRoutes.userProfile, arguments: username);
      debugPrint('[DeepLink] ✅ Navigation initiated successfully');
    } catch (e, stackTrace) {
      debugPrint('[DeepLink] ❌ NAVIGATION FAILED: $e');
      debugPrint('[DeepLink] Stack trace: $stackTrace');
    }
    debugPrint('[DeepLink] ========================================');
  }

  void navigateToPendingProfile() {
    debugPrint('[DeepLink] ========================================');
    debugPrint('[DeepLink] CHECKING PENDING PROFILE');
    debugPrint('[DeepLink] Pending username: $_pendingUsername');

    if (_pendingUsername != null) {
      debugPrint(
        '[DeepLink] ✅ Navigating to pending profile: $_pendingUsername',
      );
      _navigateToProfile(_pendingUsername!);
      debugPrint('[DeepLink] Clearing pending username');
      _pendingUsername = null;
      debugPrint('[DeepLink] ✅ Pending profile navigation complete');
    } else {
      debugPrint('[DeepLink] ℹ️ No pending profile to navigate to');
    }
    debugPrint('[DeepLink] ========================================');
  }

  String? _extractUsername(Uri uri) {
    debugPrint('[DeepLink] Extracting username from path: ${uri.path}');
    debugPrint('[DeepLink] Path segments count: ${uri.pathSegments.length}');

    if (uri.pathSegments.isEmpty) {
      debugPrint('[DeepLink] No path segments found');
      return null;
    }

    final username = uri.pathSegments.first;
    debugPrint('[DeepLink] Extracted: "$username"');
    return username;
  }

  String _sanitizeUsername(String username) {
    debugPrint('[DeepLink] Sanitizing username: "$username"');
    final sanitized = username.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '');
    final trimmed = sanitized.trim();
    debugPrint('[DeepLink] After sanitization: "$trimmed"');
    if (username != trimmed) {
      debugPrint('[DeepLink] ⚠️ Username was modified during sanitization');
    }
    return trimmed;
  }

  bool _isValidHost(String host) {
    final lowercaseHost = host.toLowerCase();
    final isValid = _allowedHosts.contains(lowercaseHost);
    debugPrint(
      '[DeepLink] Host validation: "$host" -> ${isValid ? "VALID" : "INVALID"}',
    );
    return isValid;
  }

  bool _shouldDebounce() {
    if (_lastNavigationTime == null) {
      debugPrint('[DeepLink] No previous navigation, debounce: false');
      return false;
    }
    final elapsed = DateTime.now().difference(_lastNavigationTime!);
    final shouldDebounce = elapsed.inMilliseconds < _debounceMilliseconds;
    debugPrint(
      '[DeepLink] Time since last nav: ${elapsed.inMilliseconds}ms, debounce: $shouldDebounce',
    );
    return shouldDebounce;
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    debugPrint('[DeepLink] Deep link service disposed');
  }
}