class ProfileViewer {
  final Map<String, dynamic> viewer; // Contains _id, username, profilePhoto
  final DateTime viewedAt;

  ProfileViewer({required this.viewer, required this.viewedAt});

  factory ProfileViewer.fromJson(Map<String, dynamic> json) {
    return ProfileViewer(
      viewer: json['viewer'] as Map<String, dynamic>? ?? {},
      viewedAt:
          DateTime.tryParse(json['viewedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get id => viewer['_id']?.toString() ?? '';
  String get username => viewer['username']?.toString() ?? 'Unknown';
  String get profilePhoto => viewer['profilePhoto']?.toString() ?? '';
}
