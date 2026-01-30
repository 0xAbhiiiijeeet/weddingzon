import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../feed/screens/feed_screen.dart';
import '../../explore/screens/explore_screen.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../profile/screens/my_profile_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/provider/chat_provider.dart';
import '../../map/screens/map_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../../core/services/api_service.dart';
import '../../shop/providers/shop_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/badge_provider.dart';
import '../../connections/providers/connections_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../../shared/widgets/notification_badge.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with AutomaticKeepAliveClientMixin {
  late int _currentIndex;
  late PageController _pageController;
  DateTime? _lastBackPressTime;

  List<Widget> get _screens => [
    const FeedScreen(),
    const ExploreScreen(),
    const MapScreen(),
    ChangeNotifierProvider(
      create: (_) => ShopProvider(context.read<ApiService>()),
      child: const ShopScreen(),
    ),
    const ConversationsScreen(),
    const MyProfileScreen(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
      _initializeBadges();
    });
  }

  void _initializeBadges() {
    if (!mounted) return;
    context.read<ConnectionsProvider>().loadIncomingRequests();
    context.read<NotificationsProvider>().loadNotifications();
  }

  Future<void> _initializeChat() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final apiService = context.read<ApiService>();

    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      debugPrint('[SHELL] Initializing chat for user: ${currentUser.id}');
      chatProvider.setCurrentUserId(currentUser.id);

      final accessToken = await apiService.getAccessTokenFromCookies();

      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('[SHELL] Using real JWT token for socket authentication');
        debugPrint('[SHELL] Token preview: ${accessToken.substring(0, 20)}...');

        chatProvider.connectSocket(accessToken);
      } else {
        debugPrint(
          '[SHELL] WARNING: Could not extract access_token from cookies',
        );
        debugPrint('[SHELL] Attempting fallback with cookie string...');

        final cookieString = await apiService.getCookieString(
          AppConstants.socketUrl,
        );

        if (cookieString.isEmpty) {
          debugPrint(
            '[SHELL] CRITICAL: No auth credentials available for socket',
          );
        }

        chatProvider.connectSocket('cookie-auth', cookieString: cookieString);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (index == 4) {
      context.read<ChatProvider>().loadConversations();
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      Fluttertoast.showToast(
        msg: 'Press back again to exit',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });

            if (index == 4 && mounted) {
              context.read<ChatProvider>().loadConversations();
            }
          },
          children: _screens,
        ),
        bottomNavigationBar: Consumer<BadgeProvider>(
          builder: (context, badgeProvider, _) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Feed',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined),
                  activeIcon: Icon(Icons.shopping_bag),
                  label: 'Shop',
                ),
                BottomNavigationBarItem(
                  icon: NotificationBadge(
                    count: badgeProvider.chatBadgeCount,
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  activeIcon: NotificationBadge(
                    count: badgeProvider.chatBadgeCount,
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: 'Chat',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
