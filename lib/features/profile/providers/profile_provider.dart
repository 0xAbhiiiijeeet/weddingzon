import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../repositories/user_repository.dart';
import '../../../core/models/api_response.dart'; // Assuming ApiResponse is in core/models

class ProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  User? _currentUser;
  bool _isLoading = false;
  final Map<String, dynamic> _editFormData = {};

  ProfileProvider(this._userRepository);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get editFormData => _editFormData;

  Future<void> loadCurrentUser() async {
    _setLoading(true);
    try {
      final response = await _userRepository.getCurrentUser();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PROFILE_PROVIDER] Error loading user: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadPhotos(List<File> photos) async {
    _setLoading(true);
    final response = await _userRepository.uploadPhotos(photos);
    _setLoading(false);

    if (response.success && response.data != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deletePhoto(String photoId) async {
    _setLoading(true);
    final response = await _userRepository.deletePhoto(photoId);
    _setLoading(false);

    if (response.success) {
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> setProfilePhoto(String photoId) async {
    _setLoading(true);
    final response = await _userRepository.updatePhoto(
      photoId,
      isProfile: true,
    );
    _setLoading(false);

    if (response.success) {
      notifyListeners();
      return true;
    }
    return false;
  }

  void reset() {
    _currentUser = null;
    notifyListeners();
  }

  // Edit Profile Methods
  void initializeEditForm(User user) {
    _editFormData.clear();
    _editFormData.addAll(user.toJson());
    notifyListeners();
  }

  void updateEditField(String key, dynamic value) {
    _editFormData[key] = value;
    notifyListeners();
  }

  Future<ApiResponse<User>> saveProfile() async {
    _isLoading = true;
    notifyListeners();

    debugPrint(
      '[PROFILE] Saving profile with data: ${_editFormData.keys.toList()}',
    );

    final response = await _userRepository.updateProfile(_editFormData);

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentUser = response.data;
      debugPrint('[PROFILE] Profile updated successfully');
    }

    notifyListeners();
    return response;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
