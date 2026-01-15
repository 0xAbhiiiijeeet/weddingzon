import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isCheckingAuth) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding
                  const FlutterLogo(size: 80),
                  const SizedBox(height: 32),
                  const Text(
                    'WeddingZon',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Begin your journey to a beautiful union',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 60),

                  // Action Buttons
                  CustomButton(
                    text: 'Create Account',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.signUpChoice),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Sign In',
                    isOutlined: true,
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.signInChoice),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
