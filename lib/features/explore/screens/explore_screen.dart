import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/explore_provider.dart';
import '../widgets/user_card_widget.dart';
import '../widgets/filter_bottom_sheet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().loadUsers();
    });

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ExploreProvider>().loadMore();
    }
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      debugPrint('[EXPLORE] Search query: $query');
      context.read<ExploreProvider>().searchUsers(query);
    });
  }

  void _showFilters() {
    final provider = context.read<ExploreProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: provider.filters,
        onApply: (filters) {
          provider.applyFilters(filters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          Consumer<ExploreProvider>(
            builder: (context, provider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilters,
                  ),
                  if (provider.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          Consumer<ExploreProvider>(
            builder: (context, provider, child) {
              if (!provider.hasActiveFilters) {
                return const SizedBox.shrink();
              }

              return Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (provider.filters['sortBy'] != null)
                      _buildFilterChip(
                        'Sort: ${_getSortLabel(provider.filters['sortBy'])}',
                        () => provider.removeFilter('sortBy'),
                      ),

                    if (provider.filters['minAge'] != null ||
                        provider.filters['maxAge'] != null)
                      _buildFilterChip(
                        'Age: ${provider.filters['minAge'] ?? 18}-${provider.filters['maxAge'] ?? 60}',
                        () => provider.removeFilter('age'),
                      ),

                    if (provider.filters['country'] != null)
                      _buildFilterChip(
                        provider.filters['country'],
                        () => provider.removeFilter('country'),
                      ),
                    if (provider.filters['state'] != null)
                      _buildFilterChip(
                        provider.filters['state'],
                        () => provider.removeFilter('state'),
                      ),
                    if (provider.filters['city'] != null)
                      _buildFilterChip(
                        provider.filters['city'],
                        () => provider.removeFilter('city'),
                      ),

                    if (provider.filters['maritalStatus'] != null)
                      _buildFilterChip(
                        provider.filters['maritalStatus'],
                        () => provider.removeFilter('maritalStatus'),
                      ),
                    if (provider.filters['minHeight'] != null)
                      _buildFilterChip(
                        'Height: ${provider.filters['minHeight']}+',
                        () => provider.removeFilter('height'),
                      ),

                    if (provider.filters['religion'] != null)
                      _buildFilterChip(
                        provider.filters['religion'],
                        () => provider.removeFilter('religion'),
                      ),
                    if (provider.filters['community'] != null)
                      _buildFilterChip(
                        provider.filters['community'],
                        () => provider.removeFilter('community'),
                      ),
                    if (provider.filters['motherTongue'] != null)
                      _buildFilterChip(
                        provider.filters['motherTongue'],
                        () => provider.removeFilter('motherTongue'),
                      ),
                    if (provider.filters['familyType'] != null)
                      _buildFilterChip(
                        '${provider.filters['familyType']} Family',
                        () => provider.removeFilter('familyType'),
                      ),
                    if (provider.filters['brothers'] != null ||
                        provider.filters['sisters'] != null)
                      _buildFilterChip(
                        'Siblings: ${provider.filters['brothers'] ?? 0}B, ${provider.filters['sisters'] ?? 0}S',
                        () => provider.removeFilter('siblings'),
                      ),

                    if (provider.filters['highestEducation'] != null)
                      _buildFilterChip(
                        provider.filters['highestEducation'],
                        () => provider.removeFilter('highestEducation'),
                      ),
                    if (provider.filters['occupation'] != null)
                      _buildFilterChip(
                        provider.filters['occupation'],
                        () => provider.removeFilter('occupation'),
                      ),
                    if (provider.filters['annualIncome'] != null)
                      _buildFilterChip(
                        provider.filters['annualIncome'],
                        () => provider.removeFilter('annualIncome'),
                      ),

                    if (provider.filters['eatingHabits'] != null)
                      _buildFilterChip(
                        provider.filters['eatingHabits'],
                        () => provider.removeFilter('eatingHabits'),
                      ),
                    if (provider.filters['smokingHabits'] != null)
                      _buildFilterChip(
                        'Smoking: ${provider.filters['smokingHabits']}',
                        () => provider.removeFilter('smokingHabits'),
                      ),

                    if (provider.filters['minLandArea'] != null ||
                        provider.filters['maxLandArea'] != null)
                      _buildFilterChip(
                        'Land: ${provider.filters['minLandArea'] ?? 0}-${provider.filters['maxLandArea'] ?? 100} acres',
                        () => provider.removeFilter('landArea'),
                      ),
                    if (provider.filters['propertyType'] != null)
                      _buildFilterChip(
                        provider.filters['propertyType'],
                        () => provider.removeFilter('propertyType'),
                      ),

                    TextButton.icon(
                      onPressed: provider.clearFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: Consumer<ExploreProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No users to show',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'Try a different search'
                              : 'Check back later',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadUsers();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        provider.users.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return UserCardWidget(
                        user: provider.users[index],
                        onTap: () {
                          final userMap = provider.users[index];
                          Navigator.pushNamed(
                            context,
                            '/profile/user',
                            arguments: userMap['username'],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDelete,
        backgroundColor: Colors.deepPurple.shade50,
        labelStyle: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getSortLabel(String sortKey) {
    switch (sortKey) {
      case 'newest':
        return 'Newest First';
      case 'age_asc':
        return 'Youngest First';
      case 'age_desc':
        return 'Oldest First';
      default:
        return sortKey;
    }
  }
}