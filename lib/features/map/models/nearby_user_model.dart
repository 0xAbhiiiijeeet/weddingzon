class NearbyUser {
  final String id;
  final String username;
  final List<double> coordinates;
  final double distance;
  final String? profilePhoto;

  NearbyUser({
    required this.id,
    required this.username,
    required this.coordinates,
    required this.distance,
    this.profilePhoto,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    return NearbyUser(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Unknown',
      coordinates: List<double>.from(
        json['location']?['coordinates']?.map((x) => x.toDouble()) ??
            [0.0, 0.0],
      ),
      distance: (json['distance'] ?? 0).toDouble(),
      profilePhoto: json['profilePhoto'],
    );
  }
}
