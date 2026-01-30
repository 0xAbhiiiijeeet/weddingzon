import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/custom_button.dart';

class MobileSignupScreen extends StatefulWidget {
  const MobileSignupScreen({super.key});

  @override
  State<MobileSignupScreen> createState() => _MobileSignupScreenState();
}

class _MobileSignupScreenState extends State<MobileSignupScreen> {
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign up with Google first'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signUpChoice,
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Mobile'),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Step 1 Complete',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Signed in as ${auth.currentUser?.email ?? ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Verify Your Mobile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your mobile number to complete account setup',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                    helperText: 'This will be used for account verification',
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Send OTP',
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (_phoneController.text.length == 10) {
                      final phoneNumber = '+91${_phoneController.text}';
                      final success = await auth.sendOtp(phoneNumber);
                      if (!mounted) return;
                      if (success) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.signupOtp,
                          arguments: phoneNumber,
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid 10-digit number'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}