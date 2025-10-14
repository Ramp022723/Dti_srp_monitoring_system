import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class RetailerManagementScreen extends StatefulWidget {
  const RetailerManagementScreen({super.key});

  @override
  State<RetailerManagementScreen> createState() => _RetailerManagementScreenState();
}

class _RetailerManagementScreenState extends State<RetailerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadRetailers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRetailers() async {
    // TODO: Implement retailer loading
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
                hintText: 'Search retailers...',
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
          
          // Retailers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRetailers,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                itemCount: 10, // Mock data
                itemBuilder: (context, index) {
                  return _buildRetailerCard(index);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.hasPermission('manage_retailers')) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: _addRetailer,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
  
  Widget _buildRetailerCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.successColor,
          child: const Icon(
            Icons.store,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Retailer ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Store Name ${index + 1}'),
            Text(
              'Location ${index + 1}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editRetailer(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRetailer(index),
            ),
          ],
        ),
        onTap: () => _viewRetailer(index),
      ),
    );
  }
  
  void _addRetailer() {
    // TODO: Implement add retailer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add retailer functionality coming soon'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
  
  void _viewRetailer(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retailer ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Store Name', 'Store Name ${index + 1}'),
            _buildInfoRow('Location', 'Location ${index + 1}'),
            _buildInfoRow('Status', 'Active'),
            _buildInfoRow('Products', '${(index + 1) * 10}'),
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
  
  void _editRetailer(int index) {
    // TODO: Implement edit retailer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit retailer functionality coming soon'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
  
  void _deleteRetailer(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Retailer'),
        content: Text('Are you sure you want to delete Retailer ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete retailer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete retailer functionality coming soon'),
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
