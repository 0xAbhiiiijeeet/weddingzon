import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import '../models/profile_viewer_model.dart';
import '../repositories/user_repository.dart';

class ProfileViewersScreen extends StatefulWidget {
  const ProfileViewersScreen({super.key});

  @override
  State<ProfileViewersScreen> createState() => _ProfileViewersScreenState();
}

class _ProfileViewersScreenState extends State<ProfileViewersScreen> {
  late Future<List<ProfileViewer>> _viewersFuture;
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    // Assuming context.read<ApiService>() is available, or get from provider
    // Ideally this should be in a Provider/Cubit
    final apiService = context.read<ApiService>();
    _userRepository = UserRepository(apiService);
    _loadViewers();
  }

  void _loadViewers() {
    setState(() {
      _viewersFuture = _fetchViewers();
    });
  }

  Future<List<ProfileViewer>> _fetchViewers() async {
    final response = await _userRepository.getProfileViewers();
    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load viewers');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Who Viewed Your Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<ProfileViewer>>(
        future: _viewersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  TextButton(
                    onPressed: _loadViewers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No views yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final viewers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewers.length,
            itemBuilder: (context, index) {
              final viewer = viewers[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(viewer.username),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: viewer.profilePhoto.isNotEmpty
                              ? CachedNetworkImageProvider(viewer.profilePhoto)
                              : null,
                          child: viewer.profilePhoto.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewer
                                  .username, // Assuming response has username, usually it might have fullName too
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(viewer.viewedAt.toLocal()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _navigateToProfile(viewer.username),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade50,
                          foregroundColor: Colors.pink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.pink.shade100),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToProfile(String username) {
    if (username.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.userProfile, arguments: username);
    }
  }
}
