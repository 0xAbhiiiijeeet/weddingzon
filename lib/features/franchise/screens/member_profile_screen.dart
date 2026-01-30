import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: user.profilePhoto != null
                        ? NetworkImage(user.profilePhoto!)
                        : null,
                    child: user.profilePhoto == null
                        ? Text(
                            (user.firstName?.isNotEmpty ?? false) ? user.firstName![0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                _buildSection(
                  'Basic Information',
                  [
                    _buildInfoRow('Name', user.fullName ?? 'Not specified'),
                    _buildInfoRow('Username', user.username ?? 'Not specified'),
                    _buildInfoRow('Age', '${_calculateAge(user.dob)} years'),
                    _buildInfoRow('Gender', user.gender ?? 'Not specified'),
                    _buildInfoRow('Height', user.height ?? 'Not specified'),
                    _buildInfoRow('Marital Status', user.maritalStatus?.toString() ?? 'Not specified'),
                  ],
                ),

                if (user.phone != null || user.email != null)
                  _buildSection(
                    'Contact',
                    [
                      if (user.phone != null) _buildInfoRow('Phone', user.phone!),
                      if (user.email != null) _buildInfoRow('Email', user.email!),
                    ],
                  ),

                _buildSection(
                  'Location',
                  [
                    _buildInfoRow('City', user.city ?? 'Not specified'),
                    _buildInfoRow('State', user.state ?? 'Not specified'),
                    _buildInfoRow('Country', user.country ?? 'Not specified'),
                  ],
                ),

                _buildSection(
                  'Professional',
                  [
                    _buildInfoRow('Education', user.highestEducation ?? 'Not specified'),
                    _buildInfoRow('Occupation', user.occupation ?? 'Not specified'),
                    _buildInfoRow('Employed In', user.employedIn ?? 'Not specified'),
                    _buildInfoRow('Income', user.personalIncome ?? 'Not specified'),
                  ],
                ),

                _buildSection(
                  'Religious Background',
                  [
                    _buildInfoRow('Religion', user.religion ?? 'Not specified'),
                    _buildInfoRow('Community', user.community ?? 'Not specified'),
                  ],
                ),

                if (user.aboutMe != null && user.aboutMe!.isNotEmpty)
                  _buildSection(
                    'About Me',
                    [
                      Text(
                        user.aboutMe!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                if (user.photos.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Photos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: user.photos.length,
                    itemBuilder: (context, index) {
                      final photo = user.photos[index];
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Image.network(photo.url),
                            ),
                          );
                        },
                        child: Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your profile is managed by your franchise. Contact them for any updates.',
                          style: TextStyle(color: Colors.blue[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
