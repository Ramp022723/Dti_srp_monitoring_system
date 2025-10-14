import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/products/stats_card_widget.dart';
import '../../widgets/products/product_list_widget.dart';
import '../../widgets/products/search_filter_bar.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await Future.wait([
      provider.fetchProducts(refresh: true),
      provider.fetchCategories(),
      provider.fetchFolders(),
      provider.fetchPriceAnalytics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Price Management'),
        backgroundColor: const Color(0xFF1D4ED8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.pushNamed(context, '/products/analytics');
            },
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.products.isEmpty) {
            return _buildErrorState(provider.errorMessage!);
          }

          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: Column(
              children: [
                // Search and Filter Bar
                SearchFilterBar(
                  onSearch: (query) {
                    provider.filters.search = query;
                    provider.fetchProducts(refresh: true);
                  },
                  onFilterPressed: () => _showFilterDialog(context),
                ),

                // Statistics Cards
                StatsCardWidget(
                  analytics: provider.priceAnalytics,
                  localStats: provider.calculateLocalStats(),
                ),

                // Bulk Action Bar (when products are selected)
                if (provider.hasSelectedProducts)
                  _buildBulkActionBar(context, provider),

                // Product List
                Expanded(
                  child: ProductListWidget(
                    products: provider.products,
                    selectedIds: provider.selectedProductIds,
                    onProductTap: (product) {
                      Navigator.pushNamed(
                        context,
                        '/products/details',
                        arguments: product,
                      );
                    },
                    onProductLongPress: (product) {
                      provider.toggleProductSelection(product.productId);
                    },
                    onSelectionChanged: (productId, selected) {
                      provider.toggleProductSelection(productId);
                    },
                    onLoadMore: () => provider.loadMoreProducts(),
                    hasMore: provider.hasMoreData,
                    isLoading: provider.isLoading,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/products/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, ProductProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => provider.clearSelection(),
          ),
          Text(
            '${provider.selectedCount} selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showBulkSRPUpdateDialog(context, provider),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Update SRP', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => _showMoveToFolderDialog(context, provider),
            icon: const Icon(Icons.folder, color: Colors.white),
            label: const Text('Move', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    // TODO: Implement filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: const Text('Filter dialog will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.pop(context);
                final provider = Provider.of<ProductProvider>(context, listen: false);
                final url = await provider.exportProducts(format: 'csv');
                if (url != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export ready for download')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as Excel'),
              onTap: () async {
                Navigator.pop(context);
                final provider = Provider.of<ProductProvider>(context, listen: false);
                final url = await provider.exportProducts(format: 'xlsx');
                if (url != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export ready for download')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkSRPUpdateDialog(BuildContext context, ProductProvider provider) {
    final srpController = TextEditingController();
    DateTime effectiveDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Update SRP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update SRP for ${provider.selectedCount} products'),
            const SizedBox(height: 16),
            TextField(
              controller: srpController,
              decoration: const InputDecoration(
                labelText: 'New SRP',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Effective Date'),
              subtitle: Text('${effectiveDate.day}/${effectiveDate.month}/${effectiveDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: effectiveDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  effectiveDate = picked;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final srp = double.tryParse(srpController.text);
              if (srp != null && srp > 0) {
                Navigator.pop(context);
                final success = await provider.bulkUpdateSRP(
                  productIds: provider.selectedProductIds.toList(),
                  newSRP: srp,
                  effectiveDate: effectiveDate,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SRP updated successfully')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(BuildContext context, ProductProvider provider) {
    // TODO: Implement move to folder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: const Text('Move to folder dialog will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

