/// Represents a conversation in the chat list
class Conversation {
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;

  Conversation({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
  });

  /// Returns the display name (full name if available, otherwise username)
  String get displayName {
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return fullName.isNotEmpty ? fullName : username;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      profilePhoto: json['profilePhoto']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': userId,
      'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'profilePhoto': profilePhoto,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
