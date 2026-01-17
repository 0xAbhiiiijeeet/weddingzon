// ignore_for_file: dead_code

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

          // Father's Occupation/Status
          DropdownButtonFormField<String>(
            initialValue: provider.formData['father_status'],
            decoration: const InputDecoration(
              labelText: "Father's Occupation/Status",
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

          // Mother's Occupation/Status
          DropdownButtonFormField<String>(
            initialValue: provider.formData['mother_status'],
            decoration: const InputDecoration(
              labelText: "Mother's Occupation/Status",
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

          // Brothers
          TextFormField(
            initialValue: provider.formData['brothers']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Number of Brothers (0-10)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final num = int.tryParse(v);
                if (num == null || num < 0 || num > 10) {
                  return 'Enter a number between 0 and 10';
                }
              }
              return null;
            },
            onChanged: (v) =>
                provider.updateField('brothers', int.tryParse(v ?? '') ?? 0),
            onSaved: (v) =>
                provider.updateField('brothers', int.tryParse(v ?? '') ?? 0),
          ),
          const SizedBox(height: 16),

          // Sisters
          TextFormField(
            initialValue: provider.formData['sisters']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Number of Sisters (0-10)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final num = int.tryParse(v);
                if (num == null || num < 0 || num > 10) {
                  return 'Enter a number between 0 and 10';
                }
              }
              return null;
            },
            onChanged: (v) =>
                provider.updateField('sisters', int.tryParse(v ?? '') ?? 0),
            onSaved: (v) =>
                provider.updateField('sisters', int.tryParse(v ?? '') ?? 0),
          ),
          const SizedBox(height: 16),

          // Family Status
          DropdownButtonFormField<String>(
            initialValue: provider.formData['family_status'],
            decoration: const InputDecoration(
              labelText: 'Family Status',
              border: OutlineInputBorder(),
            ),
            items: [
              'Middle Class',
              'Upper Middle Class',
              'Rich',
              'Affluent',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('family_status', v),
            onSaved: (v) => provider.updateField('family_status', v),
          ),
          const SizedBox(height: 16),

          // Family Type
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
          const SizedBox(height: 16),

          // Family Values
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

          // Family Annual Income
          DropdownButtonFormField<String>(
            initialValue: provider.formData['annual_income'],
            decoration: const InputDecoration(
              labelText: 'Family Annual Income',
              border: OutlineInputBorder(),
            ),
            items: [
              'Below 5 LPA',
              '5-10 LPA',
              '10-15 LPA',
              '15-20 LPA',
              '20-30 LPA',
              'Above 30 LPA',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('annual_income', v),
            onSaved: (v) => provider.updateField('annual_income', v),
          ),
          const SizedBox(height: 16),

          // Family Location
          TextFormField(
            initialValue: provider.formData['family_location'],
            decoration: const InputDecoration(
              labelText: 'Family Location',
              border: OutlineInputBorder(),
              hintText: 'City where your family lives',
            ),
            onChanged: (v) => provider.updateField('family_location', v),
            onSaved: (v) => provider.updateField('family_location', v),
          ),
        ],
      ),
    );
  }
}
