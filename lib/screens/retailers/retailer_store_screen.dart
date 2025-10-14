import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/retailer_provider.dart';
import '../../models/retailer_model.dart';

class RetailerStoreScreen extends StatefulWidget {
  const RetailerStoreScreen({super.key});

  @override
  State<RetailerStoreScreen> createState() => _RetailerStoreScreenState();
}

class _RetailerStoreScreenState extends State<RetailerStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<RetailerProvider>(context, listen: false);
    await Future.wait([
      provider.fetchRetailerProducts(refresh: true),
      provider.fetchRetailers(),
      provider.fetchRetailerStats(),
      provider.fetchViolationAlerts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Store Management'),
        backgroundColor: const Color(0xFF1E40AF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning),
            onPressed: () {
              Navigator.pushNamed(context, '/retailers/violation-alerts');
            },
            tooltip: 'Violation Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.pushNamed(context, '/retailers/analytics');
            },
            tooltip: 'Analytics',
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
      body: Consumer<RetailerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.retailerProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.retailerProducts.isEmpty) {
            return _buildErrorState(provider.errorMessage!);
          }

          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Retailer Store Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitor and manage all retailer stores, products, and compliance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Overview
                  if (provider.stats != null) _buildStatsSection(provider.stats!),
                  
                  const SizedBox(height: 24),
                  
                  // Retailers List
                  const Text(
                    'Registered Stores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (provider.retailers.isEmpty)
                    _buildEmptyState()
                  else
                    ...provider.retailers.map((retailer) => _buildRetailerCard(retailer)),
                    
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retailer management features coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Retailer'),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildStatsSection(dynamic stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Stores', stats.totalRetailers?.toString() ?? '0', Icons.store, Colors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Products', stats.totalProducts?.toString() ?? '0', Icons.inventory, Colors.blue),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerCard(dynamic retailer) {
    final name = retailer.storeName ?? retailer.name ?? 'Unknown Store';
    final address = retailer.address ?? 'No address';
    final productCount = retailer.productCount ?? 0;
    final complianceRate = retailer.complianceRate ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.purple[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store,
                    color: Colors.purple[600],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$productCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${complianceRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getComplianceColor(complianceRate),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Compliance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Retailer Stores Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No retailers have been registered yet',
            style: TextStyle(color: Colors.grey[600]),
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.pop(context);
                final provider = Provider.of<RetailerProvider>(context, listen: false);
                final url = await provider.exportRetailerData(format: 'csv');
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
                final provider = Provider.of<RetailerProvider>(context, listen: false);
                final url = await provider.exportRetailerData(format: 'xlsx');
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

  Color _getComplianceColor(double compliance) {
    if (compliance >= 80) return Colors.green;
    if (compliance >= 60) return Colors.orange;
    return Colors.red;
  }
}

