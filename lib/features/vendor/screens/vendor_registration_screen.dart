import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/vendor_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedPriceRange;
  bool _isLoading = false;

  final List<String> _priceRanges = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];

  final List<String> _serviceTypes = [
    'Catering',
    'Photography',
    'Venue',
    'Decoration',
    'Music',
    'Makeup',
    'Clothing',
    'Jewelry',
    'Transportation',
    'Invitation',
    'Gifts',
    'Other',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _serviceTypeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║ [VENDOR_REG] 📝 REGISTRATION SUBMIT CLICKED                ║',
    );
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final vendorDetails = {
        'business_name': _businessNameController.text.trim(),
        'service_type': _serviceTypeController.text.trim(),
        'business_address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'price_range': _selectedPriceRange,
        'experience_years': int.tryParse(_experienceController.text.trim()),
        'description': _descriptionController.text.trim(),
      };

      debugPrint('[VENDOR_REG] 📦 Vendor Details:');
      vendorDetails.forEach((key, value) {
        debugPrint('[VENDOR_REG]   - $key: $value');
      });
      debugPrint('[VENDOR_REG] ========================================');

      final apiService = context.read<ApiService>();
      final repository = VendorRepository(apiService);

      debugPrint('[VENDOR_REG] 🌐 Calling registerAsVendor API...');
      // Register as vendor with pending_payment status
      await repository.registerAsVendor(vendorDetails);

      debugPrint('[VENDOR_REG] ✅ Registration successful!');
      debugPrint('[VENDOR_REG] 🔄 Refreshing auth status...');

      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus(autoRoute: false);

      debugPrint('[VENDOR_REG] 📊 Current user:');
      final user = authProvider.currentUser;
      if (user != null) {
        debugPrint('[VENDOR_REG]   - ID: ${user.id}');
        debugPrint('[VENDOR_REG]   - vendor_status: ${user.vendorStatus}');
        debugPrint('[VENDOR_REG]   - vendor_details: ${user.vendorDetails}');
      }
      debugPrint('[VENDOR_REG] ========================================');

      if (mounted) {
        // Let routing logic handle navigation based on vendor_status
        if (user != null) {
          debugPrint('[VENDOR_REG] 🚀 Routing user based on status...');
          authProvider.routeUser(user);
        } else {
          debugPrint(
            '[VENDOR_REG] ⚠️ No user found, routing to payment screen',
          );
          Navigator.of(context).pushReplacementNamed(AppRoutes.vendorPayment);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      debugPrint('[VENDOR_REG] ✅ Process complete');
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('');
    } catch (e) {
      debugPrint('[VENDOR_REG] ========================================');
      debugPrint('[VENDOR_REG] ❌❌❌ EXCEPTION CAUGHT ❌❌❌');
      debugPrint('[VENDOR_REG] Error Type: ${e.runtimeType}');
      debugPrint('[VENDOR_REG] Error Message: $e');
      debugPrint('[VENDOR_REG] ========================================');
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Vendor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us about your business',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the details below to register as a vendor on WeddingZon',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  hintText: 'e.g., Elite Catering Services',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _serviceTypeController.text.isEmpty
                    ? null
                    : _serviceTypeController.text,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _serviceTypeController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select service type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Business Address',
                  hintText: '123 Main Street',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter business address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriceRange,
                      decoration: InputDecoration(
                        labelText: 'Price Range',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _priceRanges.map((range) {
                        return DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriceRange = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      decoration: InputDecoration(
                        labelText: 'Experience (years)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about your business and services...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
