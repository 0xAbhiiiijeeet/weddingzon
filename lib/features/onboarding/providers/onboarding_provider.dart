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
    if (_currentStep < 4) {
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

    final response = await _profileRepository.registerDetails(_formData);

    _isLoading = false;
    notifyListeners();

    return response;
  }

  void reset() {
    _currentStep = 0;
    _formData.clear();
    notifyListeners();
  }
}
