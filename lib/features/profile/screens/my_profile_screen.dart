import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/models/user_model.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await authProvider.checkAuthStatus();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 24),

                  _buildActionButtons(context),
                  const SizedBox(height: 24),

                  _buildSection(
                    title: 'Basic Details',
                    icon: Icons.person,
                    children: [
                      _buildInfoRow('Name', user.fullName ?? 'Not set'),
                      _buildInfoRow('Gender', user.gender ?? 'Not set'),
                      _buildInfoRow('Phone', user.phoneNumber ?? 'Not set'),
                      _buildInfoRow('Email', user.email ?? 'Not set'),
                      _buildInfoRow('Height', user.height ?? 'Not set'),
                      _buildInfoRow(
                        'Marital Status',
                        user.maritalStatus ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Mother Tongue',
                        user.motherTongue ?? 'Not set',
                      ),
                    ],
                  ),

                  _buildSection(
                    title: 'Location',
                    icon: Icons.location_on,
                    children: [
                      _buildInfoRow('City', user.city ?? 'Not set'),
                      _buildInfoRow('State', user.state ?? 'Not set'),
                      _buildInfoRow('Country', user.country ?? 'Not set'),
                    ],
                  ),

                  _buildSection(
                    title: 'Family Background',
                    icon: Icons.family_restroom,
                    children: [
                      _buildInfoRow(
                        'Father Status',
                        user.fatherStatus ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Mother Status',
                        user.motherStatus ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Brothers',
                        user.brothers?.toString() ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Sisters',
                        user.sisters?.toString() ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Family Type',
                        user.familyType ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Family Status',
                        user.familyStatus ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Family Values',
                        user.familyValues ?? 'Not set',
                      ),
                    ],
                  ),

                  _buildSection(
                    title: 'Education & Career',
                    icon: Icons.work,
                    children: [
                      _buildInfoRow(
                        'Education',
                        user.highestEducation ?? 'Not set',
                      ),
                      _buildInfoRow('Occupation', user.occupation ?? 'Not set'),
                      _buildInfoRow(
                        'Employed In',
                        user.employedIn ?? 'Not set',
                      ),
                      _buildInfoRow(
                        'Personal Income',
                        user.personalIncome ?? 'Not set',
                      ),
                    ],
                  ),

                  _buildSection(
                    title: 'Lifestyle & Preferences',
                    icon: Icons.favorite,
                    children: [
                      _buildInfoRow('Religion', user.religion ?? 'Not set'),
                      _buildInfoRow('Community', user.community ?? 'Not set'),
                      _buildInfoRow(
                        'Eating Habits',
                        user.eatingHabits ?? 'Not set',
                      ),
                      _buildInfoRow('Smoking', user.smokingHabits ?? 'Not set'),
                      _buildInfoRow(
                        'Drinking',
                        user.drinkingHabits ?? 'Not set',
                      ),
                    ],
                  ),

                  if (user.aboutMe != null && user.aboutMe!.isNotEmpty)
                    _buildSection(
                      title: 'About Me',
                      icon: Icons.info,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            user.aboutMe!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              user.profilePhoto != null && user.profilePhoto!.isNotEmpty
              ? CachedNetworkImageProvider(user.profilePhoto!)
              : null,
          child: user.profilePhoto == null || user.profilePhoto!.isEmpty
              ? Text(
                  (user.fullName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),

        Text(
          user.fullName ?? 'Unknown',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        if (user.username != null)
          Text(
            '@${user.username}',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              user.isPhoneVerified
                  ? Icons.verified
                  : Icons.warning_amber_rounded,
              color: user.isPhoneVerified ? Colors.green : Colors.orange,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              user.isPhoneVerified ? 'Verified' : 'Not Verified',
              style: TextStyle(
                color: user.isPhoneVerified ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.editProfile),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.photoManager),
            icon: const Icon(Icons.photo_library),
            label: const Text('Manage Photos'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: value == 'Not set' ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
