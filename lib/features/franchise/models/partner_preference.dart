import 'package:flutter/foundation.dart';

class PartnerPreference {
  final int? minAge;
  final int? maxAge;
  final String? heightMin;
  final String? heightMax;
  final String? religion;
  final List<String>? maritalStatus;
  final String? eatingHabits;
  final String? smokingHabits;
  final String? drinkingHabits;
  final String? highestEducation;
  final String? occupation;
  final int? annualIncome;

  PartnerPreference({
    this.minAge,
    this.maxAge,
    this.heightMin,
    this.heightMax,
    this.religion,
    this.maritalStatus,
    this.eatingHabits,
    this.smokingHabits,
    this.drinkingHabits,
    this.highestEducation,
    this.occupation,
    this.annualIncome,
  });

  factory PartnerPreference.fromJson(Map<String, dynamic> json) {
    return PartnerPreference(
      minAge: _parseIntFromDynamic(
        json['minAge'] ?? json['age_min'] ?? json['ageMin'],
      ),
      maxAge: _parseIntFromDynamic(
        json['maxAge'] ?? json['age_max'] ?? json['ageMax'],
      ),
      heightMin: json['heightMin']?.toString() ??
                 json['height_min']?.toString() ??
                 json['heightmin']?.toString(),
      heightMax: json['heightMax']?.toString() ??
                 json['height_max']?.toString() ??
                 json['heightmax']?.toString(),
      religion: json['religion']?.toString(),
      maritalStatus: (json['marital_status'] is List)
          ? (json['marital_status'] as List).map((e) => e.toString()).toList()
          : (json['marital_status'] != null
                ? [json['marital_status'].toString()]
                : null),
      eatingHabits: json['eating_habits']?.toString(),
      smokingHabits: json['smoking_habits']?.toString(),
      drinkingHabits: json['drinking_habits']?.toString(),
      highestEducation: json['highest_education']?.toString(),
      occupation: json['occupation']?.toString(),
      annualIncome: _parseIntFromDynamic(
        json['annual_income'] ?? json['annual_income_min'] ?? json['annualIncome'],
      ),
    );
  }

  static int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (minAge != null) data['age_min'] = minAge!;
    if (maxAge != null) data['age_max'] = maxAge!;
    if (heightMin != null && heightMin!.isNotEmpty) data['height_min'] = heightMin!;
    if (heightMax != null && heightMax!.isNotEmpty) data['height_max'] = heightMax!;
    if (religion != null && religion!.isNotEmpty) data['religion'] = religion!;
    if (maritalStatus != null && maritalStatus!.isNotEmpty) data['marital_status'] = maritalStatus!;
    if (eatingHabits != null && eatingHabits!.isNotEmpty) data['eating_habits'] = eatingHabits!;
    if (smokingHabits != null && smokingHabits!.isNotEmpty) data['smoking_habits'] = smokingHabits!;
    if (drinkingHabits != null && drinkingHabits!.isNotEmpty) data['drinking_habits'] = drinkingHabits!;
    if (highestEducation != null && highestEducation!.isNotEmpty) data['highest_education'] = highestEducation!;
    if (occupation != null && occupation!.isNotEmpty) data['occupation'] = occupation!;
    if (annualIncome != null) data['annual_income_min'] = annualIncome!;

    debugPrint('[PARTNER_PREF_MODEL] 📦 toJson output: $data');
    debugPrint('[PARTNER_PREF_MODEL] 🔢 age_min type: ${data['age_min']?.runtimeType}');
    debugPrint('[PARTNER_PREF_MODEL] 🔢 age_max type: ${data['age_max']?.runtimeType}');
    debugPrint('[PARTNER_PREF_MODEL] 🔢 annual_income_min type: ${data['annual_income_min']?.runtimeType}');

    return data;
  }
}