import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_form_provider.dart';

class FranchiseFamilyForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const FranchiseFamilyForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<FranchiseFormProvider>(
      builder: (context, provider, _) {
        return Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Family Background', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: provider.formData['father_status'],
                decoration: const InputDecoration(labelText: "Father's Status*", border: OutlineInputBorder()),
                items: ['Employed', 'Business', 'Retired', 'Passed Away']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('father_status', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['mother_status'],
                decoration: const InputDecoration(labelText: "Mother's Status*", border: OutlineInputBorder()),
                items: ['Homemaker', 'Employed', 'Business', 'Retired', 'Passed Away']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('mother_status', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['brothers']?.toString() ?? '0',
                decoration: const InputDecoration(labelText: 'Number of Brothers', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => provider.updateField('brothers', int.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['sisters']?.toString() ?? '0',
                decoration: const InputDecoration(labelText: 'Number of Sisters', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => provider.updateField('sisters', int.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['family_status'],
                decoration: const InputDecoration(labelText: 'Family Status*', border: OutlineInputBorder()),
                items: ['Middle Class', 'Upper Middle Class', 'Rich', 'Affluent']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('family_status', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['family_type'],
                decoration: const InputDecoration(labelText: 'Family Type*', border: OutlineInputBorder()),
                items: ['Nuclear', 'Joint']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('family_type', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['family_values'],
                decoration: const InputDecoration(labelText: 'Family Values*', border: OutlineInputBorder()),
                items: ['Traditional', 'Moderate', 'Liberal']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('family_values', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['annual_income'],
                decoration: const InputDecoration(labelText: 'Family Annual Income', border: OutlineInputBorder()),
                items: ['Less than 5 LPA', '5-10 LPA', '10-20 LPA', '20-50 LPA', '50 LPA - 1 Crore', 'Above 1 Crore']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => provider.updateField('annual_income', v),
              ),
            ],
          ),
        );
      },
    );
  }
}