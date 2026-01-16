import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class FamilyBackgroundForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const FamilyBackgroundForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Family Background',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['father_status'],
            decoration: const InputDecoration(
              labelText: "Father's Status",
              border: OutlineInputBorder(),
            ),
            items: [
              'Employed',
              'Business',
              'Retired',
              'Passed Away',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('father_status', v),
            onSaved: (v) => provider.updateField('father_status', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['mother_status'],
            decoration: const InputDecoration(
              labelText: "Mother's Status",
              border: OutlineInputBorder(),
            ),
            items: [
              'Homemaker',
              'Employed',
              'Business',
              'Retired',
              'Passed Away',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('mother_status', v),
            onSaved: (v) => provider.updateField('mother_status', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['brothers']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Number of Brothers',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (v) =>
                provider.updateField('brothers', int.tryParse(v ?? '0') ?? 0),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['sisters']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Number of Sisters',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (v) =>
                provider.updateField('sisters', int.tryParse(v ?? '0') ?? 0),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['family_values'],
            decoration: const InputDecoration(
              labelText: 'Family Values',
              border: OutlineInputBorder(),
            ),
            items: [
              'Traditional',
              'Moderate',
              'Liberal',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('family_values', v),
            onSaved: (v) => provider.updateField('family_values', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['family_type'],
            decoration: const InputDecoration(
              labelText: 'Family Type',
              border: OutlineInputBorder(),
            ),
            items: [
              'Nuclear',
              'Joint',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('family_type', v),
            onSaved: (v) => provider.updateField('family_type', v),
          ),
        ],
      ),
    );
  }
}
