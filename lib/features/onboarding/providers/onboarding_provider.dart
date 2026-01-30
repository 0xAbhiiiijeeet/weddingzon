import 'package:flutter/material.dart';
import '../repositories/profile_repository.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/api_response.dart';

class OnboardingProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  OnboardingProvider(this._profileRepository);

  int _currentStep = 0;
  bool _isLoading = false;

  final Map<String, dynamic> _formData = {};

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get formData => _formData;

  void updateField(String key, dynamic value) {
    debugPrint('[ONBOARDING_PROVIDER] 🔄 updateField called');
    debugPrint('[ONBOARDING_PROVIDER]   - Key: $key');
    debugPrint('[ONBOARDING_PROVIDER]   - Value: $value');
    debugPrint('[ONBOARDING_PROVIDER]   - Type: ${value.runtimeType}');
    debugPrint('[ONBOARDING_PROVIDER]   - Provider instance: ${this.hashCode}');
    debugPrint('[ONBOARDING_PROVIDER]   - FormData instance: ${_formData.hashCode}');

    _formData[key] = value;

    debugPrint('[ONBOARDING_PROVIDER] 📊 Current form data keys: ${_formData.keys}');
    debugPrint('[ONBOARDING_PROVIDER] 📦 Total fields: ${_formData.length}');

    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 7) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  Future<ApiResponse<User>> submitProfile() async {
    _isLoading = true;
    notifyListeners();

    _formData['is_profile_complete'] = true;

    debugPrint('[ONBOARDING] Submitting form data: $_formData');
    final response = await _profileRepository.registerDetails(_formData);

    if (response.success &&
        _formData['latitude'] != null &&
        _formData['longitude'] != null) {
      debugPrint('[ONBOARDING] Submitting location coordinates...');
      await updateUserLocation(_formData['latitude'], _formData['longitude']);
    }

    _isLoading = false;
    notifyListeners();

    return response;
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    debugPrint('[ONBOARDING] Updating location: $lat, $lng');
    await _profileRepository.updateLocation(lat, lng);
  }

  void prepopulateFromUser(User user) {
    debugPrint('[ONBOARDING_PROVIDER] ========================================');
    debugPrint('[ONBOARDING_PROVIDER] 🔄 prepopulateFromUser - Starting');
    debugPrint('[ONBOARDING_PROVIDER] 👤 User ID: ${user.id}');
    debugPrint('[ONBOARDING_PROVIDER] 📛 User Name: ${user.fullName}');
    debugPrint('[ONBOARDING_PROVIDER] 📧 User Email: ${user.email}');
    debugPrint('[ONBOARDING_PROVIDER] 📱 User Phone: ${user.phone}');

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        _formData[key] = value;
        debugPrint('[ONBOARDING_PROVIDER]   ✅ Added $key: $value');
      }
    }

    addIfNotEmpty('created_for', user.createdFor);
    addIfNotEmpty('username', user.username);
    addIfNotEmpty('email', user.email);
    addIfNotEmpty('phone', user.phone);
    addIfNotEmpty('first_name', user.firstName);
    addIfNotEmpty('last_name', user.lastName);
    if (user.dob != null) {
      _formData['dob'] = user.dob!.toIso8601String();
      debugPrint('[ONBOARDING_PROVIDER]   ✅ Added dob: ${user.dob!.toIso8601String()}');
    }
    addIfNotEmpty('gender', user.gender);
    if (user.height != null) {
      String h = user.height!;
      if (h.contains(' (')) {
        h = h.split(' (')[0];
      }
      addIfNotEmpty('height', h);
    }

    if (user.maritalStatus != null) {
      if (user.maritalStatus is List) {
        if ((user.maritalStatus as List).isNotEmpty) {
          addIfNotEmpty(
            'marital_status',
            (user.maritalStatus as List).first.toString(),
          );
        }
      } else if (user.maritalStatus is String) {
        addIfNotEmpty('marital_status', user.maritalStatus);
      }
    }

    addIfNotEmpty('mother_tongue', user.motherTongue);
    addIfNotEmpty('disability', user.disability);
    addIfNotEmpty('disability_description', user.disabilityDescription);
    addIfNotEmpty('aadhar_number', user.aadharNumber);
    addIfNotEmpty('blood_group', user.bloodGroup);
    addIfNotEmpty('about_me', user.aboutMe);

    addIfNotEmpty('phone', user.phone);
    addIfNotEmpty('email', user.email);

    addIfNotEmpty('city', user.city);
    addIfNotEmpty('state', user.state);
    addIfNotEmpty('country', user.country);

    addIfNotEmpty('father_status', user.fatherStatus);
    addIfNotEmpty('mother_status', user.motherStatus);
    if (user.brothers != null) _formData['brothers'] = user.brothers.toString();
    if (user.sisters != null) _formData['sisters'] = user.sisters.toString();
    addIfNotEmpty('family_status', user.familyStatus);
    addIfNotEmpty('family_type', user.familyType);
    addIfNotEmpty('family_values', user.familyValues);
    addIfNotEmpty('annual_income', user.annualIncome);
    addIfNotEmpty('family_location', user.familyLocation);

    addIfNotEmpty('highest_education', user.highestEducation);
    addIfNotEmpty('educational_details', user.educationalDetails);
    addIfNotEmpty('occupation', user.occupation);
    addIfNotEmpty('employed_in', user.employedIn);
    addIfNotEmpty('personal_income', user.personalIncome);
    addIfNotEmpty('working_sector', user.workingSector);
    addIfNotEmpty('working_location', user.workingLocation);

    addIfNotEmpty('religion', user.religion);
    addIfNotEmpty('community', user.community);
    addIfNotEmpty('sub_community', user.subCommunity);

    addIfNotEmpty('appearance', user.appearance);
    addIfNotEmpty('living_status', user.livingStatus);
    addIfNotEmpty('physical_status', user.physicalStatus);
    addIfNotEmpty('eating_habits', user.eatingHabits);
    addIfNotEmpty('smoking_habits', user.smokingHabits);
    addIfNotEmpty('drinking_habits', user.drinkingHabits);
    if (user.hobbies.isNotEmpty) {
      _formData['hobbies'] = user.hobbies;
      debugPrint('[ONBOARDING_PROVIDER]   ✅ Added hobbies: ${user.hobbies}');
    }

    debugPrint('[ONBOARDING_PROVIDER] ========================================');
    debugPrint('[ONBOARDING_PROVIDER] ✅ prepopulateFromUser - Complete');
    debugPrint('[ONBOARDING_PROVIDER] 📊 Total fields populated: ${_formData.length}');
    debugPrint('[ONBOARDING_PROVIDER] 🔑 All keys: ${_formData.keys.toList()}');
    debugPrint('[ONBOARDING_PROVIDER] ========================================');

    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _formData.clear();
    notifyListeners();
  }
}