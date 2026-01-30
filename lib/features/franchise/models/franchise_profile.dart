class FranchiseProfile {
  final String id;
  final String username;
  final String firstName;
  final bool isProfileComplete;

  FranchiseProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.isProfileComplete,
  });

  factory FranchiseProfile.fromJson(Map<String, dynamic> json) {
    return FranchiseProfile(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      isProfileComplete: json['is_profile_complete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'first_name': firstName,
      'is_profile_complete': isProfileComplete,
    };
  }
}