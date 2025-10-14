import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProducts() async {
    // TODO: Implement product loading
    await Future.delayed(const Duration(seconds: 1));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                itemCount: 15, // Mock data
                itemBuilder: (context, index) {
                  return _buildProductCard(index);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.hasPermission('manage_products')) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: _addProduct,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
  
  Widget _buildProductCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.warningColor,
          child: const Icon(
            Icons.inventory,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Product ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category ${index + 1}'),
            Text(
              '₱${(index + 1) * 100}.00',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProduct(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteProduct(index),
            ),
          ],
        ),
        onTap: () => _viewProduct(index),
      ),
    );
  }
  
  void _addProduct() {
    // TODO: Implement add product
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add product functionality coming soon'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
  
  void _viewProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', 'Product ${index + 1}'),
            _buildInfoRow('Category', 'Category ${index + 1}'),
            _buildInfoRow('Price', '₱${(index + 1) * 100}.00'),
            _buildInfoRow('Status', 'Active'),
            _buildInfoRow('Retailer', 'Retailer ${index + 1}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _editProduct(int index) {
    // TODO: Implement edit product
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit product functionality coming soon'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
  
  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete Product ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete product
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete product functionality coming soon'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
