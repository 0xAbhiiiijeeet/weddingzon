import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../providers/franchise_provider.dart';
import '../../../core/models/user_model.dart';
import 'package:open_file/open_file.dart';

class ManageMemberScreen extends StatelessWidget {
  final User member;

  const ManageMemberScreen({super.key, required this.member});

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
        title: Text(member.fullName ?? 'Unknown'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.franchiseAddMember,
                arguments: member,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: member.profilePhoto != null
                    ? NetworkImage(member.profilePhoto!)
                    : null,
                child: member.profilePhoto == null
                    ? Text(
                        (member.firstName?.isNotEmpty ?? false) ? member.firstName![0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 40),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Basic Information',
              [
                _buildInfoRow('Name', member.fullName ?? 'Not specified'),
                _buildInfoRow('Age', '${_calculateAge(member.dob)} years'),
                _buildInfoRow('Gender', member.gender ?? 'Not specified'),
                _buildInfoRow('Height', member.height ?? 'Not specified'),
                _buildInfoRow('Marital Status', member.maritalStatus?.toString() ?? 'Not specified'),
              ],
            ),

            if (member.phone != null || member.email != null)
              _buildSection(
                'Contact',
                [
                  if (member.phone != null) _buildInfoRow('Phone', member.phone!),
                  if (member.email != null) _buildInfoRow('Email', member.email!),
                ],
              ),

            _buildSection(
              'Location',
              [
                _buildInfoRow('City', member.city ?? 'Not specified'),
                _buildInfoRow('State', member.state ?? 'Not specified'),
                _buildInfoRow('Country', member.country ?? 'Not specified'),
              ],
            ),

            _buildSection(
              'Professional',
              [
                _buildInfoRow('Education', member.highestEducation ?? 'Not specified'),
                _buildInfoRow('Occupation', member.occupation ?? 'Not specified'),
                _buildInfoRow('Employed In', member.employedIn ?? 'Not specified'),
                _buildInfoRow('Income', member.personalIncome ?? 'Not specified'),
              ],
            ),

            _buildSection(
              'Religious Background',
              [
                _buildInfoRow('Religion', member.religion ?? 'Not specified'),
                _buildInfoRow('Community', member.community ?? 'Not specified'),
              ],
            ),

            if (member.photos.isNotEmpty) ...[
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
                itemCount: member.photos.length,
                itemBuilder: (context, index) {
                  final photo = member.photos[index];
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.partnerPreferences,
                    arguments: member.id,
                  );
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Partner Preferences'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final provider = context.read<FranchiseProvider>();
                  final pdfPath = await provider.downloadMatchPdf(
                    member.id,
                    language: 'english',
                  );
                  if (pdfPath != null && context.mounted) {
                    await OpenFile.open(pdfPath);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Match PDF'),
              ),
            ),
          ],
        ),
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
