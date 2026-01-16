import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/custom_button.dart';

class SignInOptionScreen extends StatelessWidget {
  const SignInOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to continue to your account',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Sign In with Google',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.googleLogin),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Sign In with Phone',
                isOutlined: true,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.mobileLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
