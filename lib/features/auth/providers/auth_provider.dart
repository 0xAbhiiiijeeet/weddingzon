import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/user_storage_service.dart';
import '../../../core/routes/app_routes.dart';
import '../repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final NavigationService _navService;

  User? _currentUser;
  bool _isLoading = false;
  bool _isCheckingAuth = false;
  bool isSignupFlow = false;

  AuthProvider(this._authRepository, this._navService);

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

  Future<void> checkAuthStatus() async {
    _setCheckingAuth(true);
    debugPrint('[AUTH] ========== CHECKING AUTH STATUS ==========');

    try {
      // First, try to load cached user
      final cachedUser = await UserStorageService.loadUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        debugPrint('[AUTH] Loaded cached user: ${cachedUser.email}');
      }

      // Then verify with server
      final response = await _authRepository.getCurrentUser();

      if (response.success && response.data != null) {
        // Server confirmed user is authenticated - update cached data
        _currentUser = response.data;
        await _saveUserLocally(_currentUser!);
        debugPrint('[AUTH] User verified by server');
        debugPrint('[AUTH] User: ${_currentUser?.email}');
        debugPrint(
          '[AUTH] Profile Complete: ${_currentUser?.isProfileComplete}',
        );
        _routeUserForLogin(_currentUser!);
      } else {
        // Server says no session (401) - but we have cached user
        debugPrint('[AUTH] Server says no active session: ${response.message}');

        // If we have a cached user with completed profile, USE THEM!
        // Don't clear - let user continue with cached data
        if (cachedUser != null && cachedUser.isProfileComplete) {
          debugPrint(
            '[AUTH] Using cached user (session expired but user has completed profile)',
          );
          _routeUserForLogin(cachedUser);
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
        _routeUserForLogin(_currentUser!);
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
        debugPrint('[AUTH] Google auth successful');
        debugPrint('[AUTH] User: ${_currentUser?.email}');
        debugPrint('[AUTH] Phone Verified: ${_currentUser?.isPhoneVerified}');
        debugPrint(
          '[AUTH] Profile Complete: ${_currentUser?.isProfileComplete}',
        );

        if (isSignup) {
          Fluttertoast.showToast(
            msg: "Step 1 complete! Now verify your phone number",
            backgroundColor: Colors.green,
          );
          _navService.pushNamedAndRemoveUntil(AppRoutes.mobileSignup);
        } else {
          // LOGIN: Route based on completion status
          _routeUserForLogin(_currentUser!);
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
          _navService.pushNamedAndRemoveUntil(AppRoutes.roleSelection);
        } else {
          // LOGIN: Route based on completion status
          _routeUserForLogin(_currentUser!);
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

  void _routeUserForLogin(User user) {
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
}
