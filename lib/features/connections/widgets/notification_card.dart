import 'package:flutter/material.dart';
import '../../notifications/models/notification_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final data = notification.data;
    final name = data['name'] ?? data['username'] ?? 'Unknown User';
    final action = data['action'] ?? _getActionText(notification.type);
    final typeText = data['type_text'] ?? _getTypeText(notification.type);

    final profilePhoto = data['profilePhoto'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final username = data['username'] as String?;

          if (username == null ||
              username.isEmpty ||
              username == 'deleted_user') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This account is no longer available'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          Navigator.pushNamed(context, '/profile/user', arguments: username);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade50,
                backgroundImage:
                    (profilePhoto != null && profilePhoto.isNotEmpty)
                    ? CachedNetworkImageProvider(profilePhoto)
                    : null,
                child: (profilePhoto == null || profilePhoto.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: action),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: typeText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionText(String type) {
    switch (type) {
      case 'request_accepted':
        return 'accepted your';
      case 'photo_access_granted':
        return 'granted your';
      case 'details_access_granted':
        return 'granted your';
      case 'connection_request':
        return 'sent you a';
      case 'photo_access_request':
        return 'requested';
      default:
        return 'updated';
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'request_accepted':
        return 'connection request';
      case 'photo_access_granted':
        return 'photo request';
      case 'details_access_granted':
        return 'details request';
      case 'connection_request':
        return 'connection request';
      case 'photo_access_request':
        return 'photo access';
      default:
        return 'notification';
    }
  }
}