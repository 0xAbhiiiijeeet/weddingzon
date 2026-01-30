import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/franchise_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class FranchiseProfileFormScreen extends StatefulWidget {
  const FranchiseProfileFormScreen({super.key});

  @override
  State<FranchiseProfileFormScreen> createState() =>
      _FranchiseProfileFormScreenState();
}

class _FranchiseProfileFormScreenState
    extends State<FranchiseProfileFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final List<GlobalKey<FormState>> _formKeys = List.generate(
    3,
    (_) => GlobalKey<FormState>(),
  );

  final Map<String, dynamic> _formData = {};

  // Controllers for read-only fields to ensure proper display
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    final user = context.read<AuthProvider>().currentUser;
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    // Populate form data
    if (user != null) {
      _formData['email'] = user.email;
      _formData['phone'] = user.phone;
      _formData['first_name'] = user.firstName;
      _formData['last_name'] = user.lastName;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    debugPrint(
      '[FRANCHISE_FORM] 🔵 _nextStep called - Current step: $_currentStep',
    );

    final form = _formKeys[_currentStep].currentState;
    if (form == null || !form.validate()) {
      debugPrint(
        '[FRANCHISE_FORM] ❌ Form validation failed for step $_currentStep',
      );
      return;
    }

    debugPrint(
      '[FRANCHISE_FORM] ✅ Form validation passed for step $_currentStep',
    );
    form.save();
    debugPrint('[FRANCHISE_FORM] 💾 Form data saved');

    if (_currentStep < 2) {
      debugPrint(
        '[FRANCHISE_FORM] ➡️ Moving to next step (${_currentStep + 1})',
      );
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
      debugPrint('[FRANCHISE_FORM] ✅ Now on step $_currentStep');
    } else {
      debugPrint('[FRANCHISE_FORM] 🎯 Final step reached - calling _submit()');
      _submit();
    }
  }

  void _previousStep() {
    debugPrint(
      '[FRANCHISE_FORM] 🔵 _previousStep called - Current step: $_currentStep',
    );

    if (_currentStep == 0) {
      debugPrint('[FRANCHISE_FORM] ⚠️ Already at first step, cannot go back');
      return;
    }

    debugPrint(
      '[FRANCHISE_FORM] ⬅️ Moving to previous step (${_currentStep - 1})',
    );
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
    debugPrint('[FRANCHISE_FORM] ✅ Now on step $_currentStep');
  }

  Future<void> _submit() async {
    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint('║ [FRANCHISE_FORM] 🚀 SUBMIT BUTTON CLICKED                 ║');
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );
    debugPrint('[FRANCHISE_FORM] 🔵 Starting form submission process');
    debugPrint('[FRANCHISE_FORM] ========================================');

    setState(() => _isLoading = true);
    debugPrint('[FRANCHISE_FORM] ⏳ Loading state set to true');

    try {
      final franchiseProvider = context.read<FranchiseProvider>();
      final authProvider = context.read<AuthProvider>();

      debugPrint('[FRANCHISE_FORM] 📋 Form Data Summary:');
      debugPrint('[FRANCHISE_FORM]   👤 Personal Info:');
      debugPrint(
        '[FRANCHISE_FORM]      - First Name: ${_formData['first_name']}',
      );
      debugPrint(
        '[FRANCHISE_FORM]      - Last Name: ${_formData['last_name']}',
      );
      debugPrint('[FRANCHISE_FORM]   🏢 Business Info:');
      debugPrint(
        '[FRANCHISE_FORM]      - Business Name: ${_formData['business_name']}',
      );
      debugPrint('[FRANCHISE_FORM]      - City: ${_formData['city']}');
      debugPrint('[FRANCHISE_FORM]      - State: ${_formData['state']}');
      debugPrint('[FRANCHISE_FORM]   🆔 KYC Info:');
      debugPrint(
        '[FRANCHISE_FORM]      - Aadhar: ${_formData['aadhar_number']}',
      );
      debugPrint('[FRANCHISE_FORM]      - PAN: ${_formData['pan_number']}');
      debugPrint(
        '[FRANCHISE_FORM]      - GST: ${_formData['gst_number'] ?? 'Not provided'}',
      );

      // ⚠️ IMPORTANT: Backend expects this structure (see API docs)
      // - phone at root level
      // - city/state/pincode INSIDE franchise_details (not at root)
      final payload = {
        'role': 'franchise',
        'first_name': _formData['first_name'],
        'last_name': _formData['last_name'],
        'phone': authProvider
            .currentUser
            ?.phoneNumber, // Use existing phone from auth
        'franchise_details': {
          'business_name': _formData['business_name'],
          'business_address': _formData['business_address'],
          'city': _formData['city'], // ← Now INSIDE franchise_details
          'state': _formData['state'], // ← Now INSIDE franchise_details
          'pincode':
              _formData['pincode'] ?? '', // ← Now INSIDE franchise_details
          'gst_number': _formData['gst_number'],
          'pan_number': _formData['pan_number'],
          'aadhar_number': _formData['aadhar_number'],
        },
      };

      debugPrint('[FRANCHISE_FORM] ========================================');
      debugPrint(
        '[FRANCHISE_FORM] 📤 Payload prepared for API (NEW STRUCTURE):',
      );
      debugPrint('[FRANCHISE_FORM]   - role: ${payload['role']}');
      debugPrint('[FRANCHISE_FORM]   - first_name: ${payload['first_name']}');
      debugPrint('[FRANCHISE_FORM]   - last_name: ${payload['last_name']}');
      debugPrint('[FRANCHISE_FORM]   - phone: ${payload['phone']}');
      debugPrint('[FRANCHISE_FORM]   - franchise_details:');
      final details = payload['franchise_details'] as Map;
      details.forEach((key, value) {
        debugPrint('[FRANCHISE_FORM]       • $key: $value');
      });
      debugPrint('[FRANCHISE_FORM] ========================================');

      debugPrint(
        '[FRANCHISE_FORM] 🌐 Calling updateFranchiseOwnerProfile API...',
      );
      final updatedUser = await franchiseProvider.updateFranchiseOwnerProfile(
        payload,
      );

      debugPrint('[FRANCHISE_FORM] ========================================');
      debugPrint('[FRANCHISE_FORM] 📥 API Response received');
      debugPrint('[FRANCHISE_FORM]   - Success: ${updatedUser != null}');

      if (updatedUser != null) {
        debugPrint('[FRANCHISE_FORM] ✅ API call successful!');
        debugPrint('[FRANCHISE_FORM] 📊 Updated User Data:');
        debugPrint('[FRANCHISE_FORM]   - ID: ${updatedUser.id}');
        debugPrint('[FRANCHISE_FORM]   - Name: ${updatedUser.fullName}');
        debugPrint('[FRANCHISE_FORM]   - Email: ${updatedUser.email}');
        debugPrint('[FRANCHISE_FORM]   - Role: ${updatedUser.role}');
        debugPrint(
          '[FRANCHISE_FORM]   - is_profile_complete: ${updatedUser.isProfileComplete}',
        );
        debugPrint(
          '[FRANCHISE_FORM]   - franchise_status: ${updatedUser.franchiseStatus}',
        );
        debugPrint(
          '[FRANCHISE_FORM]   - franchise_details: ${updatedUser.franchiseDetails}',
        );
        debugPrint('[FRANCHISE_FORM] ========================================');
      } else {
        debugPrint('[FRANCHISE_FORM] ❌ API returned NULL user');
        debugPrint('[FRANCHISE_FORM]   - Error: ${franchiseProvider.error}');
        debugPrint('[FRANCHISE_FORM] ========================================');
      }

      if (!mounted) {
        debugPrint('[FRANCHISE_FORM] ⚠️ Widget unmounted, aborting navigation');
        return;
      }

      if (updatedUser != null) {
        debugPrint(
          '[FRANCHISE_FORM] 🔄 Updating AuthProvider with new user data...',
        );
        authProvider.updateUser(updatedUser);

        debugPrint('[FRANCHISE_FORM] ✅ AuthProvider updated successfully');
        debugPrint('[FRANCHISE_FORM] 📊 Current user in AuthProvider:');
        final currentUser = authProvider.currentUser;
        debugPrint('[FRANCHISE_FORM]   - ID: ${currentUser?.id}');
        debugPrint(
          '[FRANCHISE_FORM]   - franchise_status: ${currentUser?.franchiseStatus}',
        );
        debugPrint(
          '[FRANCHISE_FORM]   - franchise_details: ${currentUser?.franchiseDetails}',
        );
        debugPrint('[FRANCHISE_FORM] ========================================');

        if (!mounted) {
          debugPrint(
            '[FRANCHISE_FORM] ⚠️ Widget unmounted after AuthProvider update',
          );
          return;
        }

        debugPrint('[FRANCHISE_FORM] 🚀 Navigating to Payment Screen...');
        debugPrint(
          '[FRANCHISE_FORM] 📍 Target Route: ${AppRoutes.franchisePayment}',
        );

        Navigator.of(context).pushReplacementNamed(AppRoutes.franchisePayment);

        debugPrint('[FRANCHISE_FORM] ✅ Navigation complete');
        debugPrint('[FRANCHISE_FORM] ========================================');
      } else {
        debugPrint(
          '[FRANCHISE_FORM] ❌ Failed to update profile, showing error to user',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              franchiseProvider.error.isNotEmpty
                  ? franchiseProvider.error
                  : 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('[FRANCHISE_FORM] ========================================');
      }
    } catch (e) {
      debugPrint('[FRANCHISE_FORM] ========================================');
      debugPrint('[FRANCHISE_FORM] ❌❌❌ EXCEPTION CAUGHT ❌❌❌');
      debugPrint('[FRANCHISE_FORM] Error Type: ${e.runtimeType}');
      debugPrint('[FRANCHISE_FORM] Error Message: $e');
      debugPrint('[FRANCHISE_FORM] ========================================');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('[FRANCHISE_FORM] ⏳ Loading state set to false');
      }
      debugPrint('[FRANCHISE_FORM] 🏁 Form submission process complete');
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Franchise Registration')),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoStep(),
                _buildBusinessInfoStep(),
                _buildKycStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Personal'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Business'),
          _buildStepLine(1),
          _buildStepCircle(2, 'KYC'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, String label) {
    final isActive = index <= _currentStep;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? Colors.orange : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int index) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: index < _currentStep ? Colors.orange : Colors.grey.shade300,
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'First Name',
              initialValue: _formData['first_name'],
              onSaved: (v) => _formData['first_name'] = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Last Name',
              initialValue: _formData['last_name'],
              onSaved: (v) => _formData['last_name'] = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              controller: _emailController,
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Mobile Number',
              controller: _phoneController,
              readOnly: true,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Franchise Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Business Name',
              onSaved: (v) => _formData['business_name'] = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Office Address',
              maxLines: 3,
              onSaved: (v) => _formData['business_address'] = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'City',
                    onSaved: (v) => _formData['city'] = v,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'State',
                    onSaved: (v) => _formData['state'] = v,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KYC Verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'These details are required for franchise approval',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Aadhar Number',
              keyboardType: TextInputType.number,
              onSaved: (v) => _formData['aadhar_number'] = v,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 12) return 'Invalid Aadhar';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'PAN Number',
              onSaved: (v) => _formData['pan_number'] = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'GST Number (Optional)',
              onSaved: (v) => _formData['gst_number'] = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Back',
                isOutlined: true,
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: _currentStep == 2 ? 'Submit & Pay' : 'Next',
              isLoading: _isLoading,
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }
}
