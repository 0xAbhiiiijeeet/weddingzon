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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ProfileProvider>().initializeEditForm(user);
        setState(() {
          _isInitialized = true;
        });
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
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            Tab(text: 'Religious'),
            Tab(text: 'Lifestyle'),
            Tab(text: 'Property'),
            Tab(text: 'Contact'),
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
                _buildReligiousTab(provider),
                _buildLifestyleTab(provider),
                _buildPropertyTab(provider),
                _buildContactTab(provider),
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
          _buildDropdown(
            label: 'Profile Created For*',
            value: provider.editFormData['created_for'],
            items: const [
              'Self',
              'Son',
              'Daughter',
              'Brother',
              'Sister',
              'Friend',
              'Relative',
            ],
            onChanged: (value) =>
                provider.updateEditField('created_for', value),
            required: true,
          ),
          _buildTextField(
            label: 'Username*',
            initialValue: provider.editFormData['username'],
            onSaved: (value) => provider.updateEditField('username', value),
            helperText: 'Unique ID for your profile URL (Cannot be changed)',
            enabled: false, // Username cannot be edited
          ),
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
          _buildDatePicker(
            label: 'Date of Birth',
            value: provider.editFormData['dob'],
            onChanged: (value) => provider.updateEditField('dob', value),
          ),
          // Age (Read-only)
          _buildTextField(
            label: 'Age',
            initialValue: provider.editFormData['dob'] != null
                ? (DateTime.now()
                              .difference(
                                DateTime.parse(provider.editFormData['dob']),
                              )
                              .inDays ~/
                          365)
                      .toString()
                : '',
            onSaved: (_) {},
            enabled: false,
          ),
          _buildDropdown(
            label: 'Gender*',
            value: provider.editFormData['gender'],
            items: const ['Male', 'Female', 'Other'],
            onChanged: (value) => provider.updateEditField('gender', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Height*',
            value: provider.editFormData['height'],
            items: const [
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
            required: true,
          ),
          _buildDropdown(
            label: 'Marital Status*',
            value: provider.editFormData['marital_status'],
            items: const [
              'Never Married',
              'Divorced',
              'Widowed',
              'Awaiting Divorce',
            ],
            onChanged: (value) =>
                provider.updateEditField('marital_status', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Mother Tongue*',
            value: provider.editFormData['mother_tongue'],
            items: const [
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
            required: true,
          ),
          _buildDropdown(
            label: 'Disability Status',
            value: provider.editFormData['disability'],
            items: const ['None', 'Physical', 'Mental', 'Other'],
            onChanged: (value) => provider.updateEditField('disability', value),
          ),
          // Conditional disability description
          if (provider.editFormData['disability'] != null &&
              provider.editFormData['disability'] != 'None')
            _buildTextField(
              label: 'Disability Description',
              initialValue: provider.editFormData['disability_description'],
              onSaved: (value) =>
                  provider.updateEditField('disability_description', value),
              maxLines: 2,
            ),
          _buildTextField(
            label: 'Aadhar Number (Optional)',
            initialValue: provider.editFormData['aadhar_number'],
            onSaved: (value) =>
                provider.updateEditField('aadhar_number', value),
            keyboardType: TextInputType.number,
            maxLength: 12,
            helperText: 'Verification ensures a trusted profile',
          ),
          _buildDropdown(
            label: 'Blood Group',
            value: provider.editFormData['blood_group'],
            items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
            onChanged: (value) =>
                provider.updateEditField('blood_group', value),
          ),
          _buildTextField(
            label: 'About Me',
            initialValue: provider.editFormData['about_me'],
            onSaved: (value) => provider.updateEditField('about_me', value),
            maxLines: 4,
            minLength: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab(ProfileProvider provider) {
    final isIndia = provider.editFormData['country'] == 'India';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Country',
            value: provider.editFormData['country'],
            items: const ['India', 'USA', 'UK', 'Canada', 'Australia'],
            onChanged: (value) => provider.updateEditField('country', value),
          ),
          if (isIndia)
            _buildDropdown(
              label: 'State',
              value: provider.editFormData['state'],
              items: const [
                'Andhra Pradesh',
                'Arunachal Pradesh',
                'Assam',
                'Bihar',
                'Chhattisgarh',
                'Goa',
                'Gujarat',
                'Haryana',
                'Himachal Pradesh',
                'Jharkhand',
                'Karnataka',
                'Kerala',
                'Madhya Pradesh',
                'Maharashtra',
                'Manipur',
                'Meghalaya',
                'Mizoram',
                'Nagaland',
                'Odisha',
                'Punjab',
                'Rajasthan',
                'Sikkim',
                'Tamil Nadu',
                'Telangana',
                'Tripura',
                'Uttar Pradesh',
                'Uttarakhand',
                'West Bengal',
                'Delhi',
                'Jammu and Kashmir',
                'Ladakh',
              ],
              onChanged: (value) => provider.updateEditField('state', value),
            )
          else
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
            label: "Father's Occupation/Status*",
            value: provider.editFormData['father_status'],
            items: const ['Employed', 'Business', 'Retired', 'Passed Away'],
            onChanged: (value) =>
                provider.updateEditField('father_status', value),
            required: true,
          ),
          _buildDropdown(
            label: "Mother's Occupation/Status*",
            value: provider.editFormData['mother_status'],
            items: const [
              'Homemaker',
              'Employed',
              'Business',
              'Retired',
              'Passed Away',
            ],
            onChanged: (value) =>
                provider.updateEditField('mother_status', value),
            required: true,
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
            label: 'Family Status*',
            value: provider.editFormData['family_status'],
            items: const [
              'Middle Class',
              'Upper Middle Class',
              'Rich',
              'Affluent',
            ],
            onChanged: (value) =>
                provider.updateEditField('family_status', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Family Type*',
            value: provider.editFormData['family_type'],
            items: const ['Nuclear', 'Joint'],
            onChanged: (value) =>
                provider.updateEditField('family_type', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Family Values*',
            value: provider.editFormData['family_values'],
            items: const ['Traditional', 'Moderate', 'Liberal'],
            onChanged: (value) =>
                provider.updateEditField('family_values', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Family Annual Income',
            value: provider.editFormData['annual_income'],
            items: const [
              'Below 5 LPA',
              '5-10 LPA',
              '10-15 LPA',
              '15-20 LPA',
              '20-30 LPA',
              'Above 30 LPA',
            ],
            onChanged: (value) =>
                provider.updateEditField('annual_income', value),
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
            label: 'Highest Education*',
            value: provider.editFormData['highest_education'],
            items: const [
              'High School',
              'Diploma',
              "Bachelor's Degree",
              "Master's Degree",
              'PhD',
              'Professional Degree',
              'Other',
            ],
            onChanged: (value) =>
                provider.updateEditField('highest_education', value),
            required: true,
          ),
          _buildTextField(
            label: 'Educational Details',
            initialValue: provider.editFormData['educational_details'],
            onSaved: (value) =>
                provider.updateEditField('educational_details', value),
            hintText: 'e.g. B.Tech in CS',
          ),
          _buildTextField(
            label: 'Occupation*',
            initialValue: provider.editFormData['occupation'],
            onSaved: (value) => provider.updateEditField('occupation', value),
            required: true,
            hintText: 'Software Engineer, Doctor, etc.',
          ),
          _buildDropdown(
            label: 'Employed In*',
            value: provider.editFormData['employed_in'],
            items: const [
              'Private',
              'Government',
              'Business',
              'Self Employed',
              'Not Working',
            ],
            onChanged: (value) =>
                provider.updateEditField('employed_in', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Annual Income*',
            value: provider.editFormData['personal_income'],
            items: const [
              'Below 5 LPA',
              '5-10 LPA',
              '10-15 LPA',
              '15-20 LPA',
              '20-30 LPA',
              'Above 30 LPA',
            ],
            onChanged: (value) =>
                provider.updateEditField('personal_income', value),
            required: true,
          ),
          _buildTextField(
            label: 'Working Sector (Optional)',
            initialValue: provider.editFormData['working_sector'],
            onSaved: (value) =>
                provider.updateEditField('working_sector', value),
            hintText: 'e.g. IT, Healthcare',
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

  Widget _buildReligiousTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Religion*',
            value: provider.editFormData['religion'],
            items: const [
              'Hindu',
              'Muslim',
              'Christian',
              'Sikh',
              'Buddhist',
              'Jain',
              'Other',
            ],
            onChanged: (value) => provider.updateEditField('religion', value),
            required: true,
          ),
          _buildTextField(
            label: 'Community / Caste*',
            initialValue: provider.editFormData['community'],
            onSaved: (value) => provider.updateEditField('community', value),
            required: true,
          ),
          _buildTextField(
            label: 'Sub-Community (Optional)',
            initialValue: provider.editFormData['sub_community'],
            onSaved: (value) =>
                provider.updateEditField('sub_community', value),
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
            label: 'Appearance*',
            value: provider.editFormData['appearance'],
            items: const ['Fair', 'Wheatish', 'Dark', 'Very Fair'],
            onChanged: (value) => provider.updateEditField('appearance', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Living Status*',
            value: provider.editFormData['living_status'],
            items: const [
              'With Family',
              'Alone',
              'With Relatives',
              'Hostel/PG',
            ],
            onChanged: (value) =>
                provider.updateEditField('living_status', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Eating Habits*',
            value: provider.editFormData['eating_habits'],
            items: const [
              'Vegetarian',
              'Non-Vegetarian',
              'Eggetarian',
              'Vegan',
            ],
            onChanged: (value) =>
                provider.updateEditField('eating_habits', value),
            required: true,
          ),
          _buildDropdown(
            label: 'Smoking',
            value: provider.editFormData['smoking_habits'],
            items: const ['No', 'Occasionally', 'Yes'],
            onChanged: (value) =>
                provider.updateEditField('smoking_habits', value),
          ),
          _buildDropdown(
            label: 'Drinking',
            value: provider.editFormData['drinking_habits'],
            items: const ['No', 'Socially', 'Yes'],
            onChanged: (value) =>
                provider.updateEditField('drinking_habits', value),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField(
            label: 'Land Area (in Acres, Optional)',
            initialValue: provider.editFormData['land_area']?.toString(),
            onSaved: (value) => provider.updateEditField(
              'land_area',
              value != null && value.isNotEmpty ? double.tryParse(value) : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _buildTextField(
            label: 'Property Type (Optional)',
            initialValue: provider.editFormData['property_type'],
            onSaved: (value) =>
                provider.updateEditField('property_type', value),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab(ProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Read-only phone (from auth)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              initialValue: provider.editFormData['phone'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Phone Number (Verified)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.verified, color: Colors.green),
              ),
              readOnly: true,
              enabled: false,
            ),
          ),
          // Read-only email (from auth)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              initialValue: provider.editFormData['email'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Email (Verified)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.verified, color: Colors.green),
              ),
              readOnly: true,
              enabled: false,
            ),
          ),
          _buildTextField(
            label: 'Alternate Mobile Number (Optional)',
            initialValue: provider.editFormData['alternate_mobile'],
            onSaved: (value) =>
                provider.updateEditField('alternate_mobile', value),
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
          _buildDropdown(
            label: 'Suitable Time to Call',
            value: provider.editFormData['suitable_time_to_call'],
            items: const [
              'Morning (6 AM - 12 PM)',
              'Afternoon (12 PM - 6 PM)',
              'Evening (6 PM - 10 PM)',
              'Anytime',
            ],
            onChanged: (value) =>
                provider.updateEditField('suitable_time_to_call', value),
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
    TextInputType? keyboardType,
    int? maxLength,
    int? minLength,
    bool enabled = true,
    String? helperText,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          helperText: helperText,
          hintText: hintText,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: (value) {
          if (required && (value?.isEmpty ?? true)) {
            return 'Required';
          }
          if (minLength != null && (value?.length ?? 0) < minLength) {
            return 'Minimum $minLength characters required';
          }
          return null;
        },
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
    bool required = false,
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
        validator: (val) {
          if (required && val == null) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    String? value,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        controller: TextEditingController(
          text: value != null && value.isNotEmpty
              ? value.split('T')[0] // Display only date part
              : '',
        ),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value != null && value.isNotEmpty
                ? DateTime.tryParse(value) ?? DateTime(2000)
                : DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
            helpText: 'Select Date of Birth',
          );
          if (picked != null) {
            onChanged(picked.toIso8601String());
          }
        },
        validator: (val) {
          if (value == null || value.isEmpty) {
            return 'Date of Birth is required';
          }
          final dob = DateTime.tryParse(value);
          if (dob == null) return 'Invalid date';

          final age = DateTime.now().difference(dob).inDays ~/ 365;
          if (age < 18) {
            return 'Must be at least 18 years old';
          }
          return null;
        },
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
      // Refresh user from server to ensure we get signed URLs and complete data
      await context.read<AuthProvider>().refreshUser();

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
