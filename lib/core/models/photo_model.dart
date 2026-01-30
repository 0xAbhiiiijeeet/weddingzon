import 'package:flutter/foundation.dart';

class Photo {
  final String url;
  final String? publicId;
  final bool isProfile;
  final bool restricted;
  final String? blurredUrl;

  Photo({
    required this.url,
    this.publicId,
    this.isProfile = false,
    this.restricted = false,
    this.blurredUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    debugPrint('[PHOTO_MODEL] 🔵 Parsing photo from JSON: $json');
    debugPrint('[PHOTO_MODEL] 🔑 Keys: ${json.keys}');

    final photo = Photo(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? json['id'] ?? json['_id'],
      isProfile: json['isProfile'] ?? json['is_profile'] ?? false,
      restricted: json['restricted'] ?? false,
      blurredUrl: json['blurredUrl'] ?? json['blurred_url'],
    );

    debugPrint('[PHOTO_MODEL] ✅ Parsed photo - URL: ${photo.url}, isProfile: ${photo.isProfile}');
    return photo;
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
      'isProfile': isProfile,
      'restricted': restricted,
      'blurredUrl': blurredUrl,
    };
  }

  Photo copyWith({
    String? url,
    String? publicId,
    bool? isProfile,
    bool? restricted,
    String? blurredUrl,
  }) {
    return Photo(
      url: url ?? this.url,
      publicId: publicId ?? this.publicId,
      isProfile: isProfile ?? this.isProfile,
      restricted: restricted ?? this.restricted,
      blurredUrl: blurredUrl ?? this.blurredUrl,
    );
  }

  @override
  String toString() {
    return 'Photo(url: $url, isProfile: $isProfile, restricted: $restricted, blurredUrl: $blurredUrl)';
  }
}