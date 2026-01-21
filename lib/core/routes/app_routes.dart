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
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/connections/screens/connections_screen.dart';
import '../../features/profile/screens/profile_viewers_screen.dart';

import '../../features/splash/screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
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
  static const String explore = '/explore';
  static const String chatTab = '/chat-tab';
  static const String profileTab = '/profile-tab';
  static const String editProfile = '/profile/edit';
  static const String photoManager = '/profile/photos';
  static const String userProfile = '/profile/user';
  static const String profileViewers = '/profile/viewers';
  static const String conversations = '/chat/conversations';
  static const String chat = '/chat';
  static const String connections = '/connections';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
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
    feed: (_) => const MainShellScreen(initialIndex: 0),
    explore: (_) => const MainShellScreen(initialIndex: 1),
    chatTab: (_) => const MainShellScreen(initialIndex: 3),
    profileTab: (_) => const MainShellScreen(initialIndex: 4),
    connections: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ConnectionsScreen(initialIndex: args?['initialIndex'] ?? 0);
    },
    editProfile: (_) => const EditProfileScreen(),
    photoManager: (_) => const PhotoManagerScreen(),
    userProfile: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // Handle username string (preferred), FeedUser, or Map
      if (args is String) {
        return UserProfileScreen(username: args);
      } else if (args is FeedUser) {
        return UserProfileScreen(username: args.username);
      } else if (args is Map<String, dynamic>) {
        final username = args['username'] as String?;
        if (username != null) {
          return UserProfileScreen(username: username);
        }
      }
      throw ArgumentError('Username required for userProfile route');
    },
    profileViewers: (_) => const ProfileViewersScreen(),
    conversations: (_) => const ConversationsScreen(),
    chat: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        return ChatScreen(
          userId: args['userId'] as String,
          username: args['username'] as String,
          firstName: args['firstName'] as String?,
          lastName: args['lastName'] as String?,
          profilePhoto: args['profilePhoto'] as String?,
        );
      }
      throw ArgumentError('Chat arguments required');
    },
  };
}
