import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:open_file/open_file.dart';

class FranchiseDashboard extends StatefulWidget {
  const FranchiseDashboard({super.key});

  @override
  State<FranchiseDashboard> createState() => _FranchiseDashboardState();
}

class _FranchiseDashboardState extends State<FranchiseDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FranchiseProvider>().loadProfiles();
    });
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final franchiseName = authProvider.currentUser?.franchiseDetails?['name'] ?? 
                         authProvider.currentUser?.fullName ?? 
                         'Franchise';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(franchiseName),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Verified Franchise',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
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
      body: Consumer<FranchiseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profiles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalMembers = provider.profiles.length;
          final activeProfiles = provider.profiles.where((p) => p.status == 'active').length;
          final pendingActions = provider.profiles.where((p) => 
            p.photos.isEmpty || p.aboutMe == null || p.aboutMe!.isEmpty
          ).length;

          if (provider.profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No members yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first member to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadProfiles(),
            child: Column(
              children: [
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatsCard(
                        'Total Members',
                        totalMembers.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatsCard(
                        'Active Profiles',
                        activeProfiles.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatsCard(
                        'Pending Actions',
                        pendingActions.toString(),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
                // Member List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.profiles.length,
                    itemBuilder: (context, index) {
                      final member = provider.profiles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.profilePhoto != null
                                ? NetworkImage(member.profilePhoto!)
                                : null,
                            child: member.profilePhoto == null
                                ? Text((member.firstName?.isNotEmpty ?? false) 
                                    ? member.firstName![0].toUpperCase() 
                                    : 'U')
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.fullName ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (member.createdFor != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member.createdFor == 'Self' 
                                        ? Colors.purple.withValues(alpha: 0.1)
                                        : Colors.pink.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    member.createdFor!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: member.createdFor == 'Self' 
                                          ? Colors.purple 
                                          : Colors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              if (member.photos.isEmpty || member.aboutMe == null || member.aboutMe!.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning, size: 10, color: Colors.orange),
                                      SizedBox(width: 2),
                                      Text(
                                        'Incomplete',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'ID: ${member.username ?? member.id.substring(0, 8)} • ${_calculateAge(member.dob)} yrs • ${member.city ?? "Location not set"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'feed',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Feed'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'preferences',
                                child: Row(
                                  children: [
                                    Icon(Icons.favorite, size: 20),
                                    SizedBox(width: 8),
                                    Text('Preferences'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, size: 20),
                                    SizedBox(width: 8),
                                    Text('Download PDF'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'feed') {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.viewAsFeed,
                                  arguments: {
                                    'viewAs': member.id,
                                    'viewAsName': member.fullName ?? 'Member',
                                  },
                                );
                              } else if (value == 'edit') {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.franchiseAddMember,
                                  arguments: member,
                                );
                              } else if (value == 'preferences') {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.partnerPreferences,
                                  arguments: member.id,
                                );
                              } else if (value == 'pdf') {
                                final pdfPath = await provider.downloadMatchPdf(
                                  member.id,
                                  language: 'english',
                                );
                                if (pdfPath != null && context.mounted) {
                                  await OpenFile.open(pdfPath);
                                }
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.manageMember,
                              arguments: member,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.franchiseAddMember);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }
}
