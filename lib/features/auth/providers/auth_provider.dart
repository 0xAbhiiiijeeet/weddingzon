import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/user_storage_service.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/auth_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../notifications/repositories/notification_repository.dart';

import '../../../core/services/socket_service.dart';
import '../../../core/services/deep_link_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final NavigationService _navService;
  final SocketService _socketService;
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;
  final DeepLinkService? _deepLinkService;

  User? _currentUser;
  bool _isLoading = false;
  bool _isCheckingAuth = false;
  bool isSignupFlow = false;

  AuthProvider(
    this._authRepository,
    this._navService,
    this._socketService,
    this._notificationService,
    this._notificationRepository, {
    DeepLinkService? deepLinkService,
  }) : _deepLinkService = deepLinkService;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setCheckingAuth(bool value) {
    _isCheckingAuth = value;
    notifyListeners();
  }

  Future<void> checkAuthStatus({bool autoRoute = true}) async {
    _setCheckingAuth(true);
    debugPrint('[AUTH] ========== CHECKING AUTH STATUS ==========');

    try {
      final cachedUser = await UserStorageService.loadUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        debugPrint('[AUTH] Loaded cached user: ${cachedUser.email}');
      }

      final response = await _authRepository.getCurrentUser();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);
        debugPrint('[AUTH] User verified by server');

        await _registerNotificationToken();

        debugPrint('[AUTH] User: ${_currentUser?.email}');
        debugPrint(
          '[AUTH] PROFILE COMPLETE: ${_currentUser?.isProfileComplete}',
        );
        if (autoRoute) {
          routeUser(_currentUser!);
        }
      } else {
        debugPrint('[AUTH] Server says no active session: ${response.message}');

        if (cachedUser != null && cachedUser.isProfileComplete) {
          debugPrint(
            '[AUTH] Using cached user (session expired but user has completed profile)',
          );
          if (autoRoute) {
            routeUser(cachedUser);
          }
        } else if (cachedUser != null) {
          debugPrint(
            '[AUTH] Cached user has incomplete profile - need to re-auth',
          );
          await UserStorageService.clearUser();
          _currentUser = null;
        } else {
          _currentUser = null;
        }
      }
    } catch (e) {
      debugPrint('[AUTH] Auth check error (likely network): $e');
      if (_currentUser != null) {
        debugPrint('[AUTH] Using cached user due to network error');
        if (autoRoute) {
          routeUser(_currentUser!);
        }
        _setCheckingAuth(false);
        return;
      }
    }

    _setCheckingAuth(false);
  }

  Future<void> signInWithGoogle({
    required bool isSignup,
    int retryCount = 0,
  }) async {
    _setLoading(true);
    isSignupFlow = isSignup;

    debugPrint(
      '[AUTH] ========== GOOGLE ${isSignup ? 'SIGNUP' : 'LOGIN'} (Attempt ${retryCount + 1}) ==========',
    );

    try {
      final response = await _authRepository.googleLogin();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);

        await _registerNotificationToken();

        debugPrint('[AUTH] Google auth successful');
        debugPrint('[AUTH] User: ${_currentUser?.email}');
        debugPrint('[AUTH] Phone Verified: ${_currentUser?.isPhoneVerified}');
        debugPrint(
          '[AUTH] Profile Complete: ${_currentUser?.isProfileComplete}',
        );

        if (isSignup) {
          if (_currentUser!.isProfileComplete) {
            debugPrint('[AUTH] Profile already complete, routing to FEED');
            Fluttertoast.showToast(
              msg: "Welcome back! Profile is complete.",
              backgroundColor: Colors.green,
            );
            _navService.pushNamedAndRemoveUntil(AppRoutes.feed);

            if (_deepLinkService?.pendingUsername != null) {
              debugPrint(
                '[AUTH] Found pending deep link: ${_deepLinkService!.pendingUsername}',
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                _deepLinkService.navigateToPendingProfile();
              });
            }
          } else if (_currentUser!.phoneNumber != null &&
              _currentUser!.phoneNumber!.isNotEmpty) {
            debugPrint(
              '[AUTH] Mobile number exists, treating as login (skipping mobile setup)',
            );
            _navService.pushNamedAndRemoveUntil(AppRoutes.roleSelection);
          } else {
            Fluttertoast.showToast(
              msg: "Step 1 complete! Now verify your phone number",
              backgroundColor: Colors.green,
            );
            _navService.pushNamedAndRemoveUntil(AppRoutes.mobileSignup);
          }
        } else {
          routeUser(_currentUser!);
        }
      } else {
        debugPrint('[AUTH] Google auth failed: ${response.message}');
        _handleGoogleSignInError(response.message, isSignup, retryCount);
      }
    } catch (e) {
      debugPrint('[AUTH] Exception: $e');
      final errorString = e.toString().toLowerCase();

      // Check if it's a network error
      if (errorString.contains('network_error') ||
          errorString.contains('apiexception: 7') ||
          errorString.contains('network') ||
          errorString.contains('connection')) {
        debugPrint('[AUTH] Network error detected - will retry');
        _handleNetworkError(isSignup, retryCount);
      } else {
        Fluttertoast.showToast(
          msg: 'An error occurred during Google sign-in. Please try again.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }

    _setLoading(false);
  }

  void _handleGoogleSignInError(
    String? message,
    bool isSignup,
    int retryCount,
  ) {
    if (message != null &&
        (message.contains('network') || message.contains('connection'))) {
      _handleNetworkError(isSignup, retryCount);
    } else {
      Fluttertoast.showToast(
        msg: message ?? 'Google sign-in failed',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _handleNetworkError(bool isSignup, int retryCount) {
    if (retryCount < 2) {
      // Allow up to 3 attempts (0, 1, 2)
      Fluttertoast.showToast(
        msg: 'Network error. Retrying... (${retryCount + 1}/3)',
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_SHORT,
      );

      // Retry after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        signInWithGoogle(isSignup: isSignup, retryCount: retryCount + 1);
      });
    } else {
      // Max retries reached
      Fluttertoast.showToast(
        msg:
            'Network error. Please check your internet connection and try again.',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  String? _error;

  String? get error => _error;
  User? get user => _currentUser;

  Future<bool> loginWithPassword(String username, String password) async {
    _setLoading(true);
    _error = null;
    debugPrint('[AUTH] ========== PASSWORD LOGIN ==========');
    debugPrint('[AUTH] 🔵 Attempting login for username: $username');

    try {
      final response = await _authRepository.loginWithPassword(
        username,
        password,
      );

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);

        await _registerNotificationToken();

        debugPrint('[AUTH] ✅ Login successful');
        debugPrint('[AUTH] 👤 User: ${_currentUser?.email}');
        debugPrint('[AUTH] 🎭 Role: ${_currentUser?.role}');

        Fluttertoast.showToast(
          msg: "Login successful",
          backgroundColor: Colors.green,
        );

        routeUser(_currentUser!);
        _setLoading(false);
        return true;
      } else {
        _error = response.message ?? "Login failed";
        debugPrint('[AUTH] ❌ Login failed: $_error');
        Fluttertoast.showToast(msg: _error!, backgroundColor: Colors.red);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = "An error occurred during login";
      debugPrint('[AUTH] ❌ Login Exception: $e');
      Fluttertoast.showToast(msg: _error!, backgroundColor: Colors.red);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    debugPrint('[AUTH] ========== SEND OTP ==========');
    debugPrint('[AUTH] Phone: $phoneNumber');

    try {
      final response = await _authRepository.sendOtp(phoneNumber);

      if (response.success) {
        debugPrint('[AUTH] OTP sent');
        Fluttertoast.showToast(
          msg: response.message ?? 'OTP sent successfully',
          backgroundColor: Colors.green,
        );
        _setLoading(false);
        return true;
      } else {
        debugPrint('[AUTH] Send OTP failed: ${response.message}');
        Fluttertoast.showToast(
          msg: response.message ?? 'Failed to send OTP',
          backgroundColor: Colors.red,
        );
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('[AUTH] Exception: $e');
      Fluttertoast.showToast(
        msg: 'An error occurred',
        backgroundColor: Colors.red,
      );
      _setLoading(false);
      return false;
    }
  }

  Future<void> verifyOtp(
    String phoneNumber,
    String otp, {
    required bool isSignup,
  }) async {
    _setLoading(true);
    isSignupFlow = isSignup;

    debugPrint('[AUTH] ========== VERIFY OTP ==========');
    debugPrint('[AUTH] Phone: $phoneNumber');
    debugPrint('[AUTH] Is Signup: $isSignup');

    try {
      final response = await _authRepository.verifyOtp(phoneNumber, otp);

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);

        await _registerNotificationToken();

        debugPrint('[AUTH] OTP verified');
        debugPrint(
          '[AUTH] User: ${_currentUser?.email ?? _currentUser?.phoneNumber}',
        );
        debugPrint(
          '[AUTH] Profile Complete: ${_currentUser?.isProfileComplete}',
        );

        Fluttertoast.showToast(
          msg: 'Phone verified successfully!',
          backgroundColor: Colors.green,
        );

        if (isSignup) {
          if (_currentUser!.isProfileComplete) {
            debugPrint('[AUTH] Profile already complete, routing to FEED');
            _navService.pushNamedAndRemoveUntil(AppRoutes.feed);

            if (_deepLinkService?.pendingUsername != null) {
              debugPrint(
                '[AUTH] Found pending deep link: ${_deepLinkService!.pendingUsername}',
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                _deepLinkService.navigateToPendingProfile();
              });
            }
          } else {
            debugPrint('[AUTH] Profile incomplete, routing to onboarding');
            _navService.pushNamedAndRemoveUntil(AppRoutes.roleSelection);
          }
        } else {
          routeUser(_currentUser!);
        }
      } else {
        debugPrint('[AUTH] OTP verification failed: ${response.message}');
        Fluttertoast.showToast(
          msg: response.message ?? 'Invalid OTP',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('[AUTH] Exception: $e');
      Fluttertoast.showToast(
        msg: 'An error occurred',
        backgroundColor: Colors.red,
      );
    }

    _setLoading(false);
  }

  void routeCurrentUser() {
    if (_currentUser != null) {
      routeUser(_currentUser!);
    } else {
      _navService.pushNamedAndRemoveUntil(AppRoutes.landing);
    }
  }

  void routeUser(User user) {
    debugPrint('[AUTH] ========== ROUTING USER (LOGIN) ==========');
    debugPrint('[AUTH] User ID: ${user.id}');
    debugPrint('[AUTH] Email: ${user.email}');
    debugPrint('[AUTH] Phone: ${user.phoneNumber}');
    debugPrint('[AUTH] Role: ${user.role}');
    debugPrint('[AUTH] isPhoneVerified: ${user.isPhoneVerified}');
    debugPrint('[AUTH] isProfileComplete: ${user.isProfileComplete}');
    debugPrint('[AUTH] Franchise Status: ${user.franchiseStatus}');
    debugPrint('[AUTH] Franchise Details: ${user.franchiseDetails}');
    debugPrint('[AUTH] Vendor Status: ${user.vendorStatus}');
    debugPrint('[AUTH] Vendor Details: ${user.vendorDetails}');
    debugPrint('[AUTH] =====================================');

    if (user.role == 'franchise') {
      debugPrint('[AUTH] User is Franchise Owner, checking status...');

      // Check if franchise details are filled
      if (user.franchiseDetails == null || user.franchiseDetails!.isEmpty) {
        debugPrint('[AUTH] Franchise details not filled → Profile Form Screen');
        Fluttertoast.showToast(
          msg: 'Please complete your franchise profile',
          backgroundColor: Colors.orange,
        );
        _navService.pushNamedAndRemoveUntil(AppRoutes.franchiseProfileForm);
        return;
      }

      // Check franchise status
      switch (user.franchiseStatus) {
        case 'pending_payment':
          debugPrint('[AUTH] Status: pending_payment → Payment Screen');
          Fluttertoast.showToast(
            msg: 'Please complete the activation payment',
            backgroundColor: Colors.orange,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.franchisePayment);
          return;

        case 'pending_approval':
          debugPrint('[AUTH] Status: pending_approval → Approval Screen');
          Fluttertoast.showToast(
            msg: 'Your franchise application is under review',
            backgroundColor: Colors.blue,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.franchiseApproval);
          return;

        case 'rejected':
          debugPrint('[AUTH] Status: rejected → Show error');
          Fluttertoast.showToast(
            msg:
                'Your franchise application was rejected. Please contact support.',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.landing);
          return;

        case 'active':
          debugPrint('[AUTH] Status: active → Dashboard');
          _navService.pushNamedAndRemoveUntil(AppRoutes.franchiseDashboard);
          return;

        default:
          debugPrint(
            '[AUTH] Status: ${user.franchiseStatus ?? "null"} → Profile Form (no status set)',
          );
          Fluttertoast.showToast(
            msg: 'Please complete your franchise registration',
            backgroundColor: Colors.orange,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.franchiseProfileForm);
          return;
      }
    }

    // ==================== VENDOR ROLE HANDLING ====================
    if (user.role == 'vendor') {
      debugPrint('[AUTH] User is Vendor, checking status...');

      // Check if vendor details are filled
      if (user.vendorDetails == null || user.vendorDetails!.isEmpty) {
        debugPrint(
          '[AUTH] Vendor details not filled → Vendor Registration Screen',
        );
        Fluttertoast.showToast(
          msg: 'Please complete your vendor registration',
          backgroundColor: Colors.orange,
        );
        _navService.pushNamedAndRemoveUntil(AppRoutes.vendorRegistration);
        return;
      }

      // Check vendor status
      switch (user.vendorStatus) {
        case 'pending_payment':
          debugPrint('[AUTH] Status: pending_payment → Payment Screen');
          Fluttertoast.showToast(
            msg: 'Please complete the activation payment',
            backgroundColor: Colors.orange,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.vendorPayment);
          return;

        case 'pending_approval':
          debugPrint('[AUTH] Status: pending_approval → Approval Screen');
          Fluttertoast.showToast(
            msg: 'Your vendor application is under review',
            backgroundColor: Colors.blue,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.vendorApproval);
          return;

        case 'rejected':
          debugPrint('[AUTH] Status: rejected → Show error');
          Fluttertoast.showToast(
            msg:
                'Your vendor application was rejected. Please contact support.',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.landing);
          return;

        case 'active':
          debugPrint('[AUTH] Status: active → Vendor Dashboard');
          _navService.pushNamedAndRemoveUntil(AppRoutes.vendorDashboard);
          return;

        default:
          debugPrint(
            '[AUTH] Status: ${user.vendorStatus ?? "null"} → Vendor Registration (no status set)',
          );
          Fluttertoast.showToast(
            msg: 'Please complete your vendor registration',
            backgroundColor: Colors.orange,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.vendorRegistration);
          return;
      }
    }
    // ============================================================

    if (user.role == 'member') {
      debugPrint('[AUTH] User is Franchise Member, routing directly to Feed');
      _navService.pushNamedAndRemoveUntil(AppRoutes.feed);
      return;
    }

    if (!user.isPhoneVerified) {
      debugPrint('[AUTH] Phone not verified, routing to phone auth');
      Fluttertoast.showToast(
        msg: 'Please verify your phone number',
        backgroundColor: Colors.orange,
      );
      _navService.pushNamedAndRemoveUntil(AppRoutes.mobileLogin);
      return;
    }

    if (!user.isProfileComplete) {
      debugPrint('[AUTH] Profile incomplete, routing to role selection');
      Fluttertoast.showToast(
        msg: 'Please complete your profile',
        backgroundColor: Colors.orange,
      );
      _navService.pushNamedAndRemoveUntil(AppRoutes.roleSelection);
      _logMissingFields(user);
    } else {
      debugPrint('[AUTH] Profile complete, routing to FEED');

      _navService.pushNamedAndRemoveUntil(AppRoutes.feed);

      if (_deepLinkService?.pendingUsername != null) {
        debugPrint(
          '[AUTH] Found pending deep link: ${_deepLinkService!.pendingUsername}',
        );
        debugPrint('[AUTH] Will navigate to profile after feed loads');

        Future.delayed(const Duration(milliseconds: 500), () {
          _deepLinkService.navigateToPendingProfile();
        });
      }
    }
  }

  Future<void> _saveUserLocally(User user) async {
    await UserStorageService.saveUser(user);
  }

  void updateUser(User user) {
    debugPrint('[AUTH] ========== UPDATING USER DATA ==========');
    _currentUser = user;
    _saveUserLocally(user);
    debugPrint('[AUTH] Profile Complete: ${user.isProfileComplete}');

    if (_deepLinkService != null) {
      _deepLinkService.updateAuthStatus(true);
      debugPrint('[AUTH] Updated deep link service: user is authenticated');
    }

    notifyListeners();
  }

  Future<void> logout() async {
    debugPrint('[AUTH] ========== LOGOUT ==========');

    try {
      _socketService.disconnect();
      debugPrint('[AUTH] Socket disconnected');

      await _unregisterNotificationToken();

      if (_deepLinkService != null) {
        _deepLinkService.updateAuthStatus(false);
        _deepLinkService.clearPendingUsername();
        debugPrint('[AUTH] Updated deep link service: user is logged out');
      }

      await _authRepository.logout();
      await UserStorageService.clearUser();
      _currentUser = null;
      isSignupFlow = false;

      Fluttertoast.showToast(
        msg: 'Logged out successfully',
        backgroundColor: Colors.green,
      );

      _navService.pushNamedAndRemoveUntil(AppRoutes.landing);
      notifyListeners();

      debugPrint('[AUTH] Logout complete');
    } catch (e) {
      debugPrint('[AUTH] Logout error: $e');
      Fluttertoast.showToast(msg: 'Logout failed', backgroundColor: Colors.red);
    }
  }

  Future<void> refreshUser() async {
    debugPrint('[AUTH] ========== REFRESH USER (NO NAV) ==========');
    try {
      final response = await _authRepository.getCurrentUser();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);
        notifyListeners();
        debugPrint('[AUTH] User refreshed successfully');
      } else {
        debugPrint('[AUTH] Refresh failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('[AUTH] Refresh error: $e');
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    return await _authRepository.getCurrentUser();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _authRepository.updateProfile(data);
      if (response.success && response.data != null) {
        updateUser(response.data!);
        _setLoading(false);
        return true;
      } else {
        Fluttertoast.showToast(msg: response.message ?? 'Update failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('[AUTH] Update profile error: $e');
      _setLoading(false);
      return false;
    }
  }

  void _logMissingFields(User user) {
    debugPrint('[AUTH] ========== PROFILE FIELD STATUS ==========');

    void check(String label, dynamic value, {required bool isRequired}) {
      final isEmpty = value == null || (value is String && value.isEmpty);
      if (isEmpty) {
        final status = isRequired ? '(REQUIRED)' : '(Optional)';
        debugPrint('[AUTH] [MISSING] $label $status');
      }
    }

    check('Date of Birth', user.dob, isRequired: true);
    check('Gender', user.gender, isRequired: true);
    check('Profile Created For', user.createdFor, isRequired: true);
    check('Height', user.height, isRequired: true);
    check('Marital Status', user.maritalStatus, isRequired: true);
    check('Mother Tongue', user.motherTongue, isRequired: true);
    check('Country', user.country, isRequired: true);
    check('State', user.state, isRequired: true);
    check('City', user.city, isRequired: true);

    check('Father Status', user.fatherStatus, isRequired: true);
    check('Mother Status', user.motherStatus, isRequired: true);
    check('Family Status', user.familyStatus, isRequired: true);
    check('Family Type', user.familyType, isRequired: true);
    check('Family Values', user.familyValues, isRequired: true);

    check('Highest Education', user.highestEducation, isRequired: true);
    check('Occupation', user.occupation, isRequired: true);
    check('Employed In', user.employedIn, isRequired: true);
    check('Annual Income', user.personalIncome, isRequired: true);

    check('Religion', user.religion, isRequired: true);
    check('Community', user.community, isRequired: true);
    check('Sub-Community', user.subCommunity, isRequired: false);

    check('Appearance', user.appearance, isRequired: true);
    check('Living Status', user.livingStatus, isRequired: true);
    check('Eating Habits', user.eatingHabits, isRequired: true);
    check('Smoking', user.smokingHabits, isRequired: false);
    check('Drinking', user.drinkingHabits, isRequired: false);

    debugPrint('[AUTH] ==========================================');
  }

  Future<void> _registerNotificationToken() async {
    try {
      final token = await _notificationService.getToken();
      if (token != null) {
        await _notificationRepository.registerToken(token);
        debugPrint('[AUTH] Notification token registered');
      }
    } catch (e) {
      debugPrint('[AUTH] Failed to register notification token: $e');
    }
  }

  Future<void> _unregisterNotificationToken() async {
    try {
      final token = await _notificationService.getToken();
      if (token != null) {
        await _notificationRepository.unregisterToken(token);
        await _notificationService.deleteToken();
        debugPrint('[AUTH] Notification token unregistered');
      }
    } catch (e) {
      debugPrint('[AUTH] Failed to unregister notification token: $e');
    }
  }
}
