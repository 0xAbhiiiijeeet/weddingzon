import 'package:flutter/material.dart';
import '../../notifications/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    // Extracting fields from data or model properties
    final data = notification.data;
    final name = data['name'] ?? data['username'] ?? 'Unknown User';
    // Logic for action text based on type if not explicit
    final action = data['action'] ?? _getActionText(notification.type);
    // Logic for type text
    final typeText = data['type_text'] ?? _getTypeText(notification.type);

    final profilePhoto = data['profilePhoto'] ?? '';
    final date = DateFormat('dd/MM/yyyy').format(notification.timestamp);

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
          if (username != null && username.isNotEmpty) {
            Navigator.pushNamed(context, '/profile/user', arguments: username);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade50,
                backgroundImage:
                    (profilePhoto != null && profilePhoto.isNotEmpty)
                    ? NetworkImage(profilePhoto)
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

              // Text Content
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
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon (Indicate navigation)
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
        return 'Connection Request'; // Or handle specific accepted types
      case 'connection_request':
        return 'Connection Request';
      case 'photo_access_request':
        return 'Photo Access';
      default:
        return 'Notification';
    }
  }
}
