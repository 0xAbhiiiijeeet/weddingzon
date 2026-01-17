import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  final Map<String, dynamic>? initialFilters;

  const FilterBottomSheet({
    super.key,
    required this.onApply,
    this.initialFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Basic Filters
  String? _sortBy;
  RangeValues _ageRange = const RangeValues(18, 60);

  // Location
  String? _country;
  String? _state;
  String? _city;

  // Personal
  String? _maritalStatus;
  String? _minHeight;

  // Cultural & Family
  String? _religion;
  String? _community;
  String? _motherTongue;
  String? _familyType;
  int? _brothers;
  int? _sisters;

  // Professional
  String? _education;
  String? _occupation;
  String? _income;

  // Lifestyle
  String? _diet;
  String? _smoking;

  // Property & Assets
  RangeValues _landAreaRange = const RangeValues(0, 100);
  String? _propertyType;

  @override
  void initState() {
    super.initState();
    _loadInitialFilters();
  }

  void _loadInitialFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;

      // Convert 'created_at' back to 'newest' for UI
      _sortBy = filters['sortBy'] == 'created_at'
          ? 'newest'
          : filters['sortBy'];

      _ageRange = RangeValues(
        (filters['minAge'] ?? 18).toDouble(),
        (filters['maxAge'] ?? 60).toDouble(),
      );
      _country = filters['country'];
      _state = filters['state'];
      _city = filters['city'];

      // Handle both snake_case (from backend) and camelCase (legacy)
      _maritalStatus = filters['marital_status'] ?? filters['maritalStatus'];
      _minHeight = filters['minHeight']?.toString();

      _religion = filters['religion'];
      _community = filters['community'];
      _motherTongue = filters['mother_tongue'] ?? filters['motherTongue'];
      _familyType = filters['family_type'] ?? filters['familyType'];
      _brothers = filters['brothers'];
      _sisters = filters['sisters'];

      _education = filters['highest_education'] ?? filters['highestEducation'];
      _occupation = filters['occupation'];
      _income = filters['annual_income'] ?? filters['annualIncome'];

      _diet = filters['eating_habits'] ?? filters['eatingHabits'];
      _smoking = filters['smoking_habits'] ?? filters['smokingHabits'];

      _landAreaRange = RangeValues(
        (filters['minLandArea'] ?? 0).toDouble(),
        (filters['maxLandArea'] ?? 100).toDouble(),
      );
      _propertyType = filters['property_type'] ?? filters['propertyType'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Search Filters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Filter Sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBasicFiltersSection(),
                    _buildLocationSection(),
                    _buildPersonalSection(),
                    _buildCulturalSection(),
                    _buildProfessionalSection(),
                    _buildLifestyleSection(),
                    _buildPropertySection(),
                  ],
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearAll,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicFiltersSection() {
    return ExpansionTile(
      title: const Text(
        'Basic Filters',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sort By
              const Text('Sort By', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select sort order'),
                items: const [
                  DropdownMenuItem(
                    value: 'newest',
                    child: Text('Newest First'),
                  ),
                  DropdownMenuItem(
                    value: 'age_asc',
                    child: Text('Age: Youngest First'),
                  ),
                  DropdownMenuItem(
                    value: 'age_desc',
                    child: Text('Age: Oldest First'),
                  ),
                ],
                onChanged: (value) => setState(() => _sortBy = value),
              ),
              const SizedBox(height: 16),

              // Age Range
              Text(
                'Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 80,
                divisions: 62,
                activeColor: Colors.deepPurple,
                labels: RangeLabels(
                  _ageRange.start.round().toString(),
                  _ageRange.end.round().toString(),
                ),
                onChanged: (values) => setState(() => _ageRange = values),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final isIndia = _country == 'India';

    return ExpansionTile(
      title: const Text(
        'Location',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country
              const Text('Country', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select country'),
                items: const [
                  DropdownMenuItem(value: 'India', child: Text('India')),
                  DropdownMenuItem(value: 'USA', child: Text('USA')),
                  DropdownMenuItem(value: 'UK', child: Text('UK')),
                  DropdownMenuItem(value: 'Canada', child: Text('Canada')),
                  DropdownMenuItem(
                    value: 'Australia',
                    child: Text('Australia'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _country = value;
                    if (value != 'India') _state = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // State (India dropdown or text field)
              const Text('State', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              if (isIndia)
                DropdownButtonFormField<String>(
                  value: _state,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: const Text('Select state'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Maharashtra',
                      child: Text('Maharashtra'),
                    ),
                    DropdownMenuItem(value: 'Delhi', child: Text('Delhi')),
                    DropdownMenuItem(
                      value: 'Karnataka',
                      child: Text('Karnataka'),
                    ),
                    DropdownMenuItem(value: 'Gujarat', child: Text('Gujarat')),
                    DropdownMenuItem(
                      value: 'Tamil Nadu',
                      child: Text('Tamil Nadu'),
                    ),
                    // Add more states as needed
                  ],
                  onChanged: (value) => setState(() => _state = value),
                )
              else
                TextField(
                  controller: TextEditingController(text: _state),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter state',
                  ),
                  onChanged: (value) =>
                      _state = value.trim().isEmpty ? null : value.trim(),
                ),
              const SizedBox(height: 16),

              // City
              const Text('City', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _city),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter city',
                  prefixIcon: Icon(Icons.location_city),
                ),
                onChanged: (value) =>
                    _city = value.trim().isEmpty ? null : value.trim(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalSection() {
    return ExpansionTile(
      title: const Text(
        'Personal Details',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Marital Status
              const Text('Marital Status', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Never Married',
                      'Divorced',
                      'Widowed',
                      'Awaiting Divorce',
                    ].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _maritalStatus == status,
                        onSelected: (selected) {
                          setState(
                            () => _maritalStatus = selected ? status : null,
                          );
                        },
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: _maritalStatus == status
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Min Height
              const Text('Minimum Height', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _minHeight,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select min height'),
                items:
                    [
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
                        ]
                        .map(
                          (height) => DropdownMenuItem(
                            value: height,
                            child: Text(height),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _minHeight = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalSection() {
    return ExpansionTile(
      title: const Text(
        'Cultural & Family',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Religion
              const Text('Religion', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Hindu',
                      'Muslim',
                      'Christian',
                      'Sikh',
                      'Buddhist',
                      'Jain',
                      'Other',
                    ].map((religion) {
                      return ChoiceChip(
                        label: Text(religion),
                        selected: _religion == religion,
                        onSelected: (selected) {
                          setState(
                            () => _religion = selected ? religion : null,
                          );
                        },
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: _religion == religion
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Community
              const Text(
                'Community / Caste (Optional)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _community),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter community',
                ),
                onChanged: (value) =>
                    _community = value.trim().isEmpty ? null : value.trim(),
              ),
              const SizedBox(height: 16),

              // Mother Tongue
              const Text('Mother Tongue', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _motherTongue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select mother tongue'),
                items:
                    [
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
                        ]
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _motherTongue = value),
              ),
              const SizedBox(height: 16),

              // Family Type
              const Text('Family Type', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Nuclear', 'Joint'].map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _familyType == type,
                    onSelected: (selected) {
                      setState(() => _familyType = selected ? type : null);
                    },
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: _familyType == type ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Brothers/Sisters
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Brothers', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _brothers,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('Any'),
                          items: List.generate(11, (i) => i)
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _brothers = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sisters', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _sisters,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('Any'),
                          items: List.generate(11, (i) => i)
                              .map(
                                (n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _sisters = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalSection() {
    return ExpansionTile(
      title: const Text(
        'Professional Details',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Education
              const Text('Highest Education', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _education,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select education'),
                items:
                    [
                          'High School',
                          'Diploma',
                          "Bachelor's",
                          "Master's",
                          'PhD',
                          'Other',
                        ]
                        .map(
                          (edu) =>
                              DropdownMenuItem(value: edu, child: Text(edu)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _education = value),
              ),
              const SizedBox(height: 16),

              // Occupation
              const Text(
                'Occupation (Optional)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _occupation),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Software Engineer',
                  prefixIcon: Icon(Icons.work),
                ),
                onChanged: (value) =>
                    _occupation = value.trim().isEmpty ? null : value.trim(),
              ),
              const SizedBox(height: 16),

              // Income
              const Text('Annual Income', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _income,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select income range'),
                items:
                    [
                          'Below 5 LPA',
                          '5-10 LPA',
                          '10-15 LPA',
                          '15-20 LPA',
                          '20-30 LPA',
                          'Above 30 LPA',
                        ]
                        .map(
                          (income) => DropdownMenuItem(
                            value: income,
                            child: Text(income),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _income = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleSection() {
    return ExpansionTile(
      title: const Text(
        'Lifestyle Preferences',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diet
              const Text(
                'Diet / Eating Habits',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Vegan'].map(
                      (diet) {
                        return ChoiceChip(
                          label: Text(diet),
                          selected: _diet == diet,
                          onSelected: (selected) {
                            setState(() => _diet = selected ? diet : null);
                          },
                          selectedColor: Colors.deepPurple,
                          labelStyle: TextStyle(
                            color: _diet == diet ? Colors.white : Colors.black,
                          ),
                        );
                      },
                    ).toList(),
              ),
              const SizedBox(height: 16),

              // Smoking
              const Text('Smoking', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['No', 'Occasionally', 'Yes'].map((smoking) {
                  return ChoiceChip(
                    label: Text(smoking),
                    selected: _smoking == smoking,
                    onSelected: (selected) {
                      setState(() => _smoking = selected ? smoking : null);
                    },
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: _smoking == smoking ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertySection() {
    return ExpansionTile(
      title: const Text(
        'Property & Assets',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Land Area
              Text(
                'Land Area: ${_landAreaRange.start.round()} - ${_landAreaRange.end.round()} acres',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              RangeSlider(
                values: _landAreaRange,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: Colors.deepPurple,
                labels: RangeLabels(
                  '${_landAreaRange.start.round()}',
                  '${_landAreaRange.end.round()}',
                ),
                onChanged: (values) => setState(() => _landAreaRange = values),
              ),
              const SizedBox(height: 16),

              // Property Type
              const Text('Property Type', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Residential', 'Commercial', 'Agricultural'].map((
                  type,
                ) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _propertyType == type,
                    onSelected: (selected) {
                      setState(() => _propertyType = selected ? type : null);
                    },
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: _propertyType == type
                          ? Colors.white
                          : Colors.black,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearAll() {
    setState(() {
      _sortBy = null;
      _ageRange = const RangeValues(18, 60);
      _country = null;
      _state = null;
      _city = null;
      _maritalStatus = null;
      _minHeight = null;
      _religion = null;
      _community = null;
      _motherTongue = null;
      _familyType = null;
      _brothers = null;
      _sisters = null;
      _education = null;
      _occupation = null;
      _income = null;
      _diet = null;
      _smoking = null;
      _landAreaRange = const RangeValues(0, 100);
      _propertyType = null;
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    // Basic - Convert sortBy values to match backend
    if (_sortBy != null) {
      filters['sortBy'] = _sortBy == 'newest' ? 'created_at' : _sortBy;
    }
    if (_ageRange.start != 18 || _ageRange.end != 60) {
      filters['minAge'] = _ageRange.start.round();
      filters['maxAge'] = _ageRange.end.round();
    }

    // Location
    if (_country != null) filters['country'] = _country;
    if (_state != null) filters['state'] = _state;
    if (_city != null) filters['city'] = _city;

    // Personal - Convert to snake_case and handle height conversion
    if (_maritalStatus != null) filters['marital_status'] = _maritalStatus;
    if (_minHeight != null) {
      // Convert feet/inches to cm (backend expects cm)
      final heightInCm = _convertHeightToCm(_minHeight!);
      if (heightInCm != null) filters['minHeight'] = heightInCm;
    }

    // Cultural - Convert to snake_case
    if (_religion != null) filters['religion'] = _religion;
    if (_community != null) filters['community'] = _community;
    if (_motherTongue != null) filters['mother_tongue'] = _motherTongue;
    // Note: family_type not in API docs - commenting out
    // if (_familyType != null) filters['family_type'] = _familyType;
    if (_brothers != null) filters['brothers'] = _brothers;
    if (_sisters != null) filters['sisters'] = _sisters;

    // Professional - Convert to snake_case
    if (_education != null) filters['highest_education'] = _education;
    if (_occupation != null) filters['occupation'] = _occupation;
    if (_income != null) filters['annual_income'] = _income;

    // Lifestyle - Convert to snake_case
    if (_diet != null) filters['eating_habits'] = _diet;
    if (_smoking != null) filters['smoking_habits'] = _smoking;

    // Property
    if (_landAreaRange.start != 0 || _landAreaRange.end != 100) {
      filters['minLandArea'] = _landAreaRange.start.round();
      filters['maxLandArea'] = _landAreaRange.end.round();
    }
    if (_propertyType != null) filters['property_type'] = _propertyType;

    debugPrint('[FILTERS] Applied: $filters');
    widget.onApply(filters);
    Navigator.pop(context);
  }

  // Helper to convert height from feet'inches" format to cm
  int? _convertHeightToCm(String height) {
    try {
      // Parse formats like "5'6"" or "5'6\""
      final cleaned = height.replaceAll('"', '').replaceAll('"', '');
      final parts = cleaned.split("'");

      if (parts.isNotEmpty) {
        final feet = int.tryParse(parts[0]) ?? 0;
        final inches = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        // Convert to cm: 1 foot = 30.48 cm, 1 inch = 2.54 cm
        final totalCm = (feet * 30.48) + (inches * 2.54);
        return totalCm.round();
      }
    } catch (e) {
      debugPrint('[FILTER] Error converting height: $e');
    }
    return null;
  }
}
