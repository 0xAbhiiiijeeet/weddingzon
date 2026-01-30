import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<String> _selectedCategories;
  late double _minPrice;
  late double _maxPrice;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    try {
      debugPrint('');
      debugPrint('╔════════════════════════════════════════════════════════╗');
      debugPrint('║ [FILTER_SHEET] 🎛️ INITIALIZING FILTER SHEET           ║');
      debugPrint('╚════════════════════════════════════════════════════════╝');

      final shopProvider = context.read<ShopProvider>();
      _selectedCategories = Set.from(shopProvider.selectedCategories);
      _minPrice = shopProvider.minPrice;
      _maxPrice = shopProvider.maxPrice;
      _priceRange = RangeValues(_minPrice, _maxPrice);

      debugPrint('[FILTER_SHEET] 📋 Initial State:');
      debugPrint(
        '[FILTER_SHEET]   - Selected Categories: ${_selectedCategories.length}',
      );
      debugPrint('[FILTER_SHEET]   - Categories: $_selectedCategories');
      debugPrint('[FILTER_SHEET]   - Price Range: ₹$_minPrice - ₹$_maxPrice');
      debugPrint('[FILTER_SHEET] ✅ Filter sheet initialized successfully');
      debugPrint('');
    } catch (e, stackTrace) {
      debugPrint('╔════════════════════════════════════════════════════════╗');
      debugPrint('║ [FILTER_SHEET] ❌ INITIALIZATION ERROR                 ║');
      debugPrint('╚════════════════════════════════════════════════════════╝');
      debugPrint('[FILTER_SHEET] 🔴 Error: $e');
      debugPrint('[FILTER_SHEET] 📚 Stack Trace:');
      debugPrint(stackTrace.toString().split('\n').take(5).join('\n'));
      debugPrint('');
      // Set safe defaults on error
      _selectedCategories = {};
      _minPrice = 0;
      _maxPrice = 1000000;
      _priceRange = RangeValues(_minPrice, _maxPrice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final categories = shopProvider.availableCategories;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    const Text(
                      'No categories available',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        final isSelected = _selectedCategories.contains(
                          category,
                        );
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            try {
                              debugPrint(
                                '[FILTER_SHEET] 🏷️ Category toggled: $category (selected: $selected)',
                              );
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                  debugPrint(
                                    '[FILTER_SHEET] ➕ Added: $category',
                                  );
                                } else {
                                  _selectedCategories.remove(category);
                                  debugPrint(
                                    '[FILTER_SHEET] ➖ Removed: $category',
                                  );
                                }
                                debugPrint(
                                  '[FILTER_SHEET] 📊 Total selected: ${_selectedCategories.length}',
                                );
                              });
                            } catch (e) {
                              debugPrint(
                                '[FILTER_SHEET] ❌ Error toggling category $category: $e',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error selecting category: $e'),
                                ),
                              );
                            }
                          },
                          selectedColor: const Color(
                            0xFFE91E63,
                          ).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFE91E63),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 100,
                    activeColor: const Color(0xFFE91E63),
                    labels: RangeLabels(
                      '₹${_priceRange.start.toStringAsFixed(0)}',
                      '₹${_priceRange.end.toStringAsFixed(0)}',
                    ),
                    onChanged: (values) {
                      try {
                        setState(() {
                          _priceRange = values;
                          _minPrice = values.start;
                          _maxPrice = values.end;
                        });
                        debugPrint(
                          '[FILTER_SHEET] 💰 Price range changed: ₹${_minPrice.toStringAsFixed(0)} - ₹${_maxPrice.toStringAsFixed(0)}',
                        );
                      } catch (e) {
                        debugPrint(
                          '[FILTER_SHEET] ❌ Error updating price range: $e',
                        );
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_minPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${_maxPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      try {
                        debugPrint('');
                        debugPrint('[FILTER_SHEET] 🧹 CLEAR ALL FILTERS');
                        setState(() {
                          _selectedCategories.clear();
                          _minPrice = 0;
                          _maxPrice = 1000000;
                          _priceRange = RangeValues(_minPrice, _maxPrice);
                        });
                        shopProvider.clearFilters();
                        debugPrint('[FILTER_SHEET] ✅ All filters cleared');
                        debugPrint('');
                        Navigator.pop(context);
                      } catch (e, stackTrace) {
                        debugPrint(
                          '[FILTER_SHEET] ❌ Error clearing filters: $e',
                        );
                        debugPrint(
                          stackTrace.toString().split('\n').take(5).join('\n'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error clearing filters: $e')),
                        );
                      }
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        debugPrint('');
                        debugPrint(
                          '╔════════════════════════════════════════════════════════╗',
                        );
                        debugPrint(
                          '║ [FILTER_SHEET] ✅ APPLYING FILTERS                     ║',
                        );
                        debugPrint(
                          '╚════════════════════════════════════════════════════════╝',
                        );
                        debugPrint('[FILTER_SHEET] 📋 Filter Configuration:');
                        debugPrint(
                          '[FILTER_SHEET]   - Categories: $_selectedCategories',
                        );
                        debugPrint(
                          '[FILTER_SHEET]   - Price Range: ₹${_minPrice.toStringAsFixed(0)} - ₹${_maxPrice.toStringAsFixed(0)}',
                        );
                        debugPrint('');

                        int categoriesAdded = 0;
                        int categoriesRemoved = 0;

                        // Add new category selections
                        for (var category in _selectedCategories) {
                          if (!shopProvider.selectedCategories.contains(
                            category,
                          )) {
                            shopProvider.toggleCategory(category);
                            categoriesAdded++;
                            debugPrint(
                              '[FILTER_SHEET] ➕ Applied category: $category',
                            );
                          }
                        }

                        // Remove unselected categories
                        final categoriesToRemove = shopProvider
                            .selectedCategories
                            .where((cat) => !_selectedCategories.contains(cat))
                            .toList();
                        for (var category in categoriesToRemove) {
                          shopProvider.toggleCategory(category);
                          categoriesRemoved++;
                          debugPrint(
                            '[FILTER_SHEET] ➖ Removed category: $category',
                          );
                        }

                        // Apply price range
                        shopProvider.setPriceRange(_minPrice, _maxPrice);

                        debugPrint('');
                        debugPrint('[FILTER_SHEET] 📊 Filter Summary:');
                        debugPrint(
                          '[FILTER_SHEET]   - Categories Added: $categoriesAdded',
                        );
                        debugPrint(
                          '[FILTER_SHEET]   - Categories Removed: $categoriesRemoved',
                        );
                        debugPrint(
                          '[FILTER_SHEET]   - Final Category Count: ${shopProvider.selectedCategories.length}',
                        );
                        debugPrint(
                          '[FILTER_SHEET]   - Price Filter Applied: ₹${_minPrice.toStringAsFixed(0)} - ₹${_maxPrice.toStringAsFixed(0)}',
                        );
                        debugPrint(
                          '[FILTER_SHEET] ✅ Filters applied successfully',
                        );
                        debugPrint(
                          '╚════════════════════════════════════════════════════════╝',
                        );
                        debugPrint('');

                        Navigator.pop(context);
                      } catch (e, stackTrace) {
                        debugPrint('');
                        debugPrint(
                          '╔════════════════════════════════════════════════════════╗',
                        );
                        debugPrint(
                          '║ [FILTER_SHEET] ❌ APPLY FILTERS ERROR                  ║',
                        );
                        debugPrint(
                          '╚════════════════════════════════════════════════════════╝',
                        );
                        debugPrint(
                          '[FILTER_SHEET] 🔴 Error Type: ${e.runtimeType}',
                        );
                        debugPrint('[FILTER_SHEET] 🔴 Error Message: $e');
                        debugPrint('[FILTER_SHEET] 📚 Stack Trace:');
                        debugPrint(
                          stackTrace.toString().split('\n').take(10).join('\n'),
                        );
                        debugPrint(
                          '╚════════════════════════════════════════════════════════╝',
                        );
                        debugPrint('');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error applying filters: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
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
  }
}
