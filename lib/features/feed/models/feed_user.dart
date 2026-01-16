import '../../../core/models/photo_model.dart';

class FeedUser {
  final String id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final List<Photo> photos;
  final String? aboutMe;
  final String? dob;
  final String? city;
  final String? state;
  final String? country;
  final String? occupation;
  final String? religion;
  final String? gender;
  final String? height;
  final String? maritalStatus;
  final String? motherTongue;

  // Family fields
  final String? fatherStatus;
  final String? motherStatus;
  final int? brothers;
  final int? sisters;
  final String? familyStatus;
  final String? familyType;
  final String? familyValues;
  final String? annualIncome;
  final String? familyLocation;

  // Education & Career fields
  final String? highestEducation;
  final String? educationalDetails;
  final String? employedIn;
  final String? personalIncome;
  final String? workingSector;
  final String? workingLocation;

  // Lifestyle fields
  final String? eatingHabits;
  final String? smokingHabits;
  final String? drinkingHabits;
  final String? community;
  final String? subCommunity;
  final String? appearance;
  final String? livingStatus;
  final String? physicalStatus;
  final List<String>? hobbies;

  // Connection status (from feed/profile response)
  final String? connectionStatus;
  final String? photoRequestStatus;

  FeedUser({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    this.photos = const [],
    this.aboutMe,
    this.dob,
    this.city,
    this.state,
    this.country,
    this.occupation,
    this.religion,
    this.gender,
    this.height,
    this.maritalStatus,
    this.motherTongue,
    // Family
    this.fatherStatus,
    this.motherStatus,
    this.brothers,
    this.sisters,
    this.familyStatus,
    this.familyType,
    this.familyValues,
    this.annualIncome,
    this.familyLocation,
    // Career
    this.highestEducation,
    this.educationalDetails,
    this.employedIn,
    this.personalIncome,
    this.workingSector,
    this.workingLocation,
    // Lifestyle
    this.eatingHabits,
    this.smokingHabits,
    this.drinkingHabits,
    this.community,
    this.subCommunity,
    this.appearance,
    this.livingStatus,
    this.physicalStatus,
    this.hobbies,
    // Connection
    this.connectionStatus,
    this.photoRequestStatus,
  });

  // Computed full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? username;
  }

  // Calculate age from dob
  int? get age {
    if (dob == null) return null;
    try {
      final birthDate = DateTime.parse(dob!);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // Location string
  String? get location {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.isEmpty ? null : parts.join(', ');
  }

  factory FeedUser.fromJson(Map<String, dynamic> json) {
    return FeedUser(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      profilePhoto: json['profilePhoto'] ?? json['profile_photo'],
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((p) => Photo.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      aboutMe: json['aboutMe'] ?? json['about_me'] ?? json['bio'],
      dob: json['dob'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      occupation: json['occupation'],
      religion: json['religion'],
      gender: json['gender'],
      height: json['height'],
      maritalStatus: json['maritalStatus'] ?? json['marital_status'],
      motherTongue: json['motherTongue'] ?? json['mother_tongue'],
      // Family
      fatherStatus: json['fatherStatus'] ?? json['father_status'],
      motherStatus: json['motherStatus'] ?? json['mother_status'],
      brothers: json['brothers'],
      sisters: json['sisters'],
      familyStatus: json['familyStatus'] ?? json['family_status'],
      familyType: json['familyType'] ?? json['family_type'],
      familyValues: json['familyValues'] ?? json['family_values'],
      annualIncome: json['annualIncome'] ?? json['annual_income'],
      familyLocation: json['familyLocation'] ?? json['family_location'],
      // Career
      highestEducation: json['highestEducation'] ?? json['highest_education'],
      educationalDetails:
          json['educationalDetails'] ?? json['educational_details'],
      employedIn: json['employedIn'] ?? json['employed_in'],
      personalIncome: json['personalIncome'] ?? json['personal_income'],
      workingSector: json['workingSector'] ?? json['working_sector'],
      workingLocation: json['workingLocation'] ?? json['working_location'],
      // Lifestyle
      eatingHabits: json['eatingHabits'] ?? json['eating_habits'],
      smokingHabits: json['smokingHabits'] ?? json['smoking_habits'],
      drinkingHabits: json['drinkingHabits'] ?? json['drinking_habits'],
      community: json['community'],
      subCommunity: json['subCommunity'] ?? json['sub_community'],
      appearance: json['appearance'],
      livingStatus: json['livingStatus'] ?? json['living_status'],
      physicalStatus: json['physicalStatus'] ?? json['physical_status'],
      hobbies: (json['hobbies'] as List<dynamic>?)?.cast<String>(),
      // Connection
      connectionStatus: json['connectionStatus'],
      photoRequestStatus: json['photoRequestStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'profilePhoto': profilePhoto,
      'photos': photos.map((p) => p.toJson()).toList(),
      'about_me': aboutMe,
      'dob': dob,
      'city': city,
      'state': state,
      'country': country,
      'occupation': occupation,
      'religion': religion,
      'gender': gender,
      'height': height,
      'marital_status': maritalStatus,
      'mother_tongue': motherTongue,
      // Family
      'father_status': fatherStatus,
      'mother_status': motherStatus,
      'brothers': brothers,
      'sisters': sisters,
      'family_status': familyStatus,
      'family_type': familyType,
      'family_values': familyValues,
      'annual_income': annualIncome,
      'family_location': familyLocation,
      // Career
      'highest_education': highestEducation,
      'educational_details': educationalDetails,
      'employed_in': employedIn,
      'personal_income': personalIncome,
      'working_sector': workingSector,
      'working_location': workingLocation,
      // Lifestyle
      'eating_habits': eatingHabits,
      'smoking_habits': smokingHabits,
      'drinking_habits': drinkingHabits,
      'community': community,
      'sub_community': subCommunity,
      'appearance': appearance,
      'living_status': livingStatus,
      'physical_status': physicalStatus,
      'hobbies': hobbies,
      // Connection
      'connectionStatus': connectionStatus,
      'photoRequestStatus': photoRequestStatus,
    };
  }
}
