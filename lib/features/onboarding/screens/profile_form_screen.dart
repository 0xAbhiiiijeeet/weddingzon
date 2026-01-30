import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/onboarding_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/deep_link_service.dart';
import '../widgets/basic_details_form.dart';
import '../widgets/location_form.dart';
import '../widgets/family_background_form.dart';
import '../widgets/education_career_form.dart';
import '../widgets/religious_background_form.dart';
import '../widgets/lifestyle_form.dart';
import '../widgets/property_assets_form.dart';
import '../widgets/contact_details_form.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final PageController _pageController = PageController();
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    8,
    (_) => GlobalKey<FormState>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;

      if (args is Map<String, dynamic>) {
        final role = args['role'] as String?;
        final gender = args['gender'] as String?;

        if (role != null) {
          context.read<OnboardingProvider>().updateField('role', role);
        }
        if (gender != null && gender.isNotEmpty) {
          context.read<OnboardingProvider>().updateField('gender', gender);
        }
      } else if (args is String) {
        context.read<OnboardingProvider>().updateField('role', args);
      }

      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        if (currentUser.phone != null) {
          context.read<OnboardingProvider>().updateField(
            'phone',
            currentUser.phone,
          );
        }
        if (currentUser.email != null) {
          context.read<OnboardingProvider>().updateField(
            'email',
            currentUser.email,
          );
        }
        if (currentUser.username != null) {
          context.read<OnboardingProvider>().updateField(
            'username',
            currentUser.username,
          );
        }

        if (currentUser.isProfileComplete == false) {
          context.read<OnboardingProvider>().prepopulateFromUser(currentUser);
        }
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
                    ReligiousBackgroundForm(formKey: _formKeys[4]),
                    LifestyleForm(formKey: _formKeys[5]),
                    PropertyAssetsForm(formKey: _formKeys[6]),
                    ContactDetailsForm(formKey: _formKeys[7]),
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
        children: List.generate(8, (index) {
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
                  : () {
                      debugPrint('[PROFILE_FORM] Next/Submit Button Tapped!');
                      _handleNext(provider);
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      provider.currentStep == 7 ? 'Submit' : 'Next',
                    ),
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

    if (provider.currentStep == 7) {
      debugPrint('[PROFILE_FORM] Submitting profile...');
      final response = await provider.submitProfile();
      debugPrint('[PROFILE_FORM] Submit response success: ${response.success}');
      debugPrint('[PROFILE_FORM] Submit response data: ${response.data}');

      if (response.success && response.data != null) {
        if (!mounted) {
          debugPrint('[PROFILE_FORM] Content not mounted after submit');
          return;
        }

        debugPrint('[PROFILE_FORM] Updating global user data...');
        context.read<AuthProvider>().updateUser(response.data!);

        Fluttertoast.showToast(
          msg: "Profile completed successfully!",
          backgroundColor: Colors.green,
        );

        if (!mounted) return;
        if (!mounted) return;
        debugPrint('[PROFILE_FORM] Routing user via AuthProvider...');
        context.read<AuthProvider>().routeUser(response.data!);

        final deepLinkService = context.read<DeepLinkService>();
        if (deepLinkService.pendingUsername != null) {
          debugPrint(
            '[PROFILE_FORM] Found pending deep link: ${deepLinkService.pendingUsername}',
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            deepLinkService.navigateToPendingProfile();
          });
        }
      } else {
        debugPrint('[PROFILE_FORM] Submit failed: ${response.message}');
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