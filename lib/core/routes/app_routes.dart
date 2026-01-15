import 'package:flutter/material.dart';

import '../../features/auth/screens/landing_screen.dart';
import '../../features/auth/screens/login_choice_screen.dart';
import '../../features/auth/screens/signup_choice_screen.dart';
import '../../features/auth/screens/google_login_screen.dart';
import '../../features/auth/screens/google_signup_screen.dart';
import '../../features/auth/screens/mobile_login_screen.dart';
import '../../features/auth/screens/mobile_signup_screen.dart';
import '../../features/auth/screens/login_otp_screen.dart';
import '../../features/auth/screens/signup_otp_screen.dart';
import '../../features/onboarding/screens/role_selection_screen.dart';
import '../../features/onboarding/screens/profile_form_screen.dart';
import '../../features/shell/screens/main_shell_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/photo_manager_screen.dart';
import '../../features/feed/screens/user_profile_screen.dart';
import '../../features/feed/models/feed_user.dart';

class AppRoutes {
  static const String landing = '/';
  static const String signInChoice = '/auth/login-choice';
  static const String signUpChoice = '/auth/signup-choice';
  static const String googleLogin = '/auth/google-login';
  static const String googleSignup = '/auth/google-signup';
  static const String mobileLogin = '/auth/mobile-login';
  static const String mobileSignup = '/auth/mobile-signup';
  static const String loginOtp = '/auth/login-otp';
  static const String signupOtp = '/auth/signup-otp';
  static const String roleSelection = '/onboarding/role';
  static const String profileForm = '/onboarding/profile';
  static const String feed = '/feed';
  static const String editProfile = '/profile/edit';
  static const String photoManager = '/profile/photos';
  static const String userProfile = '/profile/user';

  static Map<String, WidgetBuilder> get routes => {
    landing: (_) => const LandingScreen(),
    signInChoice: (_) => const LoginChoiceScreen(),
    signUpChoice: (_) => const SignupChoiceScreen(),
    googleLogin: (_) => const GoogleLoginScreen(),
    googleSignup: (_) => const GoogleSignupScreen(),
    mobileLogin: (_) => const MobileLoginScreen(),
    mobileSignup: (_) => const MobileSignupScreen(),
    loginOtp: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      return LoginOtpScreen(phoneNumber: args ?? '');
    },
    signupOtp: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      return SignupOtpScreen(phoneNumber: args ?? '');
    },
    roleSelection: (_) => const RoleSelectionScreen(),
    profileForm: (_) => const ProfileFormScreen(),
    feed: (_) => const MainShellScreen(),
    editProfile: (_) => const EditProfileScreen(),
    photoManager: (_) => const PhotoManagerScreen(),
    userProfile: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // Handle both FeedUser and Map<String, dynamic>
      if (args is FeedUser) {
        return UserProfileScreen(user: args);
      } else if (args is Map<String, dynamic>) {
        // Convert map to FeedUser
        final feedUser = FeedUser.fromJson(args);
        return UserProfileScreen(user: feedUser);
      }
      // Fallback - shouldn't happen
      throw ArgumentError('Invalid argument type for userProfile route');
    },
  };
}
