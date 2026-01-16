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
            'Lifestyle & About You',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['religion'],
            decoration: const InputDecoration(
              labelText: 'Religion *',
              border: OutlineInputBorder(),
            ),
            items: [
              'Hindu',
              'Muslim',
              'Christian',
              'Sikh',
              'Buddhist',
              'Jain',
              'Other',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('religion', v),
            onSaved: (v) => provider.updateField('religion', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['community'],
            decoration: const InputDecoration(
              labelText: 'Community/Caste',
              border: OutlineInputBorder(),
            ),
            onSaved: (v) => provider.updateField('community', v),
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
              'Regularly',
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
              'Regularly',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => provider.updateField('drinking_habits', v),
            onSaved: (v) => provider.updateField('drinking_habits', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['about_me'],
            decoration: const InputDecoration(
              labelText: 'About Me',
              border: OutlineInputBorder(),
              hintText: 'Tell us about yourself...',
            ),
            maxLines: 5,
            maxLength: 500,
            onSaved: (v) => provider.updateField('about_me', v),
          ),
        ],
      ),
    );
  }
}
