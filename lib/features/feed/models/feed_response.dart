import 'feed_user.dart';

class FeedResponse {
  final List<FeedUser> users;
  final String? nextCursor;
  final bool hasMore;

  FeedResponse({required this.users, this.nextCursor, this.hasMore = false});

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>?;
    return FeedResponse(
      users:
          data
              ?.map((u) => FeedUser.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor'],
      hasMore: json['nextCursor'] != null,
    );
  }
}