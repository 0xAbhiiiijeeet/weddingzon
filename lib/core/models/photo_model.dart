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
    return Photo(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? json['id'],
      isProfile: json['isProfile'] ?? json['is_profile'] ?? false,
      restricted: json['restricted'] ?? false,
      blurredUrl: json['blurredUrl'] ?? json['blurred_url'],
    );
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
