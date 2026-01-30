import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/shop_product_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../../core/routes/app_routes.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final shopProvider = context.read<ShopProvider>();
        return ChangeNotifierProvider.value(
          value: shopProvider,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (_, controller) => const FilterBottomSheet(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            context.read<ShopProvider>().setSearchQuery('');
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                context.read<ShopProvider>().setSearchQuery(value);
              },
            ),
          ),
        ),
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          if (shopProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shopProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    shopProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => shopProvider.loadProducts(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final products = shopProvider.products;

          return Column(
            children: [
              // Filter and Sort Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    // Filter Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showFilters,
                        icon: const Icon(Icons.filter_list),
                        label: Text(
                          'Filters${shopProvider.selectedCategories.isNotEmpty ? " (${shopProvider.selectedCategories.length})" : ""}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE91E63),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort Dropdown
                    Expanded(
                      child: PopupMenuButton<SortOption>(
                        initialValue: shopProvider.sortOption,
                        onSelected: (option) {
                          shopProvider.setSortOption(option);
                        },
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.sort),
                          label: const Text('Sort'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: SortOption.priceLowToHigh,
                            child: Text('Price: Low to High'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.priceHighToLow,
                            child: Text('Price: High to Low'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.nameAtoZ,
                            child: Text('Name: A to Z'),
                          ),
                          const PopupMenuItem(
                            value: SortOption.nameZtoA,
                            child: Text('Name: Z to A'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Product Grid
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty ||
                                      shopProvider.selectedCategories.isNotEmpty
                                  ? 'No products found'
                                  : 'No products available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty ||
                                shopProvider.selectedCategories.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    shopProvider.clearFilters();
                                    setState(() {});
                                  },
                                  child: const Text('Clear filters'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ShopProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.productDetail,
                                arguments: product,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
