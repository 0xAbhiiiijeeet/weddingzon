import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/routes/app_routes.dart';
import 'dart:async';

class FranchiseApprovalScreen extends StatefulWidget {
  const FranchiseApprovalScreen({super.key});

  @override
  State<FranchiseApprovalScreen> createState() =>
      _FranchiseApprovalScreenState();
}

class _FranchiseApprovalScreenState extends State<FranchiseApprovalScreen> {
  bool _isChecking = false;
  Timer? _autoCheckTimer;
  int _checkCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║ [APPROVAL] 📋 APPROVAL SCREEN LOADED                       ║',
    );
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );
    debugPrint('[APPROVAL] ⏰ Starting auto-check timer (every 5 seconds)');

    // Auto-check status every 5 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkCount++;
        debugPrint('[APPROVAL] ⏰ Auto-check triggered (count: $_checkCount)');
        _checkStatus(isAuto: true);
      }
    });
  }

  @override
  void dispose() {
    debugPrint('[APPROVAL] 🔴 Disposing approval screen, cancelling timer');
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _checkStatus({bool isAuto = false}) async {
    if (_isChecking) {
      debugPrint('[APPROVAL] ⚠️ Already checking status, skipping...');
      return;
    }

    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║ [APPROVAL] 🔍 CHECK STATUS ${isAuto ? '(AUTO)' : '(MANUAL)'}                     ║',
    );
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );

    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('[APPROVAL] 🔄 Refreshing user data from backend...');
    await authProvider.refreshUser();

    if (!mounted) {
      debugPrint('[APPROVAL] ⚠️ Widget unmounted during status check');
      return;
    }

    final user = authProvider.currentUser;

    debugPrint('[APPROVAL] ========================================');
    debugPrint('[APPROVAL] 📊 Current User Status:');
    if (user != null) {
      debugPrint('[APPROVAL]   - ID: ${user.id}');
      debugPrint('[APPROVAL]   - Name: ${user.fullName}');
      debugPrint('[APPROVAL]   - Role: ${user.role}');
      debugPrint('[APPROVAL]   - franchise_status: ${user.franchiseStatus}');
      debugPrint('[APPROVAL]   - franchise_details: ${user.franchiseDetails}');
    } else {
      debugPrint('[APPROVAL]   - User is NULL');
    }
    debugPrint('[APPROVAL] ========================================');

    setState(() => _isChecking = false);

    if (user?.franchiseStatus == 'active') {
      debugPrint('[APPROVAL] ========================================');
      debugPrint('[APPROVAL] ✅✅✅ APPROVED! STATUS IS ACTIVE! ✅✅✅');
      debugPrint('[APPROVAL] ========================================');
      debugPrint('[APPROVAL] 🎉 Admin has approved the franchise!');
      debugPrint('[APPROVAL] 🚀 Auto-routing to Franchise Dashboard...');
      debugPrint('[APPROVAL] 📍 Target Route: ${AppRoutes.franchiseDashboard}');
      debugPrint('[APPROVAL] ⏰ Cancelling auto-check timer');

      _autoCheckTimer?.cancel();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(AppRoutes.franchiseDashboard);

      debugPrint('[APPROVAL] ✅ Navigation complete');
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('');
    } else if (user?.franchiseStatus == 'rejected') {
      debugPrint('[APPROVAL] ========================================');
      debugPrint('[APPROVAL] ❌❌❌ REJECTED BY ADMIN ❌❌❌');
      debugPrint('[APPROVAL] ========================================');
      debugPrint('[APPROVAL] 🔴 Routing to landing page');
      debugPrint('[APPROVAL] ⏰ Cancelling auto-check timer');

      _autoCheckTimer?.cancel();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your application was rejected. Please contact support.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      Navigator.of(context).pushReplacementNamed(AppRoutes.landing);

      debugPrint('[APPROVAL] ✅ Navigation complete');
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('');
    } else {
      debugPrint('[APPROVAL] ========================================');
      debugPrint('[APPROVAL] ⏳ Still pending approval...');
      debugPrint('[APPROVAL]   - Status: ${user?.franchiseStatus ?? 'null'}');
      debugPrint('[APPROVAL]   - Next auto-check in 5 seconds');
      debugPrint('[APPROVAL] ========================================');

      if (!isAuto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still pending approval. Please wait.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Pending'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.pending_outlined, size: 100, color: Colors.orange),
            const SizedBox(height: 32),
            const Text(
              'Approval Request Sent!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your franchise application has been submitted to our admin team.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-checking status every 5 seconds',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '✓ When approved, you will automatically be redirected to the dashboard',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '✓ Approval typically takes 24-48 hours',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '✓ You can also manually check status anytime',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Need help?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact: support@weddingzon.com',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            CustomButton(
              text: _isChecking ? 'Checking...' : 'Check Status Now',
              isLoading: _isChecking,
              onPressed: () => _checkStatus(isAuto: false),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Logout',
              isOutlined: true,
              onPressed: () async {
                debugPrint('[APPROVAL] 🔵 Logout clicked');
                debugPrint('[APPROVAL] ⏰ Cancelling auto-check timer');
                _autoCheckTimer?.cancel();

                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();

                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.landing,
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
