import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partner_preference.dart';
import '../providers/franchise_provider.dart';

class PartnerPreferencesScreen extends StatefulWidget {
  const PartnerPreferencesScreen({super.key});

  @override
  State<PartnerPreferencesScreen> createState() =>
      _PartnerPreferencesScreenState();
}

class _PartnerPreferencesScreenState extends State<PartnerPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _memberId;
  bool _isLoading = false;

  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();
  final TextEditingController _minHeightController = TextEditingController();
  final TextEditingController _maxHeightController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _annualIncomeController = TextEditingController();

  String? _religion;
  String? _maritalStatus;
  String? _eatingHabits;
  String? _smokingHabits;
  String? _drinkingHabits;
  String? _highestEducation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _memberId == null) {
      _memberId = args;
      _fetchPreferences();
    }
  }

  Future<void> _fetchPreferences() async {
    if (_memberId == null) return;

    debugPrint('[PARTNER_PREFS_SCREEN] 🔵 _fetchPreferences - Fetching for member: $_memberId');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);

      final prefs = await context.read<FranchiseProvider>().getPreferences(
        _memberId!,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (prefs != null) {
          debugPrint('[PARTNER_PREFS_SCREEN] ✅ _fetchPreferences - Received preferences: $prefs');
          _populateForm(prefs);
        } else {
          debugPrint('[PARTNER_PREFS_SCREEN] ⚠️ _fetchPreferences - No preferences found');
        }
      }
    });
  }

  void _populateForm(Map<String, dynamic> json) {
    debugPrint('[PARTNER_PREFS_SCREEN] 🔵 _populateForm - Populating form with data');
    debugPrint('[PARTNER_PREFS_SCREEN] 📦 _populateForm - Raw JSON from backend: $json');

    final prefs = PartnerPreference.fromJson(json);

    debugPrint('[PARTNER_PREFS_SCREEN] 🔢 _populateForm - Parsed - minAge: ${prefs.minAge}, maxAge: ${prefs.maxAge}');
    debugPrint('[PARTNER_PREFS_SCREEN] 📝 _populateForm - Parsed - religion: ${prefs.religion}, maritalStatus: ${prefs.maritalStatus}');
    debugPrint('[PARTNER_PREFS_SCREEN] 💰 _populateForm - Parsed - annualIncome: ${prefs.annualIncome}');

    if (prefs.minAge != null) {
      _minAgeController.text = prefs.minAge!.toString();
      debugPrint('[PARTNER_PREFS_SCREEN] ✏️ _populateForm - Set minAge: ${_minAgeController.text}');
    }
    if (prefs.maxAge != null) {
      _maxAgeController.text = prefs.maxAge!.toString();
      debugPrint('[PARTNER_PREFS_SCREEN] ✏️ _populateForm - Set maxAge: ${_maxAgeController.text}');
    }
    if (prefs.heightMin != null) {
      _minHeightController.text = prefs.heightMin!;
    }
    if (prefs.heightMax != null) {
      _maxHeightController.text = prefs.heightMax!;
    }
    if (prefs.occupation != null) {
      _occupationController.text = prefs.occupation!;
    }
    if (prefs.annualIncome != null) {
      _annualIncomeController.text = prefs.annualIncome!.toString();
      debugPrint('[PARTNER_PREFS_SCREEN] ✏️ _populateForm - Set annualIncome: ${_annualIncomeController.text}');
    }

    setState(() {
      _religion = prefs.religion;
      _maritalStatus = prefs.maritalStatus?.firstOrNull;
      _eatingHabits = prefs.eatingHabits;
      _smokingHabits = prefs.smokingHabits;
      _drinkingHabits = prefs.drinkingHabits;
      _highestEducation = prefs.highestEducation;
    });

    debugPrint('[PARTNER_PREFS_SCREEN] ✅ _populateForm - Form populated successfully');
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _minHeightController.dispose();
    _maxHeightController.dispose();
    _occupationController.dispose();
    _annualIncomeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    debugPrint('[PARTNER_PREFS_SCREEN] 🔘 _submit - Button clicked');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[PARTNER_PREFS_SCREEN] ⚠️ _submit - Form validation failed');
      return;
    }
    if (_memberId == null) {
      debugPrint('[PARTNER_PREFS_SCREEN] ❌ _submit - No member ID');
      return;
    }

    debugPrint('[PARTNER_PREFS_SCREEN] 🔵 _submit - Starting submission for member: $_memberId');
    setState(() => _isLoading = true);

    final prefs = PartnerPreference(
      minAge: int.tryParse(_minAgeController.text.trim()),
      maxAge: int.tryParse(_maxAgeController.text.trim()),
      heightMin: _minHeightController.text.trim().isNotEmpty
          ? _minHeightController.text.trim()
          : null,
      heightMax: _maxHeightController.text.trim().isNotEmpty
          ? _maxHeightController.text.trim()
          : null,
      religion: _religion,
      maritalStatus: _maritalStatus != null ? [_maritalStatus!] : null,
      eatingHabits: _eatingHabits,
      smokingHabits: _smokingHabits,
      drinkingHabits: _drinkingHabits,
      highestEducation: _highestEducation,
      occupation: _occupationController.text.trim().isNotEmpty
          ? _occupationController.text.trim()
          : null,
      annualIncome: int.tryParse(_annualIncomeController.text.trim()),
    );

    debugPrint('[PARTNER_PREFS_SCREEN] 📤 _submit - Submitting preferences: ${prefs.toJson()}');

    final success = await context.read<FranchiseProvider>().updatePreferences(
      _memberId!,
      prefs.toJson(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        debugPrint('[PARTNER_PREFS_SCREEN] ✅ _submit - Preferences saved successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = context.read<FranchiseProvider>().error;
        debugPrint('[PARTNER_PREFS_SCREEN] ❌ _submit - Failed to save: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.isNotEmpty ? error : 'Failed to update preferences'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Preferences')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minAgeController,
                      decoration: const InputDecoration(
                        labelText: 'Min Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAgeController,
                      decoration: const InputDecoration(
                        labelText: 'Max Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minHeightController,
                      decoration: const InputDecoration(
                        labelText: 'Min Height',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxHeightController,
                      decoration: const InputDecoration(
                        labelText: 'Max Height',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Religion',
                value: _religion,
                items: const [
                  'Hindu',
                  'Muslim',
                  'Christian',
                  'Sikh',
                  'Buddhist',
                  'Jain',
                  'Other',
                ],
                onChanged: (val) => setState(() => _religion = val),
              ),
              _buildDropdown(
                label: 'Marital Status',
                value: _maritalStatus,
                items: const [
                  'Never Married',
                  'Divorced',
                  'Widowed',
                  'Awaiting Divorce',
                ],
                onChanged: (val) => setState(() => _maritalStatus = val),
              ),
              _buildDropdown(
                label: 'Eating Habits',
                value: _eatingHabits,
                items: const [
                  'Vegetarian',
                  'Non-Vegetarian',
                  'Eggetarian',
                  'Vegan',
                ],
                onChanged: (val) => setState(() => _eatingHabits = val),
              ),
              _buildDropdown(
                label: 'Smoking Habits',
                value: _smokingHabits,
                items: const ['No', 'Occasionally', 'Yes'],
                onChanged: (val) => setState(() => _smokingHabits = val),
              ),
              _buildDropdown(
                label: 'Drinking Habits',
                value: _drinkingHabits,
                items: const ['No', 'Socially', 'Yes'],
                onChanged: (val) => setState(() => _drinkingHabits = val),
              ),
              _buildDropdown(
                label: 'Highest Education',
                value: _highestEducation,
                items: const [
                  'High School',
                  'Diploma',
                  "Bachelor's Degree",
                  "Master's Degree",
                  'PhD',
                  'Professional Degree',
                  'Other',
                ],
                onChanged: (val) => setState(() => _highestEducation = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Engineer',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _annualIncomeController,
                decoration: const InputDecoration(
                  labelText: 'Min Annual Income',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Preferences',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}