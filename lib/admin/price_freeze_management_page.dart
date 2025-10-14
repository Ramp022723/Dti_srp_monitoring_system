import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PriceFreezeManagementPage extends StatefulWidget {
  const PriceFreezeManagementPage({super.key});

  @override
  State<PriceFreezeManagementPage> createState() => _PriceFreezeManagementPageState();
}

class _PriceFreezeManagementPageState extends State<PriceFreezeManagementPage> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _alerts = [];
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _locations = [];
  Map<String, dynamic> _statistics = {};
  
  // Filter states
  String _selectedCategory = 'all';
  String _selectedLocation = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        AuthService.getPriceFreezeAlerts(),
        AuthService.getPriceFreezeProducts(),
        AuthService.getPriceFreezeCategories(),
        AuthService.getPriceFreezeLocations(),
        AuthService.getPriceFreezeStatistics(),
      ]);

      if (results.every((result) => result['status'] == 'success')) {
        setState(() {
          _alerts = results[0]['data']?['data']?['alerts'] ?? results[0]['data']?['alerts'] ?? [];
          _products = results[1]['data']?['data']?['products'] ?? results[1]['data']?['products'] ?? [];
          _categories = results[2]['data']?['data']?['categories'] ?? results[2]['data']?['categories'] ?? [];
          _locations = results[3]['data']?['data']?['locations'] ?? results[3]['data']?['locations'] ?? [];
          _statistics = results[4]['data']?['data'] ?? results[4]['data'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Price Freeze Management'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildMainContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateAlertDialog,
          icon: const Icon(Icons.add_alert),
          label: const Text('Create Alert'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Statistics Cards
        _buildStatisticsCards(),
        
        // Filters
        _buildFilters(),
        
        // Alerts List
        Expanded(
          child: _buildAlertsList(),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Alerts',
              _statistics['total_alerts']?.toString() ?? '0',
              Icons.notifications,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Active Alerts',
              _statistics['active_alerts']?.toString() ?? '0',
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Resolved',
              _statistics['resolved_alerts']?.toString() ?? '0',
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                ..._categories.map((category) => DropdownMenuItem(
                  value: category['id'].toString(),
                  child: Text(category['name'] ?? 'Unknown'),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'all';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'expired', child: Text('Expired')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? 'all';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    final filteredAlerts = _getFilteredAlerts();
    
    if (filteredAlerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No price freeze alerts found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAlerts.length,
      itemBuilder: (context, index) {
        final alert = filteredAlerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final status = alert['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          alert['product_name'] ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${alert['category_name'] ?? 'N/A'}'),
            Text('Location: ${alert['location_name'] ?? 'N/A'}'),
            Text('Price: ₱${alert['current_price']?.toString() ?? 'N/A'}'),
            Text('Alert Price: ₱${alert['alert_price']?.toString() ?? 'N/A'}'),
            Text('Status: ${status.toUpperCase()}'),
            if (alert['created_at'] != null)
              Text('Created: ${_formatDate(alert['created_at'])}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAlertAction(value, alert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            if (status == 'active')
              const PopupMenuItem(
                value: 'resolve',
                child: Row(
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 8),
                    Text('Mark Resolved'),
                  ],
                ),
              ),
            if (status == 'resolved')
              const PopupMenuItem(
                value: 'reactivate',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reactivate'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showAlertDetails(alert),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.warning;
      case 'resolved':
        return Icons.check_circle;
      case 'expired':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  List<dynamic> _getFilteredAlerts() {
    return _alerts.where((alert) {
      // Category filter
      if (_selectedCategory != 'all') {
        if (alert['category_id']?.toString() != _selectedCategory) {
          return false;
        }
      }
      
      // Status filter
      if (_selectedStatus != 'all') {
        if (alert['status']?.toString().toLowerCase() != _selectedStatus) {
          return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final productName = alert['product_name']?.toString().toLowerCase() ?? '';
        final categoryName = alert['category_name']?.toString().toLowerCase() ?? '';
        final locationName = alert['location_name']?.toString().toLowerCase() ?? '';
        
        if (!productName.contains(query) && 
            !categoryName.contains(query) && 
            !locationName.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      // Trigger rebuild with new filters
    });
  }

  void _handleAlertAction(String action, dynamic alert) {
    switch (action) {
      case 'view':
        _showAlertDetails(alert);
        break;
      case 'resolve':
        _resolveAlert(alert);
        break;
      case 'reactivate':
        _reactivateAlert(alert);
        break;
      case 'edit':
        _showEditAlertDialog(alert);
        break;
      case 'delete':
        _deleteAlert(alert);
        break;
    }
  }

  void _showAlertDetails(dynamic alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert['product_name'] ?? 'Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', alert['category_name'] ?? 'N/A'),
              _buildDetailRow('Location', alert['location_name'] ?? 'N/A'),
              _buildDetailRow('Current Price', '₱${alert['current_price']?.toString() ?? 'N/A'}'),
              _buildDetailRow('Alert Price', '₱${alert['alert_price']?.toString() ?? 'N/A'}'),
              _buildDetailRow('Status', alert['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              _buildDetailRow('Created', _formatDate(alert['created_at'] ?? '')),
              if (alert['resolved_at'] != null)
                _buildDetailRow('Resolved', _formatDate(alert['resolved_at'])),
              if (alert['notes'] != null && alert['notes'].toString().isNotEmpty)
                _buildDetailRow('Notes', alert['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showCreateAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAlertDialog(
        products: _products,
        categories: _categories,
        locations: _locations,
        onAlertCreated: _loadData,
      ),
    );
  }

  void _showEditAlertDialog(dynamic alert) {
    showDialog(
      context: context,
      builder: (context) => _EditAlertDialog(
        alert: alert,
        products: _products,
        categories: _categories,
        locations: _locations,
        onAlertUpdated: _loadData,
      ),
    );
  }

  Future<void> _resolveAlert(dynamic alert) async {
    try {
      final result = await AuthService.updatePriceFreezeAlertStatus(
        alertId: int.parse(alert['id'].toString()),
        status: 'resolved',
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to resolve alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reactivateAlert(dynamic alert) async {
    try {
      final result = await AuthService.updatePriceFreezeAlertStatus(
        alertId: int.parse(alert['id'].toString()),
        status: 'active',
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert reactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to reactivate alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlert(dynamic alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Are you sure you want to delete the alert for "${alert['product_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AuthService.deletePriceFreezeAlert(
          alertId: int.parse(alert['id'].toString()),
        );
        
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete alert'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Create Alert Dialog
class _CreateAlertDialog extends StatefulWidget {
  final List<dynamic> products;
  final List<dynamic> categories;
  final List<dynamic> locations;
  final VoidCallback onAlertCreated;

  const _CreateAlertDialog({
    required this.products,
    required this.categories,
    required this.locations,
    required this.onAlertCreated,
  });

  @override
  State<_CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<_CreateAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedProductId;
  int? _selectedCategoryId;
  int? _selectedLocationId;
  final _alertPriceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Price Freeze Alert'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedProductId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: widget.products.map((product) => DropdownMenuItem<int>(
                  value: product['id'] as int,
                  child: Text(product['name'] ?? 'Unknown'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a product' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alertPriceController,
                decoration: const InputDecoration(labelText: 'Alert Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter alert price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAlert,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.createPriceFreezeAlert(
        title: 'Price Alert for Product ${_selectedProductId}',
        message: _notesController.text.isEmpty ? 'Price freeze alert' : _notesController.text,
        freezeStartDate: DateTime.now().toIso8601String().split('T')[0],
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onAlertCreated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Edit Alert Dialog
class _EditAlertDialog extends StatefulWidget {
  final dynamic alert;
  final List<dynamic> products;
  final List<dynamic> categories;
  final List<dynamic> locations;
  final VoidCallback onAlertUpdated;

  const _EditAlertDialog({
    required this.alert,
    required this.products,
    required this.categories,
    required this.locations,
    required this.onAlertUpdated,
  });

  @override
  State<_EditAlertDialog> createState() => _EditAlertDialogState();
}

class _EditAlertDialogState extends State<_EditAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _alertPriceController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _alertPriceController = TextEditingController(
      text: widget.alert['alert_price']?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.alert['notes']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Price Freeze Alert'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Product: ${widget.alert['product_name'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alertPriceController,
                decoration: const InputDecoration(labelText: 'Alert Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter alert price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateAlert,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updatePriceFreezeAlert(
        alertId: int.parse(widget.alert['id'].toString()),
        message: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onAlertUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
