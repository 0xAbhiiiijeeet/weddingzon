import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../feed/screens/feed_screen.dart';
import '../../explore/screens/explore_screen.dart';
import '../../chat/screens/conversations_screen.dart';
import '../../profile/screens/my_profile_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/provider/chat_provider.dart';
import '../../../core/services/api_service.dart';

import '../../../core/constants/app_constants.dart';

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

  final List<Widget> _screens = [
    const FeedScreen(),
    const ExploreScreen(),
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

    // Connect socket for chat after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final apiService = context.read<ApiService>();

    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      debugPrint('[SHELL] Initializing chat for user: ${currentUser.id}');
      chatProvider.setCurrentUserId(currentUser.id);

      // Extract the real JWT token from cookies
      final accessToken = await apiService.getAccessTokenFromCookies();

      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('[SHELL] Using real JWT token for socket authentication');
        debugPrint('[SHELL] Token preview: ${accessToken.substring(0, 20)}...');

        // Connect with the real JWT token
        chatProvider.connectSocket(accessToken);
      } else {
        // Fallback: Try cookie-based auth (though backend requires token)
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

        // Use fallback (likely to fail based on API requirements)
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
      return false; // Don't exit
    }
    return true; // Exit app
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
          },
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
