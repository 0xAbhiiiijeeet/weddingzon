import 'photo_model.dart';

class User {
  final String id;
  final String? username;
  final String? email;
  final String? phone;
  final String? authProvider;
  final String? role;
  final String? adminRole;
  final bool isPhoneVerified;
  final bool isProfileComplete;
  final String? status;

  // Basic Details
  final String? firstName;
  final String? lastName;
  final DateTime? dob;
  final String? gender;
  final String? createdFor;
  final String? height;
  final String? maritalStatus;
  final String? motherTongue;
  final String? disability;
  final String? disabilityDescription;
  final String? aadharNumber;
  final String? bloodGroup;

  // Location
  final String? country;
  final String? state;
  final String? city;

  // Family
  final String? fatherStatus;
  final String? motherStatus;
  final int? brothers;
  final int? sisters;
  final String? familyStatus;
  final String? familyType;
  final String? familyValues;
  final String? annualIncome;
  final String? familyLocation;

  // Education & Career
  final String? highestEducation;
  final String? educationalDetails;
  final String? occupation;
  final String? employedIn;
  final String? personalIncome;
  final String? workingSector;
  final String? workingLocation;

  // Religion & Lifestyle
  final String? religion;
  final String? community;
  final String? subCommunity;
  final String? appearance;
  final String? livingStatus;
  final String? physicalStatus;
  final String? eatingHabits;
  final String? smokingHabits;
  final String? drinkingHabits;
  final List<String> hobbies;

  // Property & Assets
  final double? landArea;
  final String? propertyType;

  // Contact Details
  final String? alternateMobile;
  final String? suitableTimeToCall;

  // Other
  final String? aboutMe;
  final String? profilePhoto;
  final List<Photo> photos;

  User({
    required this.id,
    this.username,
    this.email,
    this.phone,
    this.authProvider,
    this.role,
    this.adminRole,
    this.isPhoneVerified = false,
    this.isProfileComplete = false,
    this.status,
    this.firstName,
    this.lastName,
    this.dob,
    this.gender,
    this.createdFor,
    this.height,
    this.maritalStatus,
    this.motherTongue,
    this.disability,
    this.disabilityDescription,
    this.aadharNumber,
    this.bloodGroup,
    this.country,
    this.state,
    this.city,
    this.fatherStatus,
    this.motherStatus,
    this.brothers,
    this.sisters,
    this.familyStatus,
    this.familyType,
    this.familyValues,
    this.annualIncome,
    this.familyLocation,
    this.highestEducation,
    this.educationalDetails,
    this.occupation,
    this.employedIn,
    this.personalIncome,
    this.workingSector,
    this.workingLocation,
    this.religion,
    this.community,
    this.subCommunity,
    this.appearance,
    this.livingStatus,
    this.physicalStatus,
    this.eatingHabits,
    this.smokingHabits,
    this.drinkingHabits,
    this.hobbies = const [],
    this.landArea,
    this.propertyType,
    this.alternateMobile,
    this.suitableTimeToCall,
    this.aboutMe,
    this.profilePhoto,
    this.photos = const [],
  });

  String? get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName;
  }

  // Aliases for backward compatibility
  String? get name => fullName;
  String? get phoneNumber => phone;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      authProvider: json['auth_provider'],
      role: json['role'],
      adminRole: json['admin_role'],
      isPhoneVerified: json['is_phone_verified'] ?? false,
      isProfileComplete: json['is_profile_complete'] ?? false,
      status: json['status'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      gender: json['gender'],
      createdFor: json['created_for'],
      height: json['height'],
      maritalStatus: json['marital_status'],
      motherTongue: json['mother_tongue'],
      disability: json['disability'],
      disabilityDescription: json['disability_description'],
      aadharNumber: json['aadhar_number'],
      bloodGroup: json['blood_group'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      fatherStatus: json['father_status'],
      motherStatus: json['mother_status'],
      brothers: json['brothers'],
      sisters: json['sisters'],
      familyStatus: json['family_status'],
      familyType: json['family_type'],
      familyValues: json['family_values'],
      annualIncome: json['annual_income'],
      familyLocation: json['family_location'],
      highestEducation: json['highest_education'],
      educationalDetails: json['educational_details'],
      occupation: json['occupation'],
      employedIn: json['employed_in'],
      personalIncome: json['personal_income'],
      workingSector: json['working_sector'],
      workingLocation: json['working_location'],
      religion: json['religion'],
      community: json['community'],
      subCommunity: json['sub_community'],
      appearance: json['appearance'],
      livingStatus: json['living_status'],
      physicalStatus: json['physical_status'],
      eatingHabits: json['eating_habits'],
      smokingHabits: json['smoking_habits'],
      drinkingHabits: json['drinking_habits'],
      hobbies: List<String>.from(json['hobbies'] ?? []),
      landArea: json['land_area']?.toDouble(),
      propertyType: json['property_type'],
      alternateMobile: json['alternate_mobile'],
      suitableTimeToCall: json['suitable_time_to_call'],
      aboutMe: json['about_me'],
      profilePhoto: json['profile_photo'] ?? json['profilePhoto'],
      photos:
          (json['photos'] as List?)?.map((p) => Photo.fromJson(p)).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'auth_provider': authProvider,
      'role': role,
      'admin_role': adminRole,
      'is_phone_verified': isPhoneVerified,
      'is_profile_complete': isProfileComplete,
      'status': status,
      'first_name': firstName,
      'last_name': lastName,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'created_for': createdFor,
      'height': height,
      'marital_status': maritalStatus,
      'mother_tongue': motherTongue,
      'disability': disability,
      'disability_description': disabilityDescription,
      'aadhar_number': aadharNumber,
      'blood_group': bloodGroup,
      'country': country,
      'state': state,
      'city': city,
      'father_status': fatherStatus,
      'mother_status': motherStatus,
      'brothers': brothers,
      'sisters': sisters,
      'family_status': familyStatus,
      'family_type': familyType,
      'family_values': familyValues,
      'annual_income': annualIncome,
      'family_location': familyLocation,
      'highest_education': highestEducation,
      'educational_details': educationalDetails,
      'occupation': occupation,
      'employed_in': employedIn,
      'personal_income': personalIncome,
      'working_sector': workingSector,
      'working_location': workingLocation,
      'religion': religion,
      'community': community,
      'sub_community': subCommunity,
      'appearance': appearance,
      'living_status': livingStatus,
      'physical_status': physicalStatus,
      'eating_habits': eatingHabits,
      'smoking_habits': smokingHabits,
      'drinking_habits': drinkingHabits,
      'hobbies': hobbies,
      'land_area': landArea,
      'property_type': propertyType,
      'alternate_mobile': alternateMobile,
      'suitable_time_to_call': suitableTimeToCall,
      'about_me': aboutMe,
      'profile_photo': profilePhoto,
      'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? role,
    bool? isPhoneVerified,
    bool? isProfileComplete,
    String? firstName,
    String? lastName,
    DateTime? dob,
    String? gender,
    String? religion,
    String? aboutMe,
    String? profilePhoto,
    List<Photo>? photos,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      religion: religion ?? this.religion,
      aboutMe: aboutMe ?? this.aboutMe,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      photos: photos ?? this.photos,
    );
  }
}
