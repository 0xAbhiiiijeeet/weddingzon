import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class BasicDetailsForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const BasicDetailsForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Basic Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          TextFormField(
            initialValue: provider.formData['first_name'],
            decoration: const InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            onSaved: (v) => provider.updateField('first_name', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['last_name'],
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            onSaved: (v) => provider.updateField('last_name', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['dob'],
            decoration: const InputDecoration(
              labelText: 'Date of Birth (YYYY-MM-DD) *',
              border: OutlineInputBorder(),
              hintText: '1995-05-15',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            onSaved: (v) => provider.updateField('dob', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['gender'],
            decoration: const InputDecoration(
              labelText: 'Gender *',
              border: OutlineInputBorder(),
            ),
            items: [
              'Male',
              'Female',
              'Other',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('gender', v),
            onSaved: (v) => provider.updateField('gender', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['height'],
            decoration: const InputDecoration(
              labelText: 'Height',
              border: OutlineInputBorder(),
            ),
            items: List.generate(36, (i) {
              int feet = 4 + (i ~/ 12);
              int inches = i % 12;
              return DropdownMenuItem(
                value: "$feet'$inches\"",
                child: Text("$feet'$inches\""),
              );
            }),
            onChanged: (v) => provider.updateField('height', v),
            onSaved: (v) => provider.updateField('height', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['marital_status'],
            decoration: const InputDecoration(
              labelText: 'Marital Status *',
              border: OutlineInputBorder(),
            ),
            items: [
              'Never Married',
              'Divorced',
              'Widowed',
              'Separated',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('marital_status', v),
            onSaved: (v) => provider.updateField('marital_status', v),
          ),
        ],
      ),
    );
  }
}
