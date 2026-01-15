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
    };
  }
}
