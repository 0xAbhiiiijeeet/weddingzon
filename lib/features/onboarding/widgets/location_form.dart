import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/onboarding_provider.dart';
import '../../../core/services/location_service.dart';

class LocationForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const LocationForm({super.key, required this.formKey});

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final LocationService _locationService = LocationService();
  bool _isLoadingLocation = false;

  Future<void> _getMyLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      debugPrint('[ONBOARDING_LOCATION] Requesting current location...');
      final address = await _locationService.getCurrentLocationAddress();

      if (!mounted) return;

      if (address.isEmpty) {
        debugPrint('[ONBOARDING_LOCATION] ERROR: Location address is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get location. Please enable location services.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint(
        '[ONBOARDING_LOCATION] ========== Location Retrieved ==========',
      );
      debugPrint(
        '[ONBOARDING_LOCATION] Country: ${address['country'] ?? 'NULL'}',
      );
      debugPrint('[ONBOARDING_LOCATION] State: ${address['state'] ?? 'NULL'}');
      debugPrint('[ONBOARDING_LOCATION] City: ${address['city'] ?? 'NULL'}');
      debugPrint(
        '[ONBOARDING_LOCATION] ==========================================',
      );

      final provider = context.read<OnboardingProvider>();

      // Update fields
      if (address['country'] != null) {
        provider.updateField('country', address['country']);
        debugPrint('[ONBOARDING_LOCATION] Updated country field');
      }
      if (address['state'] != null) {
        provider.updateField('state', address['state']);
        debugPrint('[ONBOARDING_LOCATION] Updated state field');
      }
      if (address['city'] != null) {
        provider.updateField('city', address['city']);
        debugPrint('[ONBOARDING_LOCATION] Updated city field');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location populated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          final isIndia = provider.formData['country'] == 'India';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Get My Location Button
              OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getMyLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isLoadingLocation
                      ? 'Getting Location...'
                      : 'Get My Location',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Rest of the form remains same, reusing existing widgets inside the new stateful widget structure
              DropdownButtonFormField<String>(
                value: provider.formData['country'],
                decoration: const InputDecoration(
                  labelText: 'Country *',
                  border: OutlineInputBorder(),
                ),
                items: ['India', 'USA', 'UK', 'Canada', 'Australia', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) {
                  provider.updateField('country', v);
                  // Clear state when country changes
                  if (v != 'India') {
                    provider.updateField('state', null);
                  }
                },
                onSaved: (v) => provider.updateField('country', v),
              ),
              const SizedBox(height: 16),

              if (isIndia)
                DropdownButtonFormField<String>(
                  value: provider.formData['state'],
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
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
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  validator: (v) => v == null ? 'Required' : null,
                  onChanged: (v) => provider.updateField('state', v),
                  onSaved: (v) => provider.updateField('state', v),
                )
              else
                TextFormField(
                  key: ValueKey(
                    provider.formData['state'],
                  ), // Add key to force rebuild if value changes externally
                  initialValue: provider.formData['state'],
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (v) => provider.updateField('state', v),
                  onSaved: (v) => provider.updateField('state', v),
                ),
              const SizedBox(height: 16),

              TextFormField(
                key: ValueKey(
                  provider.formData['city'],
                ), // Add key to force rebuild
                initialValue: provider.formData['city'],
                decoration: const InputDecoration(
                  labelText: 'City *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                onChanged: (v) => provider.updateField('city', v),
                onSaved: (v) => provider.updateField('city', v),
              ),
            ],
          );
        },
      ),
    );
  }
}
