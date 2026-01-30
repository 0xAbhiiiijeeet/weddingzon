import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/connections_provider.dart';
import '../../../core/routes/app_routes.dart';

class MyConnectionsScreen extends StatefulWidget {
  const MyConnectionsScreen({super.key});

  @override
  State<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends State<MyConnectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionsProvider>().loadMyConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Connections'), centerTitle: true),
      body: Consumer<ConnectionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingConnections) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myConnections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No connections yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadMyConnections();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myConnections.length,
              itemBuilder: (context, index) {
                final user = provider.myConnections[index];
                return _buildConnectionCard(user);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> user) {
    final username = user['username'] ?? '';
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim().isEmpty
        ? username
        : '$firstName $lastName';
    final profilePhoto = user['profilePhoto'];
    final occupation = user['occupation'] ?? 'Occupation not set';
    final city = user['city'];
    final state = user['state'];
    final location = [
      city,
      state,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _viewProfile(username),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                    ? CachedNetworkImageProvider(profilePhoto)
                    : null,
                child: profilePhoto == null || profilePhoto.isEmpty
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (occupation.isNotEmpty)
                    Text(
                      occupation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 2),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Connected',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed: () => _viewProfile(username),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: const Text(
                'View',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfile(String username) {
    if (username.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.userProfile, arguments: username);
    }
  }
}