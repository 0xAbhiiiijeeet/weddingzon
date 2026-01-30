import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_form_provider.dart';

class FranchiseLifestyleForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const FranchiseLifestyleForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<FranchiseFormProvider>(
      builder: (context, provider, _) {
        return Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Lifestyle & Appearance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: provider.formData['appearance'],
                decoration: const InputDecoration(labelText: 'Appearance*', border: OutlineInputBorder()),
                items: ['Fair', 'Wheatish', 'Dark', 'Very Fair']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('appearance', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['living_status'],
                decoration: const InputDecoration(labelText: 'Living Status*', border: OutlineInputBorder()),
                items: ['With Family', 'Alone', 'With Roommates']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('living_status', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['eating_habits'],
                decoration: const InputDecoration(labelText: 'Eating Habits*', border: OutlineInputBorder()),
                items: ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Vegan']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('eating_habits', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['smoking_habits'],
                decoration: const InputDecoration(labelText: 'Smoking Habits', border: OutlineInputBorder()),
                items: ['No', 'Occasionally', 'Yes']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => provider.updateField('smoking_habits', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['drinking_habits'],
                decoration: const InputDecoration(labelText: 'Drinking Habits', border: OutlineInputBorder()),
                items: ['No', 'Occasionally', 'Yes']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => provider.updateField('drinking_habits', v),
              ),
            ],
          ),
        );
      },
    );
  }
}