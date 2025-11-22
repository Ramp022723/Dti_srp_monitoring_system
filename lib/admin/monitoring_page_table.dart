import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/monitoring_model.dart';
import '../providers/monitoring_provider.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Monitoring Page with Table View
/// Displays monitoring forms in a table format from product_monitoring_api.php
class MonitoringPageTable extends StatefulWidget {
  const MonitoringPageTable({super.key});

  @override
  State<MonitoringPageTable> createState() => _MonitoringPageTableState();
}

class _MonitoringPageTableState extends State<MonitoringPageTable> {
  final _searchController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedStore;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _monitoringForms = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadMonitoringForms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMonitoringForms({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _monitoringForms.clear();
        _hasMoreData = true;
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (!_hasMoreData || _isLoading) {
      return;
    }

    try {
      print('📊 Loading monitoring forms from product_monitoring_api.php...');
      
      final Map<String, String> queryParams = {
        'action': 'get_forms',
        'page': _currentPage.toString(),
        'limit': _limit.toString(),
      };

      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }
      if (_dateFrom != null) {
        queryParams['date_from'] = _dateFrom!.toIso8601String().split('T')[0];
      }
      if (_dateTo != null) {
        queryParams['date_to'] = _dateTo!.toIso8601String().split('T')[0];
      }
      if (_selectedStore != null && _selectedStore!.isNotEmpty) {
        queryParams['store_name'] = _selectedStore!;
      }

      final uri = Uri.parse('https://dtisrpmonitoring.bccbsis.com/api/admin/product_monitoring_api.php')
          .replace(queryParameters: queryParams);

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'login_app/1.0',
        if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
      };

      final httpResponse = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      print('📊 API Response Status: ${httpResponse.statusCode}');
      print('📊 API Response Body: ${httpResponse.body.substring(0, httpResponse.body.length > 1000 ? 1000 : httpResponse.body.length)}');

      if (httpResponse.statusCode == 200) {
        final response = json.decode(httpResponse.body);
        
        if (response['status'] == 'success' || response['success'] == true) {
          final data = response['data'] ?? response;
          List<dynamic> formsList = [];

          // Handle different response structures
          if (data['forms'] != null) {
            formsList = data['forms'] as List;
          } else if (data['data'] != null) {
            if (data['data'] is List) {
              formsList = data['data'] as List;
            } else if (data['data'] is Map && data['data']['forms'] != null) {
              formsList = data['data']['forms'] as List;
            }
          } else if (data['results'] != null) {
            formsList = data['results'] as List;
          } else if (response['forms'] != null) {
            formsList = response['forms'] as List;
          } else if (response is List) {
            formsList = response;
          }

          final List<Map<String, dynamic>> newForms = formsList
              .map((form) => form is Map<String, dynamic> ? form : {} as Map<String, dynamic>)
              .where((form) => form.isNotEmpty)
              .toList();

          if (mounted) {
            setState(() {
              if (refresh) {
                _monitoringForms = newForms;
              } else {
                _monitoringForms.addAll(newForms);
              }
              _hasMoreData = newForms.length >= _limit;
              _currentPage++;
              _isLoading = false;
            });
          }
        } else {
          throw Exception(response['message'] ?? response['error'] ?? 'Failed to fetch monitoring forms');
        }
      } else {
        throw Exception('Failed to fetch monitoring forms: ${httpResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading monitoring forms: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateFrom = null;
      _dateTo = null;
      _selectedStore = null;
    });
    _loadMonitoringForms(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Monitoring Forms',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: () => _loadMonitoringForms(refresh: true),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchBar(),
          
          // Table View
          Expanded(
            child: _isLoading && _monitoringForms.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _monitoringForms.isEmpty
                    ? _buildErrorWidget()
                    : _monitoringForms.isEmpty
                        ? _buildEmptyState()
                        : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by store name, representative, or DTI monitor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadMonitoringForms(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                _loadMonitoringForms(refresh: true);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filters',
          ),
          if (_searchController.text.isNotEmpty ||
              _dateFrom != null ||
              _dateTo != null ||
              _selectedStore != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Monitoring Forms'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date From'),
              subtitle: Text(_dateFrom?.toString().split(' ')[0] ?? 'Not set'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateFrom = date);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Date To'),
              subtitle: Text(_dateTo?.toString().split(' ')[0] ?? 'Not set'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateTo ?? DateTime.now(),
                    firstDate: _dateFrom ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _dateTo = date);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadMonitoringForms(refresh: true);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF2563EB)),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dataRowMinHeight: 50,
                dataRowMaxHeight: 80,
                columns: const [
                  DataColumn(label: Text('ID'), numeric: true),
                  DataColumn(label: Text('Store Name')),
                  DataColumn(label: Text('Store Address')),
                  DataColumn(label: Text('Monitoring Date')),
                  DataColumn(label: Text('Mode')),
                  DataColumn(label: Text('Store Rep')),
                  DataColumn(label: Text('DTI Monitor')),
                  DataColumn(label: Text('Products'), numeric: true),
                  DataColumn(label: Text('Actions')),
                ],
          rows: _monitoringForms.asMap().entries.map((entry) {
            final index = entry.key;
            final form = entry.value;
            
            final formId = form['id'] ?? form['form_id'] ?? index + 1;
            final storeName = form['store_name'] ?? form['storeName'] ?? 'N/A';
            final storeAddress = form['store_address'] ?? form['storeAddress'] ?? 'N/A';
            final monitoringDate = form['monitoring_date'] ?? form['monitoringDate'] ?? '';
            final monitoringMode = form['monitoring_mode'] ?? form['monitoringMode'] ?? 'N/A';
            final storeRep = form['store_rep'] ?? form['storeRep'] ?? 'N/A';
            final dtiMonitor = form['dti_monitor'] ?? form['dtiMonitor'] ?? 'N/A';
            final productsCount = form['products_count'] ?? 
                                 form['productsCount'] ?? 
                                 (form['products'] != null ? (form['products'] as List).length : 0);

            return DataRow(
              cells: [
                DataCell(Text(formId.toString())),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      storeName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      storeAddress,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(
                  monitoringDate.toString().split(' ')[0],
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(Text(monitoringMode)),
                DataCell(Text(storeRep)),
                DataCell(Text(dtiMonitor)),
                DataCell(Text(productsCount.toString())),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        color: Colors.blue,
                        onPressed: () => _viewForm(form),
                        tooltip: 'View',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () => _deleteForm(form),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
              ),
            ),
          ),
        ),
        // Pagination
        if (_hasMoreData)
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _loadMonitoringForms(refresh: false),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More'),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadMonitoringForms(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No monitoring forms found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search query'
                : 'Monitoring forms will appear here once created',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _viewForm(Map<String, dynamic> form) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Monitoring Form: ${form['store_name'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', form['id']?.toString() ?? 'N/A'),
              _buildDetailRow('Store Name', form['store_name'] ?? 'N/A'),
              _buildDetailRow('Store Address', form['store_address'] ?? 'N/A'),
              _buildDetailRow('Monitoring Date', form['monitoring_date']?.toString().split(' ')[0] ?? 'N/A'),
              _buildDetailRow('Monitoring Mode', form['monitoring_mode'] ?? 'N/A'),
              _buildDetailRow('Store Rep', form['store_rep'] ?? 'N/A'),
              _buildDetailRow('DTI Monitor', form['dti_monitor'] ?? 'N/A'),
              if (form['products'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Products:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((form['products'] as List).map((product) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text('• ${product['product_name'] ?? 'N/A'}'),
                    ))),
              ],
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
            width: 120,
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

  void _deleteForm(Map<String, dynamic> form) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Monitoring Form'),
        content: Text(
          'Are you sure you want to delete the monitoring form for "${form['store_name'] ?? 'N/A'}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality to be implemented'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

