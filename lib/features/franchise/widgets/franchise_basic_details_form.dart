import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/franchise_form_provider.dart';

class FranchiseBasicDetailsForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const FranchiseBasicDetailsForm({super.key, required this.formKey});

  @override
  State<FranchiseBasicDetailsForm> createState() => _FranchiseBasicDetailsFormState();
}

class _FranchiseBasicDetailsFormState extends State<FranchiseBasicDetailsForm> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Consumer<FranchiseFormProvider>(
      builder: (context, provider, _) {
        return Form(
          key: widget.formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Basic Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: provider.formData['created_for'],
                decoration: const InputDecoration(
                  labelText: 'Profile Created For*',
                  border: OutlineInputBorder(),
                ),
                items: ['Self', 'Son', 'Daughter', 'Brother', 'Sister', 'Friend', 'Relative']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('created_for', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['first_name'],
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                onChanged: (v) => provider.updateField('first_name', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['last_name'],
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                onChanged: (v) => provider.updateField('last_name', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['phone'],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  hintText: '+919876543210',
                  helperText: 'Include country code (e.g., +91)',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(v)) {
                      return 'Enter valid phone with country code';
                    }
                  }
                  return null;
                },
                onChanged: (v) => provider.updateField('phone', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['email'],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'example@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
                onChanged: (v) => provider.updateField('email', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _selectedDate != null || provider.formData['dob'] != null
                      ? (provider.formData['dob'] as String?)?.split('T')[0] ?? ''
                      : '',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
                    helpText: 'Select Date of Birth',
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    provider.updateField('dob', picked.toIso8601String());
                    // Force rebuild to show age immediately
                    setState(() {});
                  }
                },
                validator: (v) => provider.formData['dob'] == null ? 'Date of Birth is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: ValueKey(provider.formData['age']), // Force rebuild when age changes
                initialValue: provider.formData['age']?.toString() ?? '',
                readOnly: true,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  hintText: 'Auto-calculated from DOB',
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['gender'],
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('gender', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['height'],
                decoration: const InputDecoration(
                  labelText: 'Height*',
                  border: OutlineInputBorder(),
                ),
                items: ['4\'6"', '4\'8"', '4\'10"', '5\'0"', '5\'2"', '5\'4"', '5\'6"', '5\'8"', '5\'10"', '6\'0"', '6\'2"', '6\'4"']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('height', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['marital_status'],
                decoration: const InputDecoration(
                  labelText: 'Marital Status *',
                  border: OutlineInputBorder(),
                ),
                items: ['Never Married', 'Divorced', 'Widowed', 'Awaiting Divorce']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('marital_status', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['mother_tongue'],
                decoration: const InputDecoration(
                  labelText: 'Mother Tongue*',
                  border: OutlineInputBorder(),
                ),
                items: ['Hindi', 'English', 'Marathi', 'Tamil', 'Telugu', 'Bengali', 'Gujarati', 'Kannada', 'Malayalam', 'Punjabi']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => provider.updateField('mother_tongue', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['disability'],
                decoration: const InputDecoration(
                  labelText: 'Disability Status',
                  border: OutlineInputBorder(),
                ),
                items: ['None', 'Physical', 'Mental', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => provider.updateField('disability', v),
              ),
              if (provider.formData['disability'] != null && provider.formData['disability'] != 'None') ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: provider.formData['disability_description'],
                  decoration: const InputDecoration(
                    labelText: 'Disability Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (v) => provider.updateField('disability_description', v),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['aadhar_number'],
                decoration: const InputDecoration(
                  labelText: 'Aadhar Number (Optional)',
                  border: OutlineInputBorder(),
                  hintText: '12-digit number',
                ),
                keyboardType: TextInputType.number,
                maxLength: 12,
                onChanged: (v) => provider.updateField('aadhar_number', v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: provider.formData['blood_group'],
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => provider.updateField('blood_group', v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: provider.formData['about_me'],
                decoration: const InputDecoration(
                  labelText: 'About Me *',
                  border: OutlineInputBorder(),
                  hintText: 'Write a brief description about yourself (minimum 50 characters)',
                  helperText: 'Minimum 50 characters required',
                ),
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'About Me is required';
                  }
                  final charCount = v.trim().length;
                  if (charCount < 50) {
                    return 'Please write at least 50 characters (current: $charCount)';
                  }
                  return null;
                },
                onChanged: (v) => provider.updateField('about_me', v),
              ),
            ],
          ),
        );
      },
    );
  }
}