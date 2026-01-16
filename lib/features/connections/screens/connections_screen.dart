import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connections_provider.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionsProvider>().loadIncomingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connection Requests')),
      body: Consumer<ConnectionsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.incomingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.incomingRequests.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadIncomingRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.incomingRequests.length,
              itemBuilder: (context, index) {
                final request = provider.incomingRequests[index];
                return _buildRequestCard(request, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No connection requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone sends you a request, it will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _getRequestTypeChip(String type) {
    Color chipColor;
    String chipLabel;
    IconData chipIcon;

    switch (type.toLowerCase()) {
      case 'connection':
        chipColor = Colors.deepPurple;
        chipLabel = 'Connection Request';
        chipIcon = Icons.person_add;
        break;
      case 'photo':
        chipColor = Colors.blue;
        chipLabel = 'Photo Access';
        chipIcon = Icons.image;
        break;
      case 'details':
        chipColor = Colors.green;
        chipLabel = 'Details Access';
        chipIcon = Icons.contact_page;
        break;
      default:
        chipColor = Colors.grey;
        chipLabel = 'Request';
        chipIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            chipLabel,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> request,
    ConnectionsProvider provider,
  ) {
    final requestId = request['_id'] as String;
    final requester = request['requester'] as Map<String, dynamic>?;
    final status = request['status'] as String? ?? 'pending';
    final createdAt = request['createdAt'] as String? ?? '';
    final requestType = request['type'] as String? ?? 'connection';

    if (requester == null) return const SizedBox.shrink();

    final username = requester['username'] ?? 'Unknown';
    final firstName = requester['first_name'] ?? '';
    final lastName = requester['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : username;
    final profilePhoto = requester['profilePhoto'] ?? '';

    // Parse date
    String timeAgo = '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    } catch (e) {
      timeAgo = '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Type Chip
            _getRequestTypeChip(requestType),
            const SizedBox(height: 12),

            Row(
              children: [
                // Profile photo
                CircleAvatar(
                  radius: 32,
                  backgroundImage: profilePhoto.isNotEmpty
                      ? NetworkImage(profilePhoto)
                      : null,
                  child: profilePhoto.isEmpty
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (timeAgo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons based on request type
            if (status == 'pending')
              ..._buildActionButtons(requestId, requestType, provider)
            else if (status == 'accepted' || status == 'granted') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      requestType == 'connection' ? 'Accepted' : 'Granted',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'rejected') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Declined',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    String requestId,
    String requestType,
    ConnectionsProvider provider,
  ) {
    if (requestType == 'connection') {
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.reject(requestId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.accept(requestId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      ];
    } else if (requestType == 'photo') {
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.respondPhotoRequest(requestId, 'reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Deny'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.respondPhotoRequest(requestId, 'grant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Grant Access'),
              ),
            ),
          ],
        ),
      ];
    } else if (requestType == 'details') {
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.respondDetailsRequest(requestId, 'reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Deny'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.respondDetailsRequest(requestId, 'grant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Grant Access'),
              ),
            ),
          ],
        ),
      ];
    }

    return [];
  }
}
