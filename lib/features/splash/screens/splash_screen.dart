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

    // 1. Initialize Deep Link Service FIRST (before auth check)
    // This is critical for cold start - we need to detect the initial link
    // BEFORE any routing happens
    debugPrint('[SPLASH] Step 1: Initializing deep link service...');
    if (mounted) {
      // Initialize with isAuthenticated = false, we'll update it after auth check
      await deepLinkService.initialize(isAuthenticated: false);
      debugPrint('[SPLASH] Deep link service initialized');
    } else {
      debugPrint('[SPLASH] ⚠️ Widget not mounted, skipping deep link init');
      return;
    }

    // 2. Check Auth (Fast)
    debugPrint('[SPLASH] Step 2: Checking auth status...');
    await authProvider.checkAuthStatus(autoRoute: false);

    // 3. Update deep link service with actual auth status
    deepLinkService.updateAuthStatus(authProvider.isAuthenticated);

    if (authProvider.isAuthenticated) {
      debugPrint('[SPLASH] User is authenticated, preloading data...');

      // 3. Preload Data (Feed, etc.) - Fire and forget or wait partially
      // We want to use the remaining time effectively
      final feedProvider = context.read<FeedProvider>();

      // Start fetching feed
      feedProvider.loadFeed();

      // Calculate remaining time for splash
      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(seconds: 2);
      final remaining = minDuration - elapsed;

      if (remaining > Duration.zero) {
        // Wait for remainder of splash time OR feed load, whichever is longer?
        // No, we want to respect min splash time, but if feed takes longer,
        // we might minimally wait a bit more to show a smooth transition,
        // OR just navigate and let feed finish loading in background.
        // Let's just wait for the minimum time.
        await Future.delayed(remaining);
      }

      // Optional: If you want to ensure feed is loaded before showing it:
      // await feedFuture;
      // But that might make splash too long on slow networks.
      // Better to navigate and show skeleton/loading if needed.

      if (!mounted) return;
      debugPrint('[SPLASH] Routing to Feed...');
      authProvider.routeCurrentUser();

      // If there's a pending deep link, navigate to it after routing completes
      if (mounted && deepLinkService.pendingUsername != null) {
        debugPrint('[SPLASH] ✅ Pending deep link found!');
        debugPrint(
          '[SPLASH] Will navigate to: ${deepLinkService.pendingUsername}',
        );
        // Small delay to ensure navigation context is available
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
      // Not authenticated
      debugPrint('[SPLASH] User not authenticated');

      // Check if there's a pending deep link
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
            // Flutter Logo as requested
            const FlutterLogo(size: 100, style: FlutterLogoStyle.markOnly),
            const SizedBox(height: 24),
            // Optional: App Name or Loading Indicator
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
