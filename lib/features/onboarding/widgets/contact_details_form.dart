import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class ContactDetailsForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const ContactDetailsForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Contact Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Read-only Phone Number
          TextFormField(
            initialValue: provider.formData['phone'],
            decoration: const InputDecoration(
              labelText: 'Phone Number (Verified)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.verified, color: Colors.green),
            ),
            readOnly: true,
            enabled: false,
          ),
          const SizedBox(height: 16),

          // Read-only Email
          TextFormField(
            initialValue: provider.formData['email'],
            decoration: const InputDecoration(
              labelText: 'Email (Verified)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.verified, color: Colors.green),
            ),
            readOnly: true,
            enabled: false,
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['alternate_mobile'],
            decoration: const InputDecoration(
              labelText: 'Alternate Mobile Number (Optional)',
              border: OutlineInputBorder(),
              hintText: '10-digit number',
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (v) => provider.updateField('alternate_mobile', v),
            onSaved: (v) => provider.updateField('alternate_mobile', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['suitable_time_to_call'],
            decoration: const InputDecoration(
              labelText: 'Suitable Time to Call',
              border: OutlineInputBorder(),
            ),
            items: [
              'Morning (6 AM - 12 PM)',
              'Afternoon (12 PM - 6 PM)',
              'Evening (6 PM - 10 PM)',
              'Anytime',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('suitable_time_to_call', v),
            onSaved: (v) => provider.updateField('suitable_time_to_call', v),
          ),
        ],
      ),
    );
  }
}
