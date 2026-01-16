import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class LocationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const LocationForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Location',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['country'],
            decoration: const InputDecoration(
              labelText: 'Country *',
              border: OutlineInputBorder(),
            ),
            items: [
              'India',
              'USA',
              'UK',
              'Canada',
              'Australia',
              'Other',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('country', v),
            onSaved: (v) => provider.updateField('country', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['state'],
            decoration: const InputDecoration(
              labelText: 'State *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            onSaved: (v) => provider.updateField('state', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['city'],
            decoration: const InputDecoration(
              labelText: 'City *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            onSaved: (v) => provider.updateField('city', v),
          ),
        ],
      ),
    );
  }
}
