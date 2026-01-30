import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_form_provider.dart';

class FranchiseReligionForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const FranchiseReligionForm({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<FranchiseFormProvider>(
      builder: (context, provider, _) {
        return Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Religious Background', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: provider.formData['religion'],
                decoration: const InputDecoration(labelText: 'Religion *', border: OutlineInputBorder()),
                items: ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('religion', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['community'],
                decoration: const InputDecoration(labelText: 'Community / Caste*', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                onChanged: (v) => provider.updateField('community', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['sub_community'],
                decoration: const InputDecoration(labelText: 'Sub Community', border: OutlineInputBorder()),
                onChanged: (v) => provider.updateField('sub_community', v),
              ),
            ],
          ),
        );
      },
    );
  }
}