import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'navigation_service.dart';

/// Service to handle deep links for profile sharing
/// Handles both cold starts (app terminated) and warm starts (app running/backgrounded)
class DeepLinkService {
  final NavigationService _navigationService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isAuthenticated = false;

  // Store pending deep link if user is not logged in
  String? _pendingUsername;

  // Debouncing to prevent multiple rapid navigations
  DateTime? _lastNavigationTime;
  static const _debounceMilliseconds = 500;

  // Whitelist of allowed hosts for security
  static const _allowedHosts = [
    'dev.d34g4kpybwb3xb.amplifyapp.com',
    'd34g4kpybwb3xb.amplifyapp.com', // production domain if different
  ];

  DeepLinkService(this._navigationService);

  /// Get pending username (used after login)
  String? get pendingUsername => _pendingUsername;

  /// Clear pending username
  void clearPendingUsername() {
    _pendingUsername = null;
  }

  /// Update authentication status
  void updateAuthStatus(bool isAuthenticated) {
    debugPrint('[DeepLink] Auth status updated: $isAuthenticated');
    _isAuthenticated = isAuthenticated;
  }

  /// Initialize deep link listeners
  /// Call this after the app has initialized
  Future<void> initialize({required bool isAuthenticated}) async {
    debugPrint('[DeepLink] ========================================');
    debugPrint('[DeepLink] INITIALIZING DEEP LINK SERVICE');
    debugPrint('[DeepLink] isAuthenticated: $isAuthenticated');
    debugPrint('[DeepLink] ========================================');

    _isAuthenticated = isAuthenticated;

    // Handle cold start - check if app was opened via deep link
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

    // Handle warm start - listen for incoming deep links
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

  /// Handle a deep link URL
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('[DeepLink] ----------------------------------------');
    debugPrint('[DeepLink] PROCESSING DEEP LINK');
    debugPrint('[DeepLink] URL: $uri');
    debugPrint('[DeepLink] isAuthenticated: $_isAuthenticated');

    // Security: Validate domain
    debugPrint('[DeepLink] Step 1: Validating domain...');
    if (!_isValidHost(uri.host)) {
      debugPrint('[DeepLink] ❌ INVALID HOST: ${uri.host}');
      debugPrint('[DeepLink] Allowed hosts: $_allowedHosts');
      debugPrint('[DeepLink] Link REJECTED for security');
      return;
    }
    debugPrint('[DeepLink] ✅ Domain validated: ${uri.host}');

    // Debouncing: Prevent multiple rapid navigations
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

    // Extract username from path: https://domain.com/username
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

    // Sanitize username for security
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
    // Handle based on authentication state
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

    // Navigate to profile if user is authenticated
    debugPrint('[DeepLink] Step 6: Navigating to profile...');
    _navigateToProfile(sanitizedUsername);
    debugPrint('[DeepLink] ----------------------------------------');
  }

  /// Navigate to user profile screen
  void _navigateToProfile(String username) {
    debugPrint('[DeepLink] ========================================');
    debugPrint('[DeepLink] 🚀 NAVIGATING TO PROFILE');
    debugPrint('[DeepLink] Username: $username');
    debugPrint('[DeepLink] Route: ${AppRoutes.userProfile}');
    _lastNavigationTime = DateTime.now();

    try {
      // Use NavigationService for reliable navigation with global key
      _navigationService.navigateTo(AppRoutes.userProfile, arguments: username);
      debugPrint('[DeepLink] ✅ Navigation initiated successfully');
    } catch (e, stackTrace) {
      debugPrint('[DeepLink] ❌ NAVIGATION FAILED: $e');
      debugPrint('[DeepLink] Stack trace: $stackTrace');
    }
    debugPrint('[DeepLink] ========================================');
  }

  /// Navigate to pending profile (called after successful login)
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

  /// Extract username from URI path
  String? _extractUsername(Uri uri) {
    // URL format: https://domain.com/username
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

  /// Sanitize username to prevent XSS/injection attacks
  String _sanitizeUsername(String username) {
    debugPrint('[DeepLink] Sanitizing username: "$username"');
    // Remove any HTML tags, special characters, whitespace
    // Allow only alphanumeric, underscore, hyphen, and dot
    final sanitized = username.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '');
    final trimmed = sanitized.trim();
    debugPrint('[DeepLink] After sanitization: "$trimmed"');
    if (username != trimmed) {
      debugPrint('[DeepLink] ⚠️ Username was modified during sanitization');
    }
    return trimmed;
  }

  /// Validate if the host is in the allowed list
  bool _isValidHost(String host) {
    final lowercaseHost = host.toLowerCase();
    final isValid = _allowedHosts.contains(lowercaseHost);
    debugPrint(
      '[DeepLink] Host validation: "$host" -> ${isValid ? "VALID" : "INVALID"}',
    );
    return isValid;
  }

  /// Check if we should debounce navigation
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

  /// Dispose the service and cancel subscriptions
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    debugPrint('[DeepLink] Deep link service disposed');
  }
}
