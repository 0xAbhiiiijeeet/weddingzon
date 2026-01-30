import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/custom_button.dart';

class LoginChoiceScreen extends StatelessWidget {
  const LoginChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select how you would like to sign in',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Sign In with Google',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.googleLogin),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Sign In with Mobile',
              isOutlined: true,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.mobileLogin),
            ),
            const SizedBox(height: 16),

            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.signUpChoice,
                ),
                child: const Text("Don't have an account? Create one"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}