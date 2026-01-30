import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/models/user_model.dart';
import '../providers/franchise_form_provider.dart';
import '../widgets/franchise_basic_details_form.dart';
import '../widgets/franchise_location_form.dart';
import '../widgets/franchise_family_form.dart';
import '../widgets/franchise_education_form.dart';
import '../widgets/franchise_religion_form.dart';
import '../widgets/franchise_lifestyle_form.dart';
import '../providers/franchise_provider.dart';

class AddMemberScreen extends StatefulWidget {
  final User? editUser;
  const AddMemberScreen({super.key, this.editUser});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  String? _createdProfileId;
  Map<String, dynamic>? _credentials;

  final List<GlobalKey<FormState>> _formKeys = List.generate(
    7,
    (_) => GlobalKey<FormState>(),
  );
  final List<XFile> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.editUser != null) {
      _createdProfileId = widget.editUser!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FranchiseFormProvider>().prepopulateFromUser(
          widget.editUser!,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 6) {
      final formState = _formKeys[_currentStep].currentState;
      if (formState == null || !formState.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please correct the errors')),
        );
        return;
      }
    }

    if (_currentStep == 0) {
      await _submitBasicDetails();
    } else if (_currentStep < 6) {
      await _submitOtherSteps();
    } else {
      await _submitPhotos();
    }
  }

  Future<void> _submitBasicDetails() async {
    setState(() => _isLoading = true);

    try {
      final formProvider = context.read<FranchiseFormProvider>();
      final basicData = {
        'created_for': formProvider.formData['created_for'],
        'first_name': formProvider.formData['first_name'],
        'last_name': formProvider.formData['last_name'],
        'phone': formProvider.formData['phone'],
        'email': formProvider.formData['email'],
        'dob': formProvider.formData['dob'],
        'gender': formProvider.formData['gender'],
        'height': formProvider.formData['height'],
        'marital_status': formProvider.formData['marital_status'],
        'mother_tongue': formProvider.formData['mother_tongue'],
        'disability': formProvider.formData['disability'] ?? 'None',
        'about_me': formProvider.formData['about_me'],
        if (formProvider.formData['aadhar_number'] != null)
          'aadhar_number': formProvider.formData['aadhar_number'],
        if (formProvider.formData['blood_group'] != null)
          'blood_group': formProvider.formData['blood_group'],
        if (formProvider.formData['disability_description'] != null)
          'disability_description': formProvider.formData['disability_description'],
      };

      final franchiseProvider = context.read<FranchiseProvider>();

      if (widget.editUser != null) {
        final success = await franchiseProvider.updateMember(
          widget.editUser!.id,
          basicData,
        );
        if (!success) {
          throw Exception(franchiseProvider.error);
        }

        setState(() => _isLoading = false);
        _navigateToNextStep();
      } else {
        final result = await franchiseProvider.createMember(basicData);
        if (result == null) {
          throw Exception(franchiseProvider.error);
        }

        setState(() {
          _createdProfileId = result['profile']['_id'];
          _credentials = result['credentials'];
          _isLoading = false;
        });

        await _showCredentialsDialog();

        _navigateToNextStep();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _submitOtherSteps() async {
    if (_createdProfileId == null && widget.editUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile ID missing. Please restart.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formProvider = context.read<FranchiseFormProvider>();
      final updateData = _getStepData(_currentStep, formProvider.formData);

      final franchiseProvider = context.read<FranchiseProvider>();
      final profileId = _createdProfileId ?? widget.editUser!.id;

      final success = await franchiseProvider.updateMember(
        profileId,
        updateData,
      );

      setState(() => _isLoading = false);

      if (success) {
        _navigateToNextStep();
      } else {
        throw Exception(franchiseProvider.error);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _submitPhotos() async {
    if (_createdProfileId == null && widget.editUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile ID missing. Please restart.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formProvider = context.read<FranchiseFormProvider>();
      final franchiseProvider = context.read<FranchiseProvider>();
      final profileId = _createdProfileId ?? widget.editUser!.id;

      final finalData = _getStepData(6, formProvider.formData);
      if (finalData.isNotEmpty) {
        final success = await franchiseProvider.updateMember(
          profileId,
          finalData,
        );
        if (!success) {
          throw Exception(franchiseProvider.error);
        }
      }

      if (_selectedPhotos.isNotEmpty) {
        await franchiseProvider.uploadPhotos(profileId, _selectedPhotos);
      }

      setState(() => _isLoading = false);
      _finish();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _navigateToNextStep() {
    if (_currentStep < 6) {
      setState(() => _currentStep += 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (_currentStep == 6 && widget.editUser != null) {
        _reloadProfileForPhotos();
      }
    } else {
      _finish();
    }
  }

  Future<void> _reloadProfileForPhotos() async {
    try {
      final franchiseProvider = context.read<FranchiseProvider>();
      await franchiseProvider.loadProfiles();
      
      final updatedUser = franchiseProvider.profiles.firstWhere(
        (p) => p.id == widget.editUser!.id,
        orElse: () => widget.editUser!,
      );
      
      if (mounted) {
        context.read<FranchiseFormProvider>().prepopulateFromUser(updatedUser);
      }
    } catch (e) {
      debugPrint('[ADD_MEMBER] Error reloading profile for photos: $e');
    }
  }

  void _finish() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member profile created successfully!')),
      );
      Navigator.pop(context); 
    }
  }

  Map<String, dynamic> _getStepData(int step, Map<String, dynamic> formData) {
    switch (step) {
      case 1:
        return {
          if (formData['country'] != null) 'country': formData['country'],
          if (formData['state'] != null) 'state': formData['state'],
          if (formData['city'] != null) 'city': formData['city'],
        };
      case 2: 
        return {
          if (formData['highest_education'] != null)
            'highest_education': formData['highest_education'],
          if (formData['educational_details'] != null)
            'educational_details': formData['educational_details'],
          if (formData['occupation'] != null)
            'occupation': formData['occupation'],
          if (formData['employed_in'] != null)
            'employed_in': formData['employed_in'],
          if (formData['personal_income'] != null)
            'personal_income': formData['personal_income'],
          if (formData['working_sector'] != null)
            'working_sector': formData['working_sector'],
        };
      case 3: // Family
        return {
          if (formData['father_status'] != null)
            'father_status': formData['father_status'],
          if (formData['mother_status'] != null)
            'mother_status': formData['mother_status'],
          if (formData['brothers'] != null) 'brothers': formData['brothers'],
          if (formData['sisters'] != null) 'sisters': formData['sisters'],
          if (formData['family_status'] != null)
            'family_status': formData['family_status'],
          if (formData['family_type'] != null)
            'family_type': formData['family_type'],
          if (formData['family_values'] != null)
            'family_values': formData['family_values'],
          if (formData['annual_income'] != null)
            'annual_income': formData['annual_income'],
        };
      case 4: // Religion
        return {
          if (formData['religion'] != null) 'religion': formData['religion'],
          if (formData['community'] != null) 'community': formData['community'],
          if (formData['sub_community'] != null)
            'sub_community': formData['sub_community'],
        };
      case 5: // Lifestyle
        return {
          if (formData['appearance'] != null)
            'appearance': formData['appearance'],
          if (formData['living_status'] != null)
            'living_status': formData['living_status'],
          if (formData['physical_status'] != null)
            'physical_status': formData['physical_status'],
          if (formData['eating_habits'] != null)
            'eating_habits': formData['eating_habits'],
          if (formData['smoking_habits'] != null)
            'smoking_habits': formData['smoking_habits'],
          if (formData['drinking_habits'] != null)
            'drinking_habits': formData['drinking_habits'],
          if (formData['hobbies'] != null) 'hobbies': formData['hobbies'],
          if (formData['property_types'] != null)
            'property_types': formData['property_types'],
          if (formData['land_types'] != null)
            'land_types': formData['land_types'],
          if (formData['house_types'] != null)
            'house_types': formData['house_types'],
          if (formData['business_types'] != null)
            'business_types': formData['business_types'],
          if (formData['land_area'] != null) 'land_area': formData['land_area'],
          if (formData['alternate_mobile'] != null)
            'alternate_mobile': formData['alternate_mobile'],
          if (formData['suitable_time_to_call'] != null)
            'suitable_time_to_call': formData['suitable_time_to_call'],
          if (formData['disability_type'] != null)
            'disability_type': formData['disability_type'],
        };
      default:
        return {};
    }
  }

  Future<void> _showCredentialsDialog() async {
    if (_credentials == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Profile Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile successfully created! Here are the login credentials:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildCredentialRow('Username', _credentials!['username']),
            const SizedBox(height: 8),
            _buildCredentialRow('Password', _credentials!['password']),
            const SizedBox(height: 16),
            const Text(
              'Please save these credentials and share them with the member.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      'Username: ${_credentials!['username']}\nPassword: ${_credentials!['password']}',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Credentials copied to clipboard'),
                ),
              );
            },
            child: const Text('Copy Both'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$label copied')));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _prevStep() async {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedPhotos.addAll(images));
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == _currentStep ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index <= _currentStep
                  ? Colors.deepPurple
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPhotosUI() {
    // Get the latest user data from provider if in edit mode
    User? currentUser = widget.editUser;
    if (widget.editUser != null) {
      final franchiseProvider = context.watch<FranchiseProvider>();
      currentUser = franchiseProvider.profiles.firstWhere(
        (p) => p.id == widget.editUser!.id,
        orElse: () => widget.editUser!,
      );
    }
    
    final existingPhotos = currentUser?.photos ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can upload photos now or skip this step.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          // Existing photos section (only in edit mode)
          if (existingPhotos.isNotEmpty) ...[
            const Text(
              'Existing Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: existingPhotos.map((photo) {
                return _buildExistingPhotoCard(photo);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // New photos section
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Select New Photos'),
          ),
          const SizedBox(height: 16),
          
          if (_selectedPhotos.isNotEmpty) ...[
            const Text(
              'New Photos to Upload',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedPhotos.map((file) {
                return _buildNewPhotoCard(file);
              }).toList(),
            ),
          ] else if (existingPhotos.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No photos selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExistingPhotoCard(photo) {
    final isProfilePhoto = photo.isProfile;
    
    return Container(
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isProfilePhoto 
            ? Border.all(color: Colors.deepPurple, width: 3)
            : null,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photo.url,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
          if (isProfilePhoto)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isProfilePhoto)
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.all(4),
                    ),
                    tooltip: 'Set as profile photo',
                    onPressed: () => _setAsProfilePhoto(photo),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(4),
                  ),
                  tooltip: 'Delete photo',
                  onPressed: () => _deleteExistingPhoto(photo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPhotoCard(XFile file) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(file.path),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.all(4),
            ),
            onPressed: () => setState(() => _selectedPhotos.remove(file)),
          ),
        ),
      ],
    );
  }

  Future<void> _setAsProfilePhoto(photo) async {
    if (widget.editUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final franchiseProvider = context.read<FranchiseProvider>();
      final photoId = photo.publicId ?? photo.url.split('/').last;
      
      final success = await franchiseProvider.setProfilePhoto(
        widget.editUser!.id,
        photoId,
      );
      
      if (success) {
        // Refresh profile to get updated photo data
        await franchiseProvider.loadProfiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      } else {
        throw Exception(franchiseProvider.error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExistingPhoto(photo) async {
    if (widget.editUser == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final franchiseProvider = context.read<FranchiseProvider>();
      
      // Extract photoId from publicId or URL
      String photoId;
      if (photo.publicId != null && photo.publicId!.isNotEmpty) {
        photoId = photo.publicId!;
      } else {
        // Fallback: extract from URL
        photoId = photo.url.split('/').last.split('.').first;
      }
      
      debugPrint('[ADD_MEMBER] Deleting photo with ID: $photoId');
      
      final success = await franchiseProvider.deletePhoto(
        widget.editUser!.id,
        photoId,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo deleted successfully')),
          );
          // Trigger a rebuild to show updated photos
          setState(() {});
        }
      } else {
        throw Exception(franchiseProvider.error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _prevStep,
              child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 6 ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep == 0) return true;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'Going back will discard progress on this step. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.editUser != null ? 'Edit Member' : 'Add New Member',
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  FranchiseBasicDetailsForm(formKey: _formKeys[0]),
                  FranchiseLocationForm(formKey: _formKeys[1]),
                  FranchiseEducationForm(formKey: _formKeys[2]),
                  FranchiseFamilyForm(formKey: _formKeys[3]),
                  FranchiseReligionForm(formKey: _formKeys[4]),
                  FranchiseLifestyleForm(formKey: _formKeys[5]),
                  _buildPhotosUI(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }
}
