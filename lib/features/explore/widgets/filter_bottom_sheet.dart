import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;

  const FilterBottomSheet({super.key, required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _ageRange = const RangeValues(18, 60);
  RangeValues _heightRange = const RangeValues(4.0, 7.0);
  String? _selectedReligion;
  String? _selectedCity;

  final List<String> _religions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Buddhist',
    'Jain',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Age filter
            _buildSectionTitle('Age Range'),
            Text(
              '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 80,
              divisions: 62,
              activeColor: Colors.deepPurple,
              onChanged: (values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
            const SizedBox(height: 24),

            // Height filter
            _buildSectionTitle('Height Range'),
            Text(
              '${_heightRange.start.toStringAsFixed(1)} - ${_heightRange.end.toStringAsFixed(1)} ft',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            RangeSlider(
              values: _heightRange,
              min: 4.0,
              max: 7.0,
              divisions: 30,
              activeColor: Colors.deepPurple,
              onChanged: (values) {
                setState(() {
                  _heightRange = values;
                });
              },
            ),
            const SizedBox(height: 24),

            // Religion filter
            _buildSectionTitle('Religion'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _religions.map((religion) {
                final isSelected = _selectedReligion == religion;
                return ChoiceChip(
                  label: Text(religion),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedReligion = selected ? religion : null;
                    });
                  },
                  selectedColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // City filter
            _buildSectionTitle('City'),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _selectedCity = value.trim().isEmpty ? null : value.trim();
              },
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _ageRange = const RangeValues(18, 60);
                        _heightRange = const RangeValues(4.0, 7.0);
                        _selectedReligion = null;
                        _selectedCity = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    // Age filter
    if (_ageRange.start != 18 || _ageRange.end != 60) {
      filters['minAge'] = _ageRange.start.round();
      filters['maxAge'] = _ageRange.end.round();
    }

    // Height filter (convert to meters if backend expects meters)
    if (_heightRange.start != 4.0 || _heightRange.end != 7.0) {
      filters['minHeight'] = _heightRange.start;
      filters['maxHeight'] = _heightRange.end;
    }

    // Religion filter
    if (_selectedReligion != null) {
      filters['religion'] = _selectedReligion;
    }

    // City filter
    if (_selectedCity != null) {
      filters['city'] = _selectedCity;
    }

    debugPrint('[FILTERS] Applied: $filters');
    widget.onApply(filters);
    Navigator.pop(context);
  }
}
