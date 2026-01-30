import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vendor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/product_card.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/edit_product_sheet.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({Key? key}) : super(key: key);

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductSheet() {
    final vendorProvider = context.read<VendorProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: vendorProvider,
        child: const AddProductSheet(),
      ),
    );
  }

  void _showEditProductSheet(product) {
    final vendorProvider = context.read<VendorProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: vendorProvider,
        child: EditProductSheet(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<VendorProvider>().removeProduct(
        productId,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      debugPrint('[VENDOR_DASHBOARD] 🚪 Logout initiated');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logging out...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Call logout API and clear auth state
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      debugPrint('[VENDOR_DASHBOARD] ✅ Logout successful');

      // Navigate to landing page and remove all previous routes
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/landing', (route) => false);
      }
    } catch (e) {
      debugPrint('[VENDOR_DASHBOARD] ❌ Logout error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage your products and view statistics',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<VendorProvider>().loadProducts(),
        child: Consumer<VendorProvider>(
          builder: (context, vendorProvider, child) {
            if (vendorProvider.isLoading && vendorProvider.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = _searchQuery.isEmpty
                ? vendorProvider.products
                : vendorProvider.searchProducts(_searchQuery);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Total Products',
                          value: vendorProvider.totalProducts.toString(),
                          icon: Icons.inventory_2,
                          iconColor: const Color(0xFFE91E63),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatsCard(
                          title: 'Total Views',
                          value: vendorProvider.totalViews.toString(),
                          icon: Icons.visibility,
                          iconColor: const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddProductSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
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
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (products.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No products yet'
                                  : 'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isEmpty)
                              Text(
                                'Add your first product to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...products.map((product) {
                      return ProductCard(
                        product: product,
                        onEdit: () => _showEditProductSheet(product),
                        onDelete: () =>
                            _deleteProduct(product.id, product.name),
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
