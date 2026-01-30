import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/models/feed_user.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/connections/screens/connections_screen.dart';
import '../../features/connections/screens/my_connections_screen.dart';
import '../../features/profile/screens/profile_viewers_screen.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';

import '../../features/splash/screens/splash_screen.dart';

import '../../features/franchise/screens/franchise_dashboard.dart';
import '../../features/franchise/screens/add_member_screen.dart';
import '../../features/franchise/screens/manage_member_screen.dart';
import '../../features/franchise/screens/member_profile_screen.dart';
import '../../features/franchise/screens/partner_preferences_screen.dart';
import '../../features/franchise/screens/franchise_payment_screen.dart';
import '../../features/franchise/screens/franchise_approval_screen.dart';
import '../../features/franchise/screens/franchise_login_screen.dart';
import '../../features/franchise/screens/franchise_profile_form_screen.dart';
import '../../features/franchise/providers/franchise_form_provider.dart';

import '../../features/vendor/screens/vendor_dashboard.dart';
import '../../features/vendor/screens/vendor_registration_screen.dart';
import '../../features/vendor/screens/vendor_payment_screen.dart';
import '../../features/vendor/screens/vendor_approval_screen.dart';
import '../../features/vendor/providers/vendor_provider.dart';

import '../../features/shop/screens/shop_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/providers/shop_provider.dart';
import '../../features/vendor/models/product_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String signInChoice = '/auth/login-choice';
  static const String loginChoice = '/login-choice';
  static const String franchiseLogin = '/franchise/login';
  static const String signUpChoice = '/auth/signup-choice';
  static const String signupChoice = '/signup-choice';
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
  static const String myConnections = '/connections/my';

  static const String franchiseDashboard = '/franchise/dashboard';
  static const String franchiseProfileForm = '/franchise/profile-form';
  static const String franchiseAddMember = '/franchise/add-member';
  static const String manageMember = '/franchise/manage-member';
  static const String memberProfile = '/franchise/member-profile';
  static const String partnerPreferences = '/franchise/partner-preferences';
  static const String franchisePayment = '/franchise/payment';
  static const String franchiseApproval = '/franchise/approval';
  static const String viewAsFeed = '/feed/view-as';

  static const String shop = '/shop';
  static const String productDetail = '/shop/product-detail';

  static const String vendorDashboard = '/vendor/dashboard';
  static const String vendorRegistration = '/vendor/registration';
  static const String vendorPayment = '/vendor/payment';
  static const String vendorApproval = '/vendor/approval';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    landing: (_) => const LandingScreen(),
    signInChoice: (_) => const LoginChoiceScreen(),
    loginChoice: (_) => const LoginChoiceScreen(),
    franchiseLogin: (_) => const FranchiseLoginScreen(),
    signUpChoice: (_) => const SignupChoiceScreen(),
    signupChoice: (_) => const SignupChoiceScreen(),
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
    myConnections: (_) => const MyConnectionsScreen(),
    editProfile: (_) => const EditProfileScreen(),
    photoManager: (_) => const PhotoManagerScreen(),
    userProfile: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[AppRoutes] userProfile route handler called');
      debugPrint('[AppRoutes] args type: ${args.runtimeType}');
      debugPrint('[AppRoutes] args value: $args');

      if (args is String) {
        debugPrint('[AppRoutes] ✅ String argument detected');
        debugPrint('[AppRoutes] username: $args');
        debugPrint('[AppRoutes] readOnly: false (default)');
        debugPrint('═══════════════════════════════════════════════════════');
        return UserProfileScreen(username: args);
      } else if (args is FeedUser) {
        debugPrint('[AppRoutes] ✅ FeedUser argument detected');
        debugPrint('[AppRoutes] username: ${args.username}');
        debugPrint('[AppRoutes] readOnly: false (default)');
        debugPrint('═══════════════════════════════════════════════════════');
        return UserProfileScreen(username: args.username);
      } else if (args is Map<String, dynamic>) {
        final username = args['username'] as String?;
        final readOnly = args['readOnly'] as bool? ?? false;
        debugPrint('[AppRoutes] ✅ Map argument detected');
        debugPrint('[AppRoutes] username: $username');
        debugPrint('[AppRoutes] readOnly: $readOnly');
        debugPrint('═══════════════════════════════════════════════════════');
        if (username != null) {
          return UserProfileScreen(username: username, readOnly: readOnly);
        }
      }
      debugPrint('[AppRoutes] ❌ ERROR: Invalid arguments');
      debugPrint('═══════════════════════════════════════════════════════');
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

    franchiseDashboard: (_) => const FranchiseDashboard(),
    franchiseProfileForm: (_) => const FranchiseProfileFormScreen(),
    franchiseAddMember: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      return ChangeNotifierProvider(
        create: (_) {
          final provider = FranchiseFormProvider();
          if (args is User) {
            provider.prepopulateFromUser(args);
          }
          return provider;
        },
        child: args is User
            ? AddMemberScreen(editUser: args)
            : const AddMemberScreen(),
      );
    },
    manageMember: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is User) {
        return ManageMemberScreen(member: args);
      }
      throw ArgumentError('User object required for manageMember route');
    },
    memberProfile: (_) => const MemberProfileScreen(),
    partnerPreferences: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        return const PartnerPreferencesScreen();
      }
      throw ArgumentError('Member ID required for partnerPreferences route');
    },
    franchisePayment: (_) => const FranchisePaymentScreen(),
    franchiseApproval: (_) => const FranchiseApprovalScreen(),
    viewAsFeed: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final viewAs = args?['viewAs'] as String?;
      final viewAsName = args?['viewAsName'] as String?;
      if (viewAs != null) {
        return FeedScreen(viewAsUserId: viewAs, viewAsUserName: viewAsName);
      }
      throw ArgumentError('viewAs argument required');
    },

    vendorDashboard: (context) {
      final apiService = context.read<ApiService>();
      return ChangeNotifierProvider(
        create: (_) => VendorProvider(apiService),
        child: const VendorDashboard(),
      );
    },
    vendorRegistration: (_) => const VendorRegistrationScreen(),
    vendorPayment: (_) => const VendorPaymentScreen(),
    vendorApproval: (_) => const VendorApprovalScreen(),

    shop: (context) {
      final apiService = context.read<ApiService>();
      return ChangeNotifierProvider(
        create: (_) => ShopProvider(apiService),
        child: const ShopScreen(),
      );
    },
    productDetail: (context) {
      final product = ModalRoute.of(context)?.settings.arguments as Product?;
      if (product != null) {
        return ProductDetailScreen(product: product);
      }
      throw ArgumentError('Product argument required for productDetail route');
    },
  };
}
