import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isLoading;

  const RequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final requester = request['requester'] as Map<String, dynamic>?;
    if (requester == null) return const SizedBox.shrink();

    final username = requester['username'] ?? 'Unknown';
    final firstName = requester['first_name'] ?? '';
    final lastName = requester['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : username;
    final profilePhoto = requester['profilePhoto'] ?? '';
    final occupation = requester['occupation'] ?? 'Occupation N/A';
    final requestType = request['type'] as String? ?? 'connection';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: profilePhoto.isNotEmpty
                  ? NetworkImage(profilePhoto)
                  : null,
              child: profilePhoto.isEmpty
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  _buildTypeBadge(requestType),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Profession/Details
                  Text(
                    occupation,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Buttons
            Column(
              children: [
                _buildAcceptButton(),
                const SizedBox(height: 8),
                _buildRejectButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color bgColor;
    Color textColor;
    String text;

    switch (type.toLowerCase()) {
      case 'connection':
        bgColor = const Color(0xFFFFEBEE); // Pinkish light
        textColor = const Color(0xFFE91E63); // Pink
        text = 'Connection';
        break;
      case 'photo':
        bgColor = const Color(0xFFE3F2FD); // Blueish light
        textColor = const Color(0xFF2196F3); // Blue
        text = 'Photo Access';
        break;
      case 'details':
        bgColor = const Color(0xFFE3F2FD); // Blueish light
        textColor = const Color(0xFF2196F3); // Blue
        text = 'Details Access';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = 'Request';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAcceptButton() {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: isLoading ? null : onAccept,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37), // Gold/Mustard
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 16),
            SizedBox(width: 4),
            Text(
              'Accept',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectButton() {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: isLoading ? null : onReject,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.close, size: 16),
            SizedBox(width: 4),
            Text(
              'Reject',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
