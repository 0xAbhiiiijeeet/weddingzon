import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';

class EducationCareerForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const EducationCareerForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingProvider>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Education & Career',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['highest_education'],
            decoration: const InputDecoration(
              labelText: 'Highest Education *',
              border: OutlineInputBorder(),
            ),
            items: [
              'High School',
              'Diploma',
              "Bachelor's Degree",
              "Master's Degree",
              'PhD',
              'Professional Degree',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('highest_education', v),
            onSaved: (v) => provider.updateField('highest_education', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['educational_details'],
            decoration: const InputDecoration(
              labelText: 'Educational Details',
              border: OutlineInputBorder(),
              hintText: 'e.g. B.Tech in CS',
            ),
            onChanged: (v) => provider.updateField('educational_details', v),
            onSaved: (v) => provider.updateField('educational_details', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['occupation'],
            decoration: const InputDecoration(
              labelText: 'Occupation *',
              border: OutlineInputBorder(),
              hintText: 'Software Engineer, Doctor, etc.',
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            onChanged: (v) => provider.updateField('occupation', v),
            onSaved: (v) => provider.updateField('occupation', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['employed_in'],
            decoration: const InputDecoration(
              labelText: 'Employed In*',
              border: OutlineInputBorder(),
            ),
            items: [
              'Private',
              'Government',
              'Business',
              'Self Employed',
              'Not Working',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('employed_in', v),
            onSaved: (v) => provider.updateField('employed_in', v),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: provider.formData['personal_income'],
            decoration: const InputDecoration(
              labelText: 'Annual Income*',
              border: OutlineInputBorder(),
            ),
            items: [
              'Less than 5 Lakhs',
              '5-10 Lakhs',
              '10-20 Lakhs',
              '20-50 Lakhs',
              '50 Lakhs - 1 Crore',
              'Above 1 Crore',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            validator: (v) => v == null ? 'Required' : null,
            onChanged: (v) => provider.updateField('personal_income', v),
            onSaved: (v) => provider.updateField('personal_income', v),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: provider.formData['working_sector'],
            decoration: const InputDecoration(
              labelText: 'Working Sector (Optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g. IT, Healthcare',
            ),
            onChanged: (v) => provider.updateField('working_sector', v),
            onSaved: (v) => provider.updateField('working_sector', v),
          ),
        ],
      ),
    );
  }
}
