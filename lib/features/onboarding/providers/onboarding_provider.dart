import 'package:flutter/material.dart';
import '../repositories/profile_repository.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/api_response.dart';

class OnboardingProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  OnboardingProvider(this._profileRepository);

  int _currentStep = 0;
  bool _isLoading = false;

  // Form data storage
  final Map<String, dynamic> _formData = {};

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get formData => _formData;

  void updateField(String key, dynamic value) {
    _formData[key] = value;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 7) {
      // Updated from 4 to 7 to support 8 steps
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

    // Mark profile as complete
    _formData['is_profile_complete'] = true;

    debugPrint('[ONBOARDING] Submitting form data: $_formData');
    final response = await _profileRepository.registerDetails(_formData);

    _isLoading = false;
    notifyListeners();

    return response;
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    debugPrint('[ONBOARDING] Updating location: $lat, $lng');
    await _profileRepository.updateLocation(lat, lng);
  }

  /// Pre-populate form data from existing user (for incomplete profiles)
  void prepopulateFromUser(User user) {
    debugPrint('[ONBOARDING] Pre-populating from existing user data');

    // Only populate if fields are not null
    if (user.city != null) _formData['city'] = user.city;
    if (user.state != null) _formData['state'] = user.state;
    if (user.country != null) _formData['country'] = user.country;
    if (user.firstName != null) _formData['first_name'] = user.firstName;
    if (user.lastName != null) _formData['last_name'] = user.lastName;
    if (user.gender != null) _formData['gender'] = user.gender;
    if (user.dob != null) _formData['dob'] = user.dob;
    if (user.height != null) _formData['height'] = user.height;
    if (user.maritalStatus != null)
      _formData['marital_status'] = user.maritalStatus;
    if (user.motherTongue != null)
      _formData['mother_tongue'] = user.motherTongue;
    if (user.religion != null) _formData['religion'] = user.religion;
    if (user.community != null) _formData['community'] = user.community;
    if (user.occupation != null) _formData['occupation'] = user.occupation;

    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _formData.clear();
    notifyListeners();
  }
}
