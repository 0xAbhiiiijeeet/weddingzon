import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'I am signing up as ...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _RoleCard(
                    icon: Icons.people,
                    title: 'Members',
                    description: 'Find your partner',
                    role: 'member',
                    color: Colors.blue,
                    onTap: () => _selectRole(context, 'member'),
                  ),
                  _RoleCard(
                    icon: Icons.business,
                    title: 'Vendor',
                    description: 'Wedding services',
                    role: 'vendor',
                    color: Colors.orange,
                    onTap: () => _selectRole(context, 'vendor'),
                  ),
                  _RoleCard(
                    icon: Icons.store,
                    title: 'Franchise',
                    description: 'Business partner',
                    role: 'franchise',
                    color: Colors.green,
                    onTap: () => _selectRole(context, 'franchise'),
                  ),
                  _RoleCard(
                    icon: Icons.shopping_cart,
                    title: 'Ecommerce',
                    description: 'Shop wedding products',
                    role: 'ecommerce',
                    color: Colors.purple,
                    onTap: () => _selectRole(context, 'ecommerce'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, String selection) {
    debugPrint('[ONBOARDING] Selection: $selection');

    if (selection == 'ecommerce') {
      Fluttertoast.showToast(msg: "Coming Soon");
      return;
    }

    // Map member to 'member' role, others stay as-is
    final String role;
    final String gender =
        ''; // Gender selection will happen in next screen if needed

    switch (selection) {
      case 'member':
        role = 'member';
        break;
      default:
        role = selection; // vendor, franchise stay as-is
    }

    debugPrint('[ONBOARDING] Mapped to role: $role, gender: $gender');
    Navigator.pushNamed(
      context,
      AppRoutes.profileForm,
      arguments: {'role': role, 'gender': gender},
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String role;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.role,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
