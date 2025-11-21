import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/retailer_provider.dart';
import '../../models/retailer_model.dart';
import '../../services/auth_service.dart';
import 'dart:async';
import 'dart:convert';

class RetailerStoreScreen extends StatefulWidget {
  const RetailerStoreScreen({super.key});

  @override
  State<RetailerStoreScreen> createState() => _RetailerStoreScreenState();
}

class _RetailerStoreScreenState extends State<RetailerStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedComplianceFilter = 'all'; // all, compliant, violations
  String _selectedViolationFilter = 'all'; // all, minor, critical
  bool _showFilters = false;
  Timer? _searchDebounce;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });
    
    // Debounce search to avoid too many API calls
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _performSearch(query);
    });
  }
  
  void _performSearch(String query) {
    final provider = Provider.of<RetailerProvider>(context, listen: false);
    final filters = provider.filters;
    
    // Update provider filters with unified search that searches both retailers and products
    filters.retailerSearch = query.isNotEmpty ? query : null;
    filters.productSearch = query.isNotEmpty ? query : null;
    provider.updateFilters(filters);
    
    // Always fetch fresh data when searching or filtering
    // The filtering will be applied client-side to search both retailers and their products
    provider.fetchRetailerProducts(refresh: true);
    provider.fetchRetailers(search: query.isNotEmpty ? query : null);
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
                  
                  // Unified Search Bar
                  _buildSearchBar(),
                  
                  const SizedBox(height: 16),
                  
                  // Filter Section
                  if (_showFilters) _buildFilterSection(provider),
                  
                  const SizedBox(height: 16),
                  
                  // Statistics Overview
                  if (provider.stats != null) _buildStatsSection(provider.stats!),
                  
                  const SizedBox(height: 24),
                  
                  // Retailers List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const Text(
                    'Registered Stores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                      if (_searchQuery.isNotEmpty || _selectedComplianceFilter != 'all' || _selectedViolationFilter != 'all')
                        Chip(
                          label: Text('${_getFilteredRetailers(provider).length} results'),
                          avatar: Icon(Icons.filter_list, size: 18),
                          onDeleted: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                              _selectedComplianceFilter = 'all';
                              _selectedViolationFilter = 'all';
                              _showFilters = false;
                            });
                            final filters = provider.filters;
                            filters.clear();
                            provider.updateFilters(filters);
                            provider.fetchRetailerProducts(refresh: true);
                            provider.fetchRetailers();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_getFilteredRetailers(provider).isEmpty)
                    _buildEmptyState()
                  else
                    ..._getFilteredRetailers(provider).map((retailer) => _buildRetailerCard(retailer, provider)),
                    
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRetailerDialog(context),
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

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search retailers, stores, or products...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      // Optionally reset filters when clearing search
                      // _selectedComplianceFilter = 'all';
                      // _selectedViolationFilter = 'all';
                    });
                    // Clear search filters but keep other filters
                    final provider = Provider.of<RetailerProvider>(context, listen: false);
                    final filters = provider.filters;
                    filters.retailerSearch = null;
                    filters.productSearch = null;
                    provider.updateFilters(filters);
                    provider.fetchRetailerProducts(refresh: true);
                    provider.fetchRetailers();
                  },
                ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                  color: (_selectedComplianceFilter != 'all' || _selectedViolationFilter != 'all')
                      ? const Color(0xFF2563EB)
                      : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                tooltip: 'Filters',
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterSection(RetailerProvider provider) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedComplianceFilter = 'all';
                    _selectedViolationFilter = 'all';
                  });
                  _applyFilters(provider);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Compliance Filter
          const Text(
            'Compliance Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('All', 'all', _selectedComplianceFilter, (value) {
                setState(() {
                  _selectedComplianceFilter = value;
                });
                _applyFilters(provider);
              }),
              _buildFilterChip('Compliant', 'compliant', _selectedComplianceFilter, (value) {
                setState(() {
                  _selectedComplianceFilter = value;
                });
                _applyFilters(provider);
              }),
              _buildFilterChip('Violations', 'violations', _selectedComplianceFilter, (value) {
                setState(() {
                  _selectedComplianceFilter = value;
                });
                _applyFilters(provider);
              }),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Violation Level Filter
          const Text(
            'Violation Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('All', 'all', _selectedViolationFilter, (value) {
                setState(() {
                  _selectedViolationFilter = value;
                });
                _applyFilters(provider);
              }),
              _buildFilterChip('Minor', 'minor', _selectedViolationFilter, (value) {
                setState(() {
                  _selectedViolationFilter = value;
                });
                _applyFilters(provider);
              }),
              _buildFilterChip('Critical', 'critical', _selectedViolationFilter, (value) {
                setState(() {
                  _selectedViolationFilter = value;
                });
                _applyFilters(provider);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelected) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(value);
      },
      selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  void _applyFilters(RetailerProvider provider) {
    final filters = provider.filters;
    
    // Update anomaly filter based on compliance and violation filters
    if (_selectedComplianceFilter == 'violations') {
      if (_selectedViolationFilter == 'minor') {
        filters.anomalyFilter = 'minor_violation';
      } else if (_selectedViolationFilter == 'critical') {
        filters.anomalyFilter = 'critical';
      } else {
        filters.anomalyFilter = 'anomaly'; // All violations
      }
    } else if (_selectedComplianceFilter == 'compliant') {
      filters.anomalyFilter = null;
    } else {
      filters.anomalyFilter = null;
    }
    
    // Maintain search query when applying filters
    if (_searchQuery.isNotEmpty) {
      filters.retailerSearch = _searchQuery;
      filters.productSearch = _searchQuery;
    }
    
    provider.updateFilters(filters);
    // Fetch fresh data with filters applied
    provider.fetchRetailerProducts(refresh: true);
    provider.fetchRetailers(search: _searchQuery.isNotEmpty ? _searchQuery : null);
  }

  List<dynamic> _getFilteredRetailers(RetailerProvider provider) {
    List<dynamic> filtered = List.from(provider.retailers);
    
    // Apply search filter - searches both retailer info and their products
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((retailer) {
        // Search retailer fields
        final name = (retailer.storeName ?? retailer.name ?? '').toLowerCase();
        final address = (retailer.address ?? '').toLowerCase();
        final username = (retailer.username ?? retailer.retailerUsername ?? '').toLowerCase();
        
        final matchesRetailer = name.contains(query) || 
                               address.contains(query) || 
                               username.contains(query);
        
        // Also check if retailer has products matching search
        final retailerId = retailer.retailerId ?? retailer.id;
        final hasMatchingProducts = provider.retailerProducts.any((product) {
          if (product.retailerId != retailerId) return false;
          final productName = (product.productName ?? '').toLowerCase();
          final brand = (product.brand ?? '').toLowerCase();
          final manufacturer = (product.manufacturer ?? '').toLowerCase();
          return productName.contains(query) || 
                 brand.contains(query) || 
                 manufacturer.contains(query);
        });
        
        return matchesRetailer || hasMatchingProducts;
      }).toList();
    }
    
    // Apply compliance filter
    if (_selectedComplianceFilter == 'compliant') {
      filtered = filtered.where((retailer) {
        final complianceRate = retailer.complianceRate ?? 0.0;
        return complianceRate >= 100.0;
      }).toList();
    } else if (_selectedComplianceFilter == 'violations') {
      filtered = filtered.where((retailer) {
        final complianceRate = retailer.complianceRate ?? 0.0;
        // Retailer has violations if compliance rate < 100% or has violation products
        final retailerId = retailer.retailerId ?? retailer.id;
        final hasViolationProducts = provider.retailerProducts.any((product) {
          return product.retailerId == retailerId && !product.isCompliant;
        });
        return complianceRate < 100.0 || hasViolationProducts;
      }).toList();
      
      // Further filter by violation level if selected
      if (_selectedViolationFilter == 'minor') {
        filtered = filtered.where((retailer) {
          final retailerId = retailer.retailerId ?? retailer.id;
          return provider.retailerProducts.any((product) {
            return product.retailerId == retailerId && product.isMinorViolation;
          });
        }).toList();
      } else if (_selectedViolationFilter == 'critical') {
        filtered = filtered.where((retailer) {
          final retailerId = retailer.retailerId ?? retailer.id;
          return provider.retailerProducts.any((product) {
            return product.retailerId == retailerId && product.isCriticalViolation;
          });
        }).toList();
      }
    }
    
    return filtered;
  }

  Widget _buildRetailerCard(dynamic retailer, RetailerProvider provider) {
    
    // Extract retailer data with fallbacks for field name variations
    final name = retailer.storeName ?? retailer.name ?? 'Unknown Store';
    final address = retailer.address ?? 'No address';
    
    // Get retailer ID - check all possible field names to match with products
    // CRITICAL: Products use retailer_register_id, but Retailer.fromJson prioritizes retailer_id
    // So we need to try retailer_register_id FIRST to match products correctly
    dynamic retailerId;
    dynamic retailerRegisterId; // Store this separately for product matching
    
    if (retailer is Map) {
      // If retailer is a Map, prioritize retailer_register_id to match products
      retailerRegisterId = retailer['retailer_register_id'];
      retailerId = retailerRegisterId ?? 
                   retailer['retailer_id'] ?? 
                   retailer['id'] ??
                   retailer['retailerId'];
    } else {
      // If retailer is a Retailer object, we need to try both IDs
      // Since Retailer.fromJson prioritizes retailer_id, we'll use retailerId
      // But we'll also try to match products using both the retailerId and by store name
      retailerId = retailer.retailerId ?? retailer.id;
      // Note: Retailer object doesn't store retailer_register_id separately if retailer_id was used
      // So we'll rely on the retailerId matching, and fallback to store name matching
      retailerRegisterId = null; // Can't access original retailer_register_id from Retailer object
    }
    
    // Get product count - try from retailer object first, then calculate from products
    int productCount = retailer.productCount ?? 0;
    
    // Get products for this specific retailer with search and filter
    // Products use retailer_register_id, so we need to match that field
    // Convert both IDs to strings for comparison to handle type mismatches
    final retailerIdStr = retailerId?.toString();
    final retailerRegisterIdStr = retailerRegisterId?.toString();
    
    // Debug logging
    print('🔍 Matching products for store: $name');
    print('   Retailer ID: $retailerIdStr');
    print('   Retailer Register ID: $retailerRegisterIdStr');
    print('   Total products in provider: ${provider.retailerProducts.length}');
    
    if (retailerIdStr == null || retailerIdStr == '0' || retailerIdStr == 'null') {
      print('⚠️ Retailer ID is null or invalid: $retailerIdStr');
    }
    
    // Try to match products - use multiple strategies since ID fields might differ
    List<dynamic> storeProducts = provider.retailerProducts
        .where((product) {
          // Strategy 1: Match by retailer_register_id (what products use)
          bool matchesByRegisterId = false;
          if (retailerRegisterIdStr != null && retailerRegisterIdStr != '0' && retailerRegisterIdStr != 'null') {
            final productRetailerId = product.retailerId?.toString();
            matchesByRegisterId = productRetailerId == retailerRegisterIdStr;
          }
          
          // Strategy 2: Match by retailerId (in case they're the same)
          bool matchesById = false;
          if (!matchesByRegisterId && retailerIdStr != null && retailerIdStr != '0' && retailerIdStr != 'null') {
            final productRetailerId = product.retailerId?.toString();
            matchesById = productRetailerId == retailerIdStr;
          }
          
          // Strategy 3: Fallback match by store name (in case ID matching fails)
          bool matchesByName = false;
          if (!matchesByRegisterId && !matchesById) {
            final productStoreName = product.storeName?.toLowerCase().trim() ?? '';
            final retailerStoreName = name.toLowerCase().trim();
            matchesByName = productStoreName.isNotEmpty && 
                           retailerStoreName.isNotEmpty && 
                           productStoreName == retailerStoreName;
          }
          
          final matches = matchesByRegisterId || matchesById || matchesByName;
          
          if (matches) {
            final matchType = matchesByRegisterId ? "by register_id" : (matchesById ? "by ID" : "by name");
            print('✅ Found product: ${product.productName} for retailer (${matchType})');
          }
          
          return matches;
        })
        .toList();
    
    print('📊 Found ${storeProducts.length} products for retailer $retailerIdStr (Store: $name)');
    
    // Apply search filter to products - searches product name, brand, and manufacturer
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      storeProducts = storeProducts.where((product) {
        final productName = (product.productName ?? '').toLowerCase();
        final brand = (product.brand ?? '').toLowerCase();
        final manufacturer = (product.manufacturer ?? '').toLowerCase();
        return productName.contains(query) || 
               brand.contains(query) || 
               manufacturer.contains(query);
      }).toList();
    }
    
    // Apply violation filter to products
    if (_selectedViolationFilter == 'minor') {
      storeProducts = storeProducts.where((product) => product.isMinorViolation).toList();
    } else if (_selectedViolationFilter == 'critical') {
      storeProducts = storeProducts.where((product) => product.isCriticalViolation).toList();
    } else if (_selectedComplianceFilter == 'compliant') {
      storeProducts = storeProducts.where((product) => product.isCompliant).toList();
    } else if (_selectedComplianceFilter == 'violations') {
      storeProducts = storeProducts.where((product) => !product.isCompliant).toList();
    }
    
    // If product count is 0 or missing, calculate from retailer products
    if (productCount == 0 && storeProducts.isNotEmpty) {
      productCount = storeProducts.length;
    }
    
    // Get compliance rate with fallback
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
          // Store Prices Section
          if (storeProducts.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Store Prices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        '${storeProducts.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Show up to 5 products, or all if less than 5
                  ...storeProducts.take(5).map((product) => _buildProductPriceRow(product)),
                  if (storeProducts.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${storeProducts.length - 5} more products',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'No products with prices available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductPriceRow(dynamic product) {
    final productName = product.productName ?? 'Unknown Product';
    final currentPrice = product.currentRetailPrice ?? 0.0;
    final srp = product.srp ?? 0.0;
    final effectiveMrp = product.effectiveMrp ?? 0.0;
    final isCompliant = product.isCompliant ?? true;
    
    // Determine price status
    Color priceColor = Colors.green;
    String priceStatus = 'Compliant';
    if (currentPrice > effectiveMrp) {
      priceColor = Colors.red;
      priceStatus = 'Above MRP';
    } else if (currentPrice > srp) {
      priceColor = Colors.orange;
      priceStatus = 'Above SRP';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₱${currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: priceColor,
                      ),
                    ),
                    if (srp > 0 && currentPrice != srp) ...[
                      const SizedBox(width: 8),
                      Text(
                        'SRP: ₱${srp.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompliant ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCompliant ? Colors.green[200]! : Colors.red[200]!,
                width: 1,
              ),
            ),
            child: Text(
              priceStatus,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: priceColor,
              ),
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

  void _showAddRetailerDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AddRetailerDialog(
        onSuccess: () {
          _loadInitialData();
        },
      ),
    );
  }
}

// Separate StatefulWidget for the Add Retailer Dialog
class _AddRetailerDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _AddRetailerDialog({required this.onSuccess});

  @override
  State<_AddRetailerDialog> createState() => _AddRetailerDialogState();
}

class _AddRetailerDialogState extends State<_AddRetailerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedLocationId;
  bool _isLoading = false;
  bool _isLoadingLocations = true;
  List<Map<String, dynamic>> _locations = [];
  bool _isObscured = true;
  bool _isConfirmObscured = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final result = await AuthService.getPriceFreezeLocations();
      if (result['status'] == 'success') {
        final data = result['data'] ?? {};
        final locationsData = data['locations'] ?? data['data'] ?? [];
        if (locationsData is List) {
          if (mounted) {
            setState(() {
              _locations = locationsData.map((loc) {
                if (loc is Map<String, dynamic>) {
                  return loc;
                }
                return {'location_id': 0, 'location_name': 'Unknown'};
              }).toList();
              _isLoadingLocations = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingLocations = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocations = false;
          });
        }
      }
    } catch (e) {
      print('Error loading locations: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
          minWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Bar
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_business, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add New Retailer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Store Name
                        TextFormField(
                          controller: _storeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Store Name *',
                            hintText: 'Enter store name',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Store name is required';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        
                        // Owner Name
                        TextFormField(
                          controller: _ownerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Owner Name *',
                            hintText: 'Enter owner full name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Owner name is required';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        
                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            hintText: 'Enter unique username',
                            prefixIcon: Icon(Icons.account_circle),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username is required';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.none,
                        ),
                        const SizedBox(height: 16),
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            hintText: 'Enter password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*])').hasMatch(value)) {
                              return 'Password must contain uppercase, number, and special character';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _isConfirmObscured,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            hintText: 'Re-enter password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmObscured ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isConfirmObscured = !_isConfirmObscured;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Location Dropdown
                        _isLoadingLocations
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedLocationId,
                                decoration: const InputDecoration(
                                  labelText: 'Location *',
                                  prefixIcon: Icon(Icons.location_on),
                                  border: OutlineInputBorder(),
                                ),
                                items: _locations.map((location) {
                                  final id = location['location_id'] ?? location['id'] ?? 0;
                                  final name = location['location_name'] ?? location['name'] ?? 'Unknown';
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLocationId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a location';
                                  }
                                  return null;
                                },
                              ),
                        const SizedBox(height: 16),
                        
                        // Email (Optional)
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (Optional)',
                            hintText: 'Enter email address',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone (Optional)
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone (Optional)',
                            hintText: 'Enter contact number',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        
                        // Address (Optional)
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address (Optional)',
                            hintText: 'Enter store address',
                            prefixIcon: Icon(Icons.home),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description (Optional)
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Enter store description',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        
                        if (_isLoading) ...[
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            final result = await AuthService.adminCreateRetailer(
                              storeName: _storeNameController.text.trim(),
                              ownerName: _ownerNameController.text.trim(),
                              username: _usernameController.text.trim(),
                              password: _passwordController.text,
                              locationId: _selectedLocationId!,
                              email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
                              phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
                              address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
                              description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
                            );
                            
                            if (!mounted) return;
                            
                            setState(() {
                              _isLoading = false;
                            });
                            
                            if (result['status'] == 'success') {
                              // Get the generated retailer code from response
                              final responseData = result['data'] ?? {};
                              final retailerCode = responseData['retailer_code'] ?? 
                                                 responseData['registration_code'] ?? 
                                                 responseData['code'] ?? 
                                                 'N/A';
                              
                              Navigator.pop(context);
                              
                              // Show success dialog with retailer code
                              showDialog(
                                context: context,
                                builder: (successContext) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Retailer Created Successfully'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Retailer account has been created successfully!',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Retailer Code:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SelectableText(
                                                  retailerCode.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2563EB),
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 20),
                                                onPressed: () async {
                                                  await Clipboard.setData(ClipboardData(text: retailerCode.toString()));
                                                  if (successContext.mounted) {
                                                    ScaffoldMessenger.of(successContext).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Retailer code copied: $retailerCode'),
                                                        backgroundColor: Colors.green,
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                },
                                                tooltip: 'Copy code',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Share this code with the retailer for registration',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(successContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            
                            // Refresh retailer list
                            widget.onSuccess();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Retailer "${_storeNameController.text}" created successfully'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Failed to create retailer'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Retailer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

