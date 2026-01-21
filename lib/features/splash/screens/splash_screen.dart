import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../../../core/routes/app_routes.dart';

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

    // 1. Check Auth (Fast)
    await authProvider.checkAuthStatus(autoRoute: false);

    if (authProvider.isAuthenticated) {
      debugPrint('[SPLASH] User is authenticated, preloading data...');

      // 2. Preload Data (Feed, etc.) - Fire and forget or wait partially
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
    } else {
      // Not authenticated
      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(seconds: 2);
      final remaining = minDuration - elapsed;

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (!mounted) return;
      debugPrint('[SPLASH] User not authenticated, going to Landing');
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
