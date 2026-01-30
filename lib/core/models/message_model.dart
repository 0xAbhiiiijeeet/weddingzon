class Message {
  final String? id;
  final String senderId;
  final String? senderUsername;
  final String receiverId;
  final String message;
  final MessageType type;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    this.senderUsername,
    required this.receiverId,
    required this.message,
    this.type = MessageType.text,
    this.mediaUrl,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id']?.toString(),
      senderId:
          json['sender']?['_id']?.toString() ??
          json['senderId']?.toString() ??
          '',
      senderUsername: json['sender']?['username']?.toString(),
      receiverId:
          json['receiverId']?.toString() ?? json['receiver']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: MessageType.fromString(json['type']?.toString()),
      mediaUrl: json['mediaUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type.value,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderUsername,
    String? receiverId,
    String? message,
    MessageType? type,
    String? mediaUrl,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum MessageType {
  text('text'),
  image('image');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }
}