import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connections_provider.dart';
import '../widgets/request_card.dart';

class InvitesTab extends StatelessWidget {
  const InvitesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionsProvider>(
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
              final requestId = request['_id'] as String;
              final requestType = request['type'] as String? ?? 'connection';

              return RequestCard(
                request: request,
                isLoading: provider.isLoading,
                onAccept: () {
                  if (requestType == 'connection') {
                    provider.accept(requestId);
                  } else if (requestType == 'photo') {
                    provider.respondPhotoRequest(requestId, 'grant');
                  } else if (requestType == 'details') {
                    provider.respondDetailsRequest(requestId, 'grant');
                  }
                },
                onReject: () {
                  if (requestType == 'connection') {
                    provider.reject(requestId);
                  } else if (requestType == 'photo') {
                    provider.respondPhotoRequest(requestId, 'reject');
                  } else if (requestType == 'details') {
                    provider.respondDetailsRequest(requestId, 'reject');
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No pending invites',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
