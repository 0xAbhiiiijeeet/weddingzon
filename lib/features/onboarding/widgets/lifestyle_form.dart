import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class LifestyleForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const LifestyleForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Lifestyle & Appearance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['appearance'],
            decoration: const InputDecoration(
              labelText: 'Appearance',
              border: OutlineInputBorder(),
            ),
            items: [
              'Fair',
              'Wheatish',
              'Dark',
              'Very Fair',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('appearance', v),
            onSaved: (v) => provider.updateField('appearance', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['living_status'],
            decoration: const InputDecoration(
              labelText: 'Living Status',
              border: OutlineInputBorder(),
            ),
            items: [
              'With Family',
              'Alone',
              'With Relatives',
              'Hostel/PG',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('living_status', v),
            onSaved: (v) => provider.updateField('living_status', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['eating_habits'],
            decoration: const InputDecoration(
              labelText: 'Eating Habits',
              border: OutlineInputBorder(),
            ),
            items: [
              'Vegetarian',
              'Non-Vegetarian',
              'Eggetarian',
              'Vegan',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('eating_habits', v),
            onSaved: (v) => provider.updateField('eating_habits', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['smoking_habits'],
            decoration: const InputDecoration(
              labelText: 'Smoking',
              border: OutlineInputBorder(),
            ),
            items: [
              'No',
              'Occasionally',
              'Yes',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('smoking_habits', v),
            onSaved: (v) => provider.updateField('smoking_habits', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['drinking_habits'],
            decoration: const InputDecoration(
              labelText: 'Drinking',
              border: OutlineInputBorder(),
            ),
            items: [
              'No',
              'Socially',
              'Yes',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('drinking_habits', v),
            onSaved: (v) => provider.updateField('drinking_habits', v),
          ),
        ],
      ),
    );
  }
}
