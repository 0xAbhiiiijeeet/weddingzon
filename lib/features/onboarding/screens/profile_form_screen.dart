import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/onboarding_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/basic_details_form.dart';
import '../widgets/location_form.dart';
import '../widgets/family_background_form.dart';
import '../widgets/education_career_form.dart';
import '../widgets/lifestyle_form.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final PageController _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    5,
    (_) => GlobalKey<FormState>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;

      if (args is Map<String, dynamic>) {
        // New format: {role: 'member', gender: 'Male'/'Female'}
        final role = args['role'] as String?;
        final gender = args['gender'] as String?;

        if (role != null) {
          context.read<OnboardingProvider>().updateField('role', role);
        }
        if (gender != null && gender.isNotEmpty) {
          context.read<OnboardingProvider>().updateField('gender', gender);
        }
      } else if (args is String) {
        // Legacy format: just role string
        context.read<OnboardingProvider>().updateField('role', args);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildStepIndicator(provider.currentStep),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => provider.setStep(index),
                  children: [
                    BasicDetailsForm(formKey: _formKeys[0]),
                    LocationForm(formKey: _formKeys[1]),
                    FamilyBackgroundForm(formKey: _formKeys[2]),
                    EducationCareerForm(formKey: _formKeys[3]),
                    LifestyleForm(formKey: _formKeys[4]),
                  ],
                ),
              ),
              _buildNavigationButtons(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == currentStep ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index <= currentStep
                  ? Colors.deepPurple
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons(OnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (provider.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  provider.previousStep();
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Previous'),
              ),
            ),
          if (provider.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _handleNext(provider),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(provider.currentStep == 4 ? 'Submit' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext(OnboardingProvider provider) async {
    if (!_formKeys[provider.currentStep].currentState!.validate()) {
      Fluttertoast.showToast(
        msg: "Please fill all required fields",
        backgroundColor: Colors.red,
      );
      return;
    }

    _formKeys[provider.currentStep].currentState!.save();

    if (provider.currentStep == 4) {
      // Submit profile
      final response = await provider.submitProfile();
      if (response.success && response.data != null) {
        // Update auth provider with new user data
        if (!mounted) return;
        context.read<AuthProvider>().updateUser(response.data!);

        Fluttertoast.showToast(
          msg: "Profile completed successfully!",
          backgroundColor: Colors.green,
        );

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.feed,
          (route) => false,
        );
      } else {
        Fluttertoast.showToast(
          msg: response.message ?? "Failed to update profile",
          backgroundColor: Colors.red,
        );
      }
    } else {
      provider.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
