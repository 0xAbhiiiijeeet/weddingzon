import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class PropertyAssetsForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const PropertyAssetsForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Property & Assets',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Optional information',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            initialValue: provider.formData['land_area']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Land Area (in Acres)',
              border: OutlineInputBorder(),
              hintText: 'e.g., 5.5',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => provider.updateField(
              'land_area',
              v.isEmpty ? null : double.tryParse(v),
            ),
            onSaved: (v) => provider.updateField(
              'land_area',
              v != null && v.isNotEmpty ? double.tryParse(v) : null,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['property_type'],
            decoration: const InputDecoration(
              labelText: 'Property Type (Optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g., Residential, Commercial, Agricultural',
            ),
            onChanged: (v) => provider.updateField('property_type', v),
            onSaved: (v) => provider.updateField('property_type', v),
          ),
        ],
      ),
    );
  }
}
