import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/monitoring_model.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/monitoring/form_filter_widget.dart';
import '../../widgets/monitoring/form_list_item.dart';

class MonitoringFormsScreen extends StatefulWidget {
  const MonitoringFormsScreen({super.key});

  @override
  State<MonitoringFormsScreen> createState() => _MonitoringFormsScreenState();
}

class _MonitoringFormsScreenState extends State<MonitoringFormsScreen> {
  final _searchController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedStore;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadForms({bool refresh = true}) async {
    final provider = Provider.of<MonitoringProvider>(context, listen: false);
    await provider.fetchMonitoringForms(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      storeName: _selectedStore,
      refresh: refresh,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateFrom = null;
      _dateTo = null;
      _selectedStore = null;
    });
    _loadForms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Forms'),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFilterExpanded ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
      body: Consumer<MonitoringProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
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
                              _loadForms();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _loadForms();
                      }
                    });
                  },
                ),
              ),

              // Filter Section
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isFilterExpanded ? null : 0,
                child: _isFilterExpanded
                    ? FormFilterWidget(
                        dateFrom: _dateFrom,
                        dateTo: _dateTo,
                        selectedStore: _selectedStore,
                        onDateFromChanged: (date) {
                          setState(() {
                            _dateFrom = date;
                          });
                        },
                        onDateToChanged: (date) {
                          setState(() {
                            _dateTo = date;
                          });
                        },
                        onStoreChanged: (store) {
                          setState(() {
                            _selectedStore = store;
                          });
                        },
                        onApplyFilters: () => _loadForms(),
                        onClearFilters: _clearFilters,
                      )
                    : null,
              ),

              // Forms List
              Expanded(
                child: provider.isLoading && provider.monitoringForms.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.monitoringForms.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _loadForms(refresh: true),
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification scrollInfo) {
                                if (!provider.isLoading &&
                                    provider.hasMoreData &&
                                    scrollInfo.metrics.pixels ==
                                        scrollInfo.metrics.maxScrollExtent) {
                                  _loadForms(refresh: false);
                                }
                                return false;
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: provider.monitoringForms.length + (provider.hasMoreData ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= provider.monitoringForms.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final form = provider.monitoringForms[index];
                                  return FormListItem(
                                    form: form,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/form_details',
                                        arguments: form,
                                      );
                                    },
                                    onEdit: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/edit_form',
                                        arguments: form,
                                      );
                                    },
                                    onDelete: () => _showDeleteDialog(context, form),
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_form');
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF3498db),
        foregroundColor: Colors.white,
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
            'Create your first monitoring form to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/create_form');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Form'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498db),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MonitoringForm form) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Monitoring Form'),
        content: Text(
          'Are you sure you want to delete the monitoring form for "${form.storeName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<MonitoringProvider>(context, listen: false);
              final success = await provider.deleteMonitoringForm(form.id!);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monitoring form deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to delete form'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
