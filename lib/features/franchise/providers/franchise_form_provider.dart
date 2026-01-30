import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';

class FranchiseFormProvider extends ChangeNotifier {
  final Map<String, dynamic> _formData = {};

  Map<String, dynamic> get formData => _formData;

  void updateField(String key, dynamic value) {
    _formData[key] = value;
    
    // Auto-calculate age when DOB changes
    if (key == 'dob' && value != null) {
      final age = calculateAge(value);
      if (age != null) {
        _formData['age'] = age;
      }
    }
    
    notifyListeners();
  }

  int? calculateAge(String? dobString) {
    if (dobString == null) return null;
    
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      
      // Adjust if birthday hasn't occurred this year
      if (now.month < dob.month || 
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      return null;
    }
  }

  void prepopulateFromUser(User user) {
    _formData.clear();

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        _formData[key] = value;
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
      // Calculate age from DOB
      final age = calculateAge(user.dob!.toIso8601String());
      if (age != null) {
        _formData['age'] = age;
      }
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
          addIfNotEmpty('marital_status', (user.maritalStatus as List).first.toString());
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
    }

    notifyListeners();
  }

  void reset() {
    _formData.clear();
    notifyListeners();
  }
}