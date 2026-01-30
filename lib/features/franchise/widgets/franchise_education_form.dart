import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_form_provider.dart';

class FranchiseEducationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const FranchiseEducationForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<FranchiseFormProvider>(
      builder: (context, provider, _) {
        return Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Education & Career', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: provider.formData['highest_education'],
                decoration: const InputDecoration(labelText: 'Highest Education *', border: OutlineInputBorder()),
                items: ['High School', 'Diploma', "Bachelor's Degree", "Master's Degree", 'PhD', 'Professional Degree']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('highest_education', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['educational_details'],
                decoration: const InputDecoration(labelText: 'Educational Details', border: OutlineInputBorder(), hintText: 'e.g. B.Tech in CS'),
                onChanged: (v) => provider.updateField('educational_details', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['occupation'] != null &&
                    ['Software Engineer', 'Doctor', 'Teacher', 'Business Owner', 
                     'Government Employee', 'Lawyer', 'Accountant', 'Engineer', 'Other']
                        .contains(provider.formData['occupation'])
                    ? provider.formData['occupation']
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Occupation *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Software Engineer',
                  'Doctor',
                  'Teacher',
                  'Business Owner',
                  'Government Employee',
                  'Lawyer',
                  'Accountant',
                  'Engineer',
                  'Other'
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('occupation', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['employed_in'],
                decoration: const InputDecoration(labelText: 'Employed In*', border: OutlineInputBorder()),
                items: ['Private', 'Government', 'Business', 'Self Employed', 'Not Working']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('employed_in', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['personal_income'],
                decoration: const InputDecoration(labelText: 'Annual Income *', border: OutlineInputBorder()),
                items: ['Less than 5 Lakhs', '5-10 Lakhs', '10-20 Lakhs', '20-50 Lakhs', '50 Lakhs - 1 Crore', 'Above 1 Crore']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('personal_income', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['working_sector'],
                decoration: const InputDecoration(labelText: 'Working Sector', border: OutlineInputBorder(), hintText: 'e.g. IT, Healthcare'),
                onChanged: (v) => provider.updateField('working_sector', v),
              ),
            ],
          ),
        );
      },
    );
  }
}