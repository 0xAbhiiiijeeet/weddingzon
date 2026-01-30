import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/routes/app_routes.dart';

class FranchisePaymentScreen extends StatefulWidget {
  const FranchisePaymentScreen({super.key});

  @override
  State<FranchisePaymentScreen> createState() => _FranchisePaymentScreenState();
}

class _FranchisePaymentScreenState extends State<FranchisePaymentScreen> {
  bool _isProcessing = false;

  void _processPayment() async {
    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║ [PAYMENT] 💳 PAY NOW CLICKED                               ║',
    );
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );

    setState(() => _isProcessing = true);
    debugPrint('[PAYMENT] ⏳ Processing payment...');

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('[PAYMENT] ✅ Payment simulation complete');

    if (!mounted) {
      debugPrint('[PAYMENT] ⚠️ Widget unmounted during payment');
      return;
    }

    final franchiseProvider = Provider.of<FranchiseProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('[PAYMENT] ========================================');
    debugPrint('[PAYMENT] 📤 Submitting payment to backend...');
    debugPrint('[PAYMENT] 📍 Endpoint: POST /api/franchise/payment');

    final success = await franchiseProvider.submitPayment();

    debugPrint('[PAYMENT] ========================================');
    debugPrint(
      '[PAYMENT] 📥 Status update response: ${success ? 'SUCCESS' : 'FAILED'}',
    );

    if (success) {
      debugPrint('[PAYMENT] ✅ Approval request sent successfully!');
      debugPrint('[PAYMENT] 🔄 Refreshing user data from backend...');

      // Refresh user data to get updated franchise status
      await authProvider.refreshUser();

      debugPrint('[PAYMENT] 📊 Current user status:');
      final user = authProvider.currentUser;
      if (user != null) {
        debugPrint('[PAYMENT]   - ID: ${user.id}');
        debugPrint('[PAYMENT]   - franchise_status: ${user.franchiseStatus}');
        debugPrint('[PAYMENT]   - franchise_details: ${user.franchiseDetails}');
      } else {
        debugPrint('[PAYMENT]   - User is NULL');
      }

      if (!mounted) {
        debugPrint('[PAYMENT] ⚠️ Widget unmounted after refresh');
        return;
      }

      debugPrint('[PAYMENT] ========================================');
      debugPrint('[PAYMENT] 🚀 Navigating to Approval Screen...');
      debugPrint('[PAYMENT] 📍 Target Route: ${AppRoutes.franchiseApproval}');

      Navigator.pushReplacementNamed(context, AppRoutes.franchiseApproval);

      debugPrint('[PAYMENT] ✅ Navigation complete');
      debugPrint(
        '[PAYMENT] ℹ️ User will wait for admin approval on next screen',
      );
      debugPrint('[PAYMENT] ========================================');
    } else {
      setState(() => _isProcessing = false);

      debugPrint('[PAYMENT] ========================================');
      debugPrint('[PAYMENT] ❌ Failed to send approval request');
      debugPrint('[PAYMENT] 🔴 Error: ${franchiseProvider.error}');
      debugPrint('[PAYMENT] ========================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            franchiseProvider.error.isNotEmpty
                ? franchiseProvider.error
                : 'Payment verification failed. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );
    debugPrint('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Franchise Activation')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Activate Your Franchise',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To start managing profiles and accessing the franchise dashboard, a one-time activation fee is required.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Column(
                children: [
                  Text(
                    'Activation Fee',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹25,000',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            CustomButton(
              text: 'Pay Now',
              isLoading: _isProcessing,
              onPressed: _processPayment,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
