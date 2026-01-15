import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ProfileProvider>().initializeEditForm(user);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Location'),
            Tab(text: 'Family'),
            Tab(text: 'Education'),
            Tab(text: 'Lifestyle'),
          ],
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          return Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicDetailsTab(provider),
                _buildLocationTab(provider),
                _buildFamilyTab(provider),
                _buildEducationTab(provider),
                _buildLifestyleTab(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton.extended(
            onPressed: provider.isLoading ? null : () => _saveProfile(provider),
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(provider.isLoading ? 'Saving...' : 'Save Profile'),
          );
        },
      ),
    );
  }

  Widget _buildBasicDetailsTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'First Name',
            initialValue: provider.editFormData['first_name'],
            onSaved: (value) => provider.updateEditField('first_name', value),
            required: true,
          ),
          _buildTextField(
            label: 'Last Name',
            initialValue: provider.editFormData['last_name'],
            onSaved: (value) => provider.updateEditField('last_name', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Height',
            value: provider.editFormData['height'],
            items: [
              '4\'6"',
              '4\'8"',
              '4\'10"',
              '5\'0"',
              '5\'2"',
              '5\'4"',
              '5\'6"',
              '5\'8"',
              '5\'10"',
              '6\'0"',
              '6\'2"',
              '6\'4"',
            ],
            onChanged: (value) => provider.updateEditField('height', value),
          ),
          _buildDropdown(
            label: 'Marital Status',
            value: provider.editFormData['marital_status'],
            items: ['Never Married', 'Divorced', 'Widowed', 'Awaiting Divorce'],
            onChanged: (value) =>
                provider.updateEditField('marital_status', value),
          ),
          _buildDropdown(
            label: 'Mother Tongue',
            value: provider.editFormData['mother_tongue'],
            items: [
              'Hindi',
              'English',
              'Marathi',
              'Tamil',
              'Telugu',
              'Bengali',
              'Gujarati',
              'Kannada',
              'Malayalam',
              'Punjabi',
            ],
            onChanged: (value) =>
                provider.updateEditField('mother_tongue', value),
          ),
          _buildDropdown(
            label: 'Blood Group',
            value: provider.editFormData['blood_group'],
            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
            onChanged: (value) =>
                provider.updateEditField('blood_group', value),
          ),
          _buildTextField(
            label: 'About Me',
            initialValue: provider.editFormData['about_me'],
            onSaved: (value) => provider.updateEditField('about_me', value),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Country',
            value: provider.editFormData['country'],
            items: ['India', 'USA', 'UK', 'Canada', 'Australia'],
            onChanged: (value) => provider.updateEditField('country', value),
          ),
          _buildTextField(
            label: 'State',
            initialValue: provider.editFormData['state'],
            onSaved: (value) => provider.updateEditField('state', value),
          ),
          _buildTextField(
            label: 'City',
            initialValue: provider.editFormData['city'],
            onSaved: (value) => provider.updateEditField('city', value),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Father Status',
            value: provider.editFormData['father_status'],
            items: ['Employed', 'Business', 'Retired', 'Passed Away'],
            onChanged: (value) =>
                provider.updateEditField('father_status', value),
          ),
          _buildDropdown(
            label: 'Mother Status',
            value: provider.editFormData['mother_status'],
            items: [
              'Homemaker',
              'Employed',
              'Business',
              'Retired',
              'Passed Away',
            ],
            onChanged: (value) =>
                provider.updateEditField('mother_status', value),
          ),
          _buildNumberField(
            label: 'Brothers',
            initialValue: provider.editFormData['brothers']?.toString(),
            onSaved: (value) => provider.updateEditField(
              'brothers',
              int.tryParse(value ?? '0'),
            ),
          ),
          _buildNumberField(
            label: 'Sisters',
            initialValue: provider.editFormData['sisters']?.toString(),
            onSaved: (value) =>
                provider.updateEditField('sisters', int.tryParse(value ?? '0')),
          ),
          _buildDropdown(
            label: 'Family Status',
            value: provider.editFormData['family_status'],
            items: ['Middle Class', 'Upper Middle Class', 'Rich', 'Affluent'],
            onChanged: (value) =>
                provider.updateEditField('family_status', value),
          ),
          _buildDropdown(
            label: 'Family Type',
            value: provider.editFormData['family_type'],
            items: ['Nuclear', 'Joint'],
            onChanged: (value) =>
                provider.updateEditField('family_type', value),
          ),
          _buildDropdown(
            label: 'Family Values',
            value: provider.editFormData['family_values'],
            items: ['Traditional', 'Moderate', 'Liberal'],
            onChanged: (value) =>
                provider.updateEditField('family_values', value),
          ),
          _buildTextField(
            label: 'Family Location',
            initialValue: provider.editFormData['family_location'],
            onSaved: (value) =>
                provider.updateEditField('family_location', value),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Highest Education',
            value: provider.editFormData['highest_education'],
            items: [
              'High School',
              'Diploma',
              'Bachelor\'s',
              'Master\'s',
              'PhD',
              'Other',
            ],
            onChanged: (value) =>
                provider.updateEditField('highest_education', value),
          ),
          _buildTextField(
            label: 'Educational Details',
            initialValue: provider.editFormData['educational_details'],
            onSaved: (value) =>
                provider.updateEditField('educational_details', value),
          ),
          _buildTextField(
            label: 'Occupation',
            initialValue: provider.editFormData['occupation'],
            onSaved: (value) => provider.updateEditField('occupation', value),
          ),
          _buildDropdown(
            label: 'Employed In',
            value: provider.editFormData['employed_in'],
            items: [
              'Private',
              'Government',
              'Business',
              'Self Employed',
              'Not Working',
            ],
            onChanged: (value) =>
                provider.updateEditField('employed_in', value),
          ),
          _buildDropdown(
            label: 'Personal Income',
            value: provider.editFormData['personal_income'],
            items: [
              'Below 5 LPA',
              '5-10 LPA',
              '10-15 LPA',
              '15-20 LPA',
              '20-30 LPA',
              'Above 30 LPA',
            ],
            onChanged: (value) =>
                provider.updateEditField('personal_income', value),
          ),
          _buildTextField(
            label: 'Working Sector',
            initialValue: provider.editFormData['working_sector'],
            onSaved: (value) =>
                provider.updateEditField('working_sector', value),
          ),
          _buildTextField(
            label: 'Working Location',
            initialValue: provider.editFormData['working_location'],
            onSaved: (value) =>
                provider.updateEditField('working_location', value),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Religion',
            value: provider.editFormData['religion'],
            items: [
              'Hindu',
              'Muslim',
              'Christian',
              'Sikh',
              'Buddhist',
              'Jain',
              'Other',
            ],
            onChanged: (value) => provider.updateEditField('religion', value),
          ),
          _buildTextField(
            label: 'Community',
            initialValue: provider.editFormData['community'],
            onSaved: (value) => provider.updateEditField('community', value),
          ),
          _buildDropdown(
            label: 'Eating Habits',
            value: provider.editFormData['eating_habits'],
            items: ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Vegan'],
            onChanged: (value) =>
                provider.updateEditField('eating_habits', value),
          ),
          _buildDropdown(
            label: 'Smoking Habits',
            value: provider.editFormData['smoking_habits'],
            items: ['No', 'Occasionally', 'Yes'],
            onChanged: (value) =>
                provider.updateEditField('smoking_habits', value),
          ),
          _buildDropdown(
            label: 'Drinking Habits',
            value: provider.editFormData['drinking_habits'],
            items: ['No', 'Socially', 'Yes'],
            onChanged: (value) =>
                provider.updateEditField('drinking_habits', value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    required Function(String?) onSaved,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        validator: required
            ? (value) => value?.isEmpty ?? true ? 'Required' : null
            : null,
        onSaved: onSaved,
        onChanged: onSaved,
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    String? initialValue,
    required Function(String?) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onSaved: onSaved,
        onChanged: onSaved,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    // Ensure value is in items list, otherwise set to null
    final validValue = (value != null && items.contains(value)) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _saveProfile(ProfileProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: 'Please fill all required fields',
        backgroundColor: Colors.red,
      );
      return;
    }

    _formKey.currentState!.save();

    final response = await provider.saveProfile();

    if (!mounted) return;

    if (response.success && response.data != null) {
      // Update auth provider with new user data
      context.read<AuthProvider>().updateUser(response.data!);

      Fluttertoast.showToast(
        msg: 'Profile updated successfully!',
        backgroundColor: Colors.green,
      );

      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: response.message ?? 'Failed to update profile',
        backgroundColor: Colors.red,
      );
    }
  }
}
