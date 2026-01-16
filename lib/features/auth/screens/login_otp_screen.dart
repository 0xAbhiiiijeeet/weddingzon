import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/custom_button.dart';

class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const LoginOtpScreen({super.key, required this.phoneNumber});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify Login',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit OTP sent to ${widget.phoneNumber}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '------',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Verify & Sign In',
                  isLoading: auth.isLoading,
                  onPressed: () {
                    if (_otpController.text.length == 6) {
                      auth.verifyOtp(
                        widget.phoneNumber,
                        _otpController.text,
                        isSignup: false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a 6-digit OTP'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => auth.sendOtp(widget.phoneNumber),
                    child: const Text('Resend OTP'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
