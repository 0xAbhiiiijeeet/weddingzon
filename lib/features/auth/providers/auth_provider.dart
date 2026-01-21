import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/user_storage_service.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/auth_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../notifications/repositories/notification_repository.dart';

import '../../../core/services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final NavigationService _navService;
  final SocketService _socketService;
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;

  User? _currentUser;
  bool _isLoading = false;
  bool _isCheckingAuth = false;
  bool isSignupFlow = false;

  AuthProvider(
    this._authRepository,
    this._navService,
    this._socketService,
    this._notificationService,
    this._notificationRepository,
  );

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
      // Network error - if we have cached user, use them
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

  Future<void> signInWithGoogle({required bool isSignup}) async {
    _setLoading(true);
    isSignupFlow = isSignup;

    debugPrint(
      '[AUTH] ========== GOOGLE ${isSignup ? 'SIGNUP' : 'LOGIN'} ==========',
    );

    try {
      final response = await _authRepository.googleLogin();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);

        // Register Notification Token
        await _registerNotificationToken();

        debugPrint('[AUTH] Google auth successful');
        debugPrint('[AUTH] User: ${_currentUser?.email}');
        debugPrint('[AUTH] Phone Verified: ${_currentUser?.isPhoneVerified}');
        debugPrint(
          '[AUTH] Profile Complete: ${_currentUser?.isProfileComplete}',
        );

        if (isSignup) {
          // SIGNUP: Check if profile is already complete
          if (_currentUser!.isProfileComplete) {
            debugPrint('[AUTH] Profile already complete, routing to FEED');
            Fluttertoast.showToast(
              msg: "Welcome back! Profile is complete.",
              backgroundColor: Colors.green,
            );
            _navService.pushNamedAndRemoveUntil(AppRoutes.feed);
          } else if (_currentUser!.phoneNumber != null &&
              _currentUser!.phoneNumber!.isNotEmpty) {
            // If mobile number exists, skip mobile signup and go to role selection (or next onboarding step)
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
          // LOGIN: Route based on completion status
          routeUser(_currentUser!);
        }
      } else {
        debugPrint('[AUTH] Google auth failed: ${response.message}');
        Fluttertoast.showToast(
          msg: response.message ?? 'Google sign-in failed',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('[AUTH] Exception: $e');
      Fluttertoast.showToast(
        msg: 'An error occurred during Google sign-in',
        backgroundColor: Colors.red,
      );
    }

    _setLoading(false);
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

        // Register Notification Token
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
          // SIGNUP: Check if profile is already complete
          if (_currentUser!.isProfileComplete) {
            debugPrint('[AUTH] Profile already complete, routing to FEED');
            _navService.pushNamedAndRemoveUntil(AppRoutes.feed);
          } else {
            debugPrint('[AUTH] Profile incomplete, routing to onboarding');
            _navService.pushNamedAndRemoveUntil(AppRoutes.roleSelection);
          }
        } else {
          // LOGIN: Route based on completion status
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
    debugPrint('[AUTH] =====================================');

    if (!user.isPhoneVerified) {
      debugPrint('[AUTH] Phone not verified, routing to phone auth');
      Fluttertoast.showToast(
        msg: 'Please verify your phone number',
        backgroundColor: Colors.orange,
      );
      _navService.pushNamedAndRemoveUntil(AppRoutes.mobileLogin);
    } else if (!user.isProfileComplete) {
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
    notifyListeners();
  }

  Future<void> logout() async {
    debugPrint('[AUTH] ========== LOGOUT ==========');

    try {
      // Disconnect socket BEFORE clearing user data
      _socketService.disconnect();
      debugPrint('[AUTH] Socket disconnected');

      // Unregister Notification Token
      await _unregisterNotificationToken();

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

  /// Refreshes the current user data from the server without triggering navigation
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

  void _logMissingFields(User user) {
    debugPrint('[AUTH] ========== PROFILE FIELD STATUS ==========');

    void check(String label, dynamic value, {required bool isRequired}) {
      final isEmpty = value == null || (value is String && value.isEmpty);
      if (isEmpty) {
        final status = isRequired ? '(REQUIRED)' : '(Optional)';
        debugPrint('[AUTH] [MISSING] $label $status');
      }
    }

    // Basic Details
    check('Date of Birth', user.dob, isRequired: true);
    check('Gender', user.gender, isRequired: true);
    check('Profile Created For', user.createdFor, isRequired: true);
    check('Height', user.height, isRequired: true);
    check('Marital Status', user.maritalStatus, isRequired: true);
    check('Mother Tongue', user.motherTongue, isRequired: true);
    check('Country', user.country, isRequired: true);
    check('State', user.state, isRequired: true);
    check('City', user.city, isRequired: true);

    // Family
    check('Father Status', user.fatherStatus, isRequired: true);
    check('Mother Status', user.motherStatus, isRequired: true);
    check('Family Status', user.familyStatus, isRequired: true);
    check('Family Type', user.familyType, isRequired: true);
    check('Family Values', user.familyValues, isRequired: true);

    // Education & Career
    check('Highest Education', user.highestEducation, isRequired: true);
    check('Occupation', user.occupation, isRequired: true);
    check('Employed In', user.employedIn, isRequired: true);
    check('Annual Income', user.personalIncome, isRequired: true);

    // Religion
    check('Religion', user.religion, isRequired: true);
    check('Community', user.community, isRequired: true);
    check('Sub-Community', user.subCommunity, isRequired: false);

    // Lifestyle
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
        await _notificationService
            .deleteToken(); // Optional: delete local token
        debugPrint('[AUTH] Notification token unregistered');
      }
    } catch (e) {
      debugPrint('[AUTH] Failed to unregister notification token: $e');
    }
  }
}
