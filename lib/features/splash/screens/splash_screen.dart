import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/deep_link_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    final startTime = DateTime.now();
    final authProvider = context.read<AuthProvider>();
    final deepLinkService = context.read<DeepLinkService>();

    debugPrint('[SPLASH] Step 1: Initializing deep link service...');
    if (mounted) {
      await deepLinkService.initialize(isAuthenticated: false);
      debugPrint('[SPLASH] Deep link service initialized');
    } else {
      debugPrint('[SPLASH] ⚠️ Widget not mounted, skipping deep link init');
      return;
    }

    debugPrint('[SPLASH] Step 2: Checking auth status...');
    await authProvider.checkAuthStatus(autoRoute: false);

    deepLinkService.updateAuthStatus(authProvider.isAuthenticated);

    if (authProvider.isAuthenticated) {
      debugPrint('[SPLASH] User is authenticated, preloading data...');

      final feedProvider = context.read<FeedProvider>();

      feedProvider.loadFeed();

      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(seconds: 2);
      final remaining = minDuration - elapsed;

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }


      if (!mounted) return;
      debugPrint('[SPLASH] Routing to Feed...');
      authProvider.routeCurrentUser();

      if (mounted && deepLinkService.pendingUsername != null) {
        debugPrint('[SPLASH] ✅ Pending deep link found!');
        debugPrint(
          '[SPLASH] Will navigate to: ${deepLinkService.pendingUsername}',
        );
        debugPrint('[SPLASH] Waiting 500ms for navigation context...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint('[SPLASH] Navigating to pending profile...');
          deepLinkService.navigateToPendingProfile();
        } else {
          debugPrint(
            '[SPLASH] ⚠️ Widget unmounted, cannot navigate to pending profile',
          );
        }
      } else {
        debugPrint('[SPLASH] ℹ️ No pending deep link');
      }
    } else {
      debugPrint('[SPLASH] User not authenticated');

      if (deepLinkService.pendingUsername != null) {
        debugPrint('[SPLASH] ⚠️ Deep link detected but user not authenticated');
        debugPrint(
          '[SPLASH] Pending username stored: ${deepLinkService.pendingUsername}',
        );
        debugPrint('[SPLASH] User will be prompted to login');
      }

      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(seconds: 2);
      final remaining = minDuration - elapsed;

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (!mounted) return;
      debugPrint('[SPLASH] Routing to Landing page');
      Navigator.pushReplacementNamed(context, AppRoutes.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100, style: FlutterLogoStyle.markOnly),
            const SizedBox(height: 24),
            Text(
              'WeddingZon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}