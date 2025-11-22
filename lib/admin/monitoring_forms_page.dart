import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/retailer_model.dart';
import '../models/monitoring_model.dart';
import '../services/auth_service.dart';
import '../services/retailer_api_service.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/monitoring/form_filter_widget.dart';
import '../widgets/monitoring/form_list_item.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

/// Unified Monitoring Page
/// 
/// Combines Monitoring Forms and Registered Stores in a tabbed interface
/// - Tab 1: Monitoring Forms (list of all monitoring forms)
/// - Tab 2: Registered Stores (list of all registered stores with their products)
class MonitoringFormsPage extends StatefulWidget {
  const MonitoringFormsPage({super.key});

  @override
  State<MonitoringFormsPage> createState() => _MonitoringFormsPageState();
}

class _MonitoringFormsPageState extends State<MonitoringFormsPage>
    with TickerProviderStateMixin {
  // Tab Controller
  late TabController _tabController;
  
  // Services
  final RetailerApiService _retailerApi = RetailerApiService();
  
  // Data for Stores Tab
  List<Retailer> _retailers = [];
  List<RetailerProduct> _allProducts = [];
  Map<int, List<RetailerProduct>> _storeProducts = {};
  
  // Data for Forms Tab
  final _searchController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedStore;
  bool _isFilterExpanded = false;
  List<Map<String, dynamic>> _monitoringForms = [];
  bool _isLoadingForms = false;
  String? _formsErrorMessage;
  int _formsCurrentPage = 1;
  bool _formsHasMoreData = true;
  final int _formsLimit = 20;
  
  // UI State
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  Set<int> _expandedStores = {};
  
  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Controllers
  final TextEditingController _storeSearchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadData();
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        // Load products and forms when switching to forms tab (same as retailer_store_management_page.dart)
        if (_allProducts.isEmpty) {
          _loadProducts();
        }
        _loadForms();
      } else if (_tabController.index == 1) {
        // Load stores when switching to stores tab
        if (_retailers.isEmpty) {
          _loadStoresData();
        }
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _storeSearchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load retailer store products first (needed for overall products display)
    await _loadProducts();
    // Then load forms
    _loadForms();
  }

  Future<void> _loadStoresData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Load stores and products in parallel
      await Future.wait([
        _loadStores(),
        _loadProducts(),
      ]);

      // Group products by store
      _groupProductsByStore();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      print('❌ Error loading monitoring data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: $e';
        });
      }
    }
  }

  Future<void> _loadStores() async {
    try {
      print('📊 Loading registered stores from database...');
      
      final result = await AuthService.getRetailers(
        page: 1,
        limit: 1000, // Get all stores
      );

      if (result['status'] == 'success') {
        final retailersData = result['data'];
        final retailersList = retailersData?['retailers'] ?? 
                             retailersData?['data'] ?? 
                             [];

        final retailers = retailersList.map<Retailer>((retailerData) {
          return Retailer.fromJson(retailerData);
        }).toList();

        if (mounted) {
          setState(() {
            _retailers = retailers;
          });
        }
        
        print('✅ Loaded ${retailers.length} stores from database');
      } else {
        throw Exception(result['message'] ?? 'Failed to load stores');
      }
    } catch (e) {
      print('❌ Error loading stores: $e');
      // If stores fail, try to synthesize from products
      if (_allProducts.isNotEmpty) {
        _synthesizeStoresFromProducts();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      print('📊 Loading products from all stores...');
      
      // Get all store prices (products from all stores)
      final products = await _retailerApi.getStorePrices();

      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
      
      print('✅ Loaded ${products.length} products from database');
    } catch (e) {
      print('❌ Error loading products: $e');
      if (mounted && _allProducts.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to load products: $e';
        });
      }
    }
  }

  void _synthesizeStoresFromProducts() {
    // Create store entries from products if stores API fails
    final Map<String, Retailer> storeMap = {};
    
    for (final product in _allProducts) {
      final key = '${product.retailerId}__${product.storeName}';
      if (!storeMap.containsKey(key)) {
        final compliantProducts = _allProducts
            .where((p) => p.retailerId == product.retailerId && p.isCompliant)
            .length;
        final totalProducts = _allProducts
            .where((p) => p.retailerId == product.retailerId)
            .length;
        final complianceRate = totalProducts > 0 
            ? (compliantProducts / totalProducts) * 100.0 
            : 0.0;
        
        storeMap[key] = Retailer(
          retailerId: product.retailerId,
          username: product.retailerUsername,
          storeName: product.storeName,
          productCount: totalProducts,
          complianceRate: complianceRate,
          violationCount: totalProducts - compliantProducts,
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _retailers = storeMap.values.toList();
      });
    }
  }

  void _groupProductsByStore() {
    final Map<int, List<RetailerProduct>> grouped = {};
    
    for (final product in _allProducts) {
      grouped.putIfAbsent(product.retailerId, () => []).add(product);
    }
    
    if (mounted) {
      setState(() {
        _storeProducts = grouped;
      });
    }
  }

  void _filterStores() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Filtering is done in the build method
        });
      }
    });
  }

  List<Retailer> get _filteredRetailers {
    if (_searchQuery.isEmpty) {
      return _retailers;
    }
    
    final query = _searchQuery.toLowerCase();
    return _retailers.where((retailer) {
      return retailer.storeName.toLowerCase().contains(query) ||
             retailer.username.toLowerCase().contains(query) ||
             (retailer.locationName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<RetailerProduct> _getStoreProducts(int retailerId) {
    final products = _storeProducts[retailerId] ?? [];
    
    if (_searchQuery.isEmpty) {
      return products;
    }
    
    final query = _searchQuery.toLowerCase();
    return products.where((product) {
      return product.productName.toLowerCase().contains(query) ||
             (product.brand ?? '').toLowerCase().contains(query) ||
             (product.manufacturer ?? '').toLowerCase().contains(query);
    }).toList();
  }

  // Get products for a specific monitoring form - filtered by store
  List<RetailerProduct> _getFormProducts(Map<String, dynamic> form) {
    final storeName = form['store_name'] ?? form['storeName'] ?? '';
    final retailerId = form['retailer_id'] ?? form['retailerId'];
    final formProducts = form['products'] as List? ?? [];
    
    if (formProducts.isEmpty) {
      return [];
    }
    
    // Filter products from _allProducts that match the store
    List<RetailerProduct> matchedProducts = [];
    
    for (final formProduct in formProducts) {
      final productId = formProduct['product_id'] ?? formProduct['id'] ?? formProduct['productId'];
      final productName = formProduct['product_name'] ?? formProduct['productName'] ?? '';
      
      // Find matching product in _allProducts
      final matchingProducts = _allProducts.where((product) {
        // Match by product ID first (most reliable)
        if (productId != null && product.productId == productId) {
          // Also verify it's from the correct store
          if (retailerId != null) {
            return product.retailerId == retailerId;
          } else if (storeName.isNotEmpty) {
            return product.storeName.toLowerCase() == storeName.toLowerCase();
          }
          return true;
        }
        
        // Fallback: match by product name and store
        if (productName.isNotEmpty) {
          final nameMatch = product.productName.toLowerCase() == productName.toLowerCase();
          if (nameMatch) {
            if (retailerId != null) {
              return product.retailerId == retailerId;
            } else if (storeName.isNotEmpty) {
              return product.storeName.toLowerCase() == storeName.toLowerCase();
            }
          }
        }
        
        return false;
      }).toList();
      
      if (matchingProducts.isNotEmpty) {
        matchedProducts.add(matchingProducts.first);
      }
    }
    
    return matchedProducts;
  }

  // Monitoring Forms Methods - Fetch from product_monitoring_api.php
  Future<void> _loadForms({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _formsCurrentPage = 1;
        _monitoringForms.clear();
        _formsHasMoreData = true;
        _isLoadingForms = true;
        _formsErrorMessage = null;
      });
    } else if (!_formsHasMoreData || _isLoadingForms) {
      return;
    }

    try {
      print('📊 Loading monitoring forms from product_monitoring_api.php...');
      
      final Map<String, String> queryParams = {
        'action': 'get_forms',
        'page': _formsCurrentPage.toString(),
        'limit': _formsLimit.toString(),
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
              _formsHasMoreData = newForms.length >= _formsLimit;
              _formsCurrentPage++;
              _isLoadingForms = false;
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
          _formsErrorMessage = e.toString();
          _isLoadingForms = false;
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
    _loadForms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormsTab(),
          _buildStoresTab(),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          // Listen to tab changes
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return _tabController.index == 0
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/create_form');
                      },
                      child: const Icon(Icons.add),
                      backgroundColor: const Color(0xFF3498db),
                      foregroundColor: Colors.white,
                    )
                  : const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Monitoring',
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
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(
            icon: Icon(Icons.assignment),
            text: 'Monitoring Forms',
          ),
          Tab(
            icon: Icon(Icons.store),
            text: 'Registered Stores',
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 24),
          onPressed: () {
            if (_tabController.index == 0) {
              _loadForms(refresh: true);
            } else {
              _loadStoresData();
            }
          },
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  // Forms Tab - Table View
  Widget _buildFormsTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
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
                  },
                  onSubmitted: (value) {
                    _loadForms(refresh: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
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
                  onApplyFilters: () => _loadForms(refresh: true),
                  onClearFilters: _clearFilters,
                )
              : null,
        ),

        // Forms List
        Expanded(
          child: _isLoadingForms && _monitoringForms.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _formsErrorMessage != null && _monitoringForms.isEmpty
                  ? _buildFormsErrorWidget()
                  : _monitoringForms.isEmpty
                      ? _buildFormsEmptyState()
                      : _buildFormsList(),
        ),
      ],
    );
  }

  // Get overall products from retailer stores (registered products)
  // Uses the same approach as retailer_store_management_page.dart
  List<Map<String, dynamic>> _getOverallProducts() {
    if (_allProducts.isEmpty) {
      return [];
    }
    
    final Map<int, Map<String, dynamic>> uniqueProducts = {};
    
    // Group products by productId to show unique products across all stores
    // Same approach as retailer_store_management_page.dart uses for _retailerProducts
    for (final product in _allProducts) {
      final productId = product.productId;
      
      if (!uniqueProducts.containsKey(productId)) {
        // First occurrence of this product
        uniqueProducts[productId] = {
          'product_id': productId,
          'product_name': product.productName,
          'brand': product.brand,
          'manufacturer': product.manufacturer,
          'product_price': product.currentRetailPrice,
          'latest_price': product.monitoredPrice ?? product.currentRetailPrice,
          'srp': product.srp,
          'mrp': product.effectiveMrp,
          'store_count': 1,
          'stores': <String>[product.storeName],
          'retailer_ids': <int>[product.retailerId],
        };
      } else {
        // Product already exists, aggregate data
        final existing = uniqueProducts[productId]!;
        final stores = existing['stores'] as List<String>;
        final retailerIds = existing['retailer_ids'] as List<int>;
        
        // Add store if not already present
        if (!stores.contains(product.storeName)) {
          stores.add(product.storeName);
          existing['store_count'] = stores.length;
        }
        
        // Add retailer ID if not already present
        if (!retailerIds.contains(product.retailerId)) {
          retailerIds.add(product.retailerId);
        }
        
        // Update latest price to show the highest monitored price
        final currentLatest = existing['latest_price'] as double;
        if (product.monitoredPrice != null) {
          // Use the higher monitored price if available
          if (product.monitoredPrice! > currentLatest) {
            existing['latest_price'] = product.monitoredPrice;
          }
        }
      }
    }
    
    return uniqueProducts.values.toList();
  }

  Widget _buildFormsList() {
    // Load retailer products if not already loaded
    if (_allProducts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProducts();
      });
    }
    
    final overallProducts = _getOverallProducts();
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadProducts();
        _loadForms(refresh: true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingForms &&
              _formsHasMoreData &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadForms(refresh: false);
          }
          return false;
        },
        child: Column(
          children: [
            // Overall Products Summary Card - Only show if products are loaded
            if (_allProducts.isNotEmpty && overallProducts.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text(
                          'Overall Products from All Stores',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            '${overallProducts.length} Unique Products',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Add Price Monitor Button
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddPriceMonitorDialog(null),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Add Latest Price Monitor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Products Table - Mobile Responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Mobile: Card View
                          return Column(
                            children: overallProducts.map((product) {
                              final stores = product['stores'] as List;
                              return _buildMobileProductCard(product, stores);
                            }).toList(),
                          );
                        } else {
                          // Desktop: Table View
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(const Color(0xFF2563EB)),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              dataRowMinHeight: 40,
                              columns: const [
                                DataColumn(label: Text('Product Name')),
                                DataColumn(label: Text('Latest Price'), numeric: true),
                                DataColumn(label: Text('Available In Stores'), numeric: true),
                                DataColumn(label: Text('Stores')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: overallProducts.map((product) {
                                final stores = product['stores'] as List;
                                return DataRow(
                                  cells: [
                                    DataCell(Text(
                                      product['product_name'] ?? 'N/A',
                                      style: const TextStyle(fontSize: 12),
                                    )),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
          Text(
                                            '₱${(product['product_price'] ?? product['latest_price'] ?? 0.0).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                                            onPressed: () => _showAddPriceMonitorDialog(product),
                                            tooltip: 'Edit Price',
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(
                                      '${product['store_count'] ?? 0}',
                                      style: const TextStyle(fontSize: 12),
                                    )),
                                    DataCell(Text(
                                      stores.length <= 3 
                                          ? stores.join(', ')
                                          : '${stores.sublist(0, 3).join(', ')} +${stores.length - 3} more',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    )),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, size: 20, color: Color(0xFF10B981)),
                                        onPressed: () => _showAddPriceMonitorDialog(product),
                                        tooltip: 'Add Price Monitor',
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            
            // Monitoring Forms List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _monitoringForms.length + (_formsHasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _monitoringForms.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isLoadingForms
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => _loadForms(refresh: false),
                                child: const Text('Load More'),
                              ),
                      ),
                    );
                  }

                  final form = _monitoringForms[index];
                  return _buildFormCard(form);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(Map<String, dynamic> form) {
    final formId = form['id'] ?? form['form_id'] ?? 'N/A';
    final storeName = form['store_name'] ?? form['storeName'] ?? 'N/A';
    final storeAddress = form['store_address'] ?? form['storeAddress'] ?? 'N/A';
    final monitoringDate = form['monitoring_date'] ?? form['monitoringDate'] ?? '';
    final monitoringMode = form['monitoring_mode'] ?? form['monitoringMode'] ?? 'N/A';
    final storeRep = form['store_rep'] ?? form['storeRep'] ?? 'N/A';
    final dtiMonitor = form['dti_monitor'] ?? form['dtiMonitor'] ?? 'N/A';
    // Get filtered products that are registered to this specific store
    final formProducts = _getFormProducts(form);
    final productsCount = formProducts.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Form ID: $formId',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.white, size: 20),
                      onPressed: () => _showFormDetails(form),
                      tooltip: 'View Details',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
                      onPressed: () => _showDeleteDialog(context, form),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.location_on, 'Address', storeAddress),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, 'Monitoring Date', 
                    monitoringDate.toString().split(' ')[0]),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Store Rep', storeRep),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.badge, 'DTI Monitor', dtiMonitor),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.settings, 'Mode', monitoringMode),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Products: ',
            style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '$productsCount',
                        style: const TextStyle(
              fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
              color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }

  // Mobile Product Card for Overall Products
  Widget _buildMobileProductCard(Map<String, dynamic> product, List stores) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product['product_name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Color(0xFF2563EB)),
                onPressed: () => _showAddPriceMonitorDialog(product),
                tooltip: 'Edit Price',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMobileInfoItem('Latest Price', 
                  '₱${(product['product_price'] ?? product['latest_price'] ?? 0.0).toStringAsFixed(2)}', 
                  Icons.attach_money, const Color(0xFF2563EB)),
              const SizedBox(width: 16),
              _buildMobileInfoItem('Stores', '${product['store_count'] ?? 0}', 
                  Icons.store, const Color(0xFF10B981)),
            ],
          ),
          if (stores.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Available in: ${stores.length <= 3 ? stores.join(', ') : '${stores.sublist(0, 3).join(', ')} +${stores.length - 3} more'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddPriceMonitorDialog(product),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Price Monitor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mobile Product Card for Store Products
  Widget _buildMobileStoreProductCard(RetailerProduct product) {
    final isViolation = !product.isCompliant;
    final priceDifference = product.priceDeviationPercentage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isViolation ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (product.brand != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Brand: ${product.brand}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (product.manufacturer != null) ...[
                      Text(
                        'Manufacturer: ${product.manufacturer}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isViolation
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.isCompliant ? 'Compliant' : 'Violation',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isViolation ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMobileInfoItem(
                  'Current Price',
                  '₱${product.currentRetailPrice.toStringAsFixed(2)}',
                  Icons.attach_money,
                  isViolation ? Colors.red : Colors.green,
                ),
              ),
              Expanded(
                child: _buildMobileInfoItem(
                  'MRP',
                  '₱${product.effectiveMrp.toStringAsFixed(2)}',
                  Icons.label,
                  const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileInfoItem(
                  'Latest Price',
                  '₱${(product.monitoredPrice ?? product.currentRetailPrice).toStringAsFixed(2)}',
                  Icons.update,
                  const Color(0xFF2563EB),
                ),
              ),
              Expanded(
                child: _buildMobileInfoItem(
                  'Deviation',
                  '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  isViolation ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddPriceMonitorDialog(product),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Update Latest Price'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Price Monitor Dialog
  void _showAddPriceMonitorDialog(dynamic product) {
    final productName = product is RetailerProduct 
        ? product.productName
        : (product['product_name'] ?? 'Unknown Product');
    // Get the current latest price or monitored price, not the current retail price
    final latestPrice = product is RetailerProduct
        ? (product.monitoredPrice ?? product.prevailingPrice ?? product.currentRetailPrice)
        : (product['latest_price'] ?? product['monitored_price'] ?? product['product_price'] ?? 0.0);
    final currentPrice = product is RetailerProduct
        ? product.currentRetailPrice
        : (product['product_price'] ?? product['current_price'] ?? 0.0);
    final productId = product is RetailerProduct
        ? product.productId
        : (product['product_id'] ?? product['id']);
    
    final priceController = TextEditingController(
      text: latestPrice.toStringAsFixed(2),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.price_change, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Latest Price Monitor',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 20, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Latest Price',
                  hintText: '0.00',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Retail Price: ₱${currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Previous Latest Price: ₱${latestPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This will save as latest monitored price only. Current retail price will not be changed.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2563EB),
                              ),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice == null || newPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _savePriceMonitor(productId, productName, newPrice, product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Price Monitor'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePriceMonitor(
    dynamic productId,
    String productName,
    double price,
    dynamic product,
  ) async {
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product ID is required to save price monitor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Save latest price using updateProductPrices - only updates monitored_price
      final result = await AuthService.updateProductPrices(
        productId: productId is int ? productId : int.tryParse(productId.toString()) ?? 0,
        monitoredPrice: price, // Only update monitored price, not current retail price
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (result['status'] == 'success' || result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Latest price monitor saved for $productName: ₱${price.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Update the product in local state immediately to show the new price
          if (product is RetailerProduct) {
            final productIdToUpdate = product.productId;
            // Update all products with matching productId
            setState(() {
              for (int i = 0; i < _allProducts.length; i++) {
                if (_allProducts[i].productId == productIdToUpdate) {
                  // Create updated product with new monitored price
                  _allProducts[i] = RetailerProduct(
                    retailPriceId: _allProducts[i].retailPriceId,
                    productId: _allProducts[i].productId,
                    retailerId: _allProducts[i].retailerId,
                    productName: _allProducts[i].productName,
                    brand: _allProducts[i].brand,
                    manufacturer: _allProducts[i].manufacturer,
                    srp: _allProducts[i].srp,
                    monitoredPrice: price, // Update monitored price
                    prevailingPrice: _allProducts[i].prevailingPrice,
                    currentRetailPrice: _allProducts[i].currentRetailPrice, // Keep current price unchanged
                    unit: _allProducts[i].unit,
                    profilePic: _allProducts[i].profilePic,
                    categoryName: _allProducts[i].categoryName,
                    categoryId: _allProducts[i].categoryId,
                    retailerUsername: _allProducts[i].retailerUsername,
                    storeName: _allProducts[i].storeName,
                    locationId: _allProducts[i].locationId,
                    dateRecorded: _allProducts[i].dateRecorded,
                    mainFolderName: _allProducts[i].mainFolderName,
                    subFolderName: _allProducts[i].subFolderName,
                    mainFolderId: _allProducts[i].mainFolderId,
                    subFolderId: _allProducts[i].subFolderId,
                    mrp: _allProducts[i].mrp,
                    effectiveMrp: _allProducts[i].effectiveMrp,
                    mrpStatus: _allProducts[i].mrpStatus,
                    violationLevel: _allProducts[i].violationLevel,
                  );
                }
              }
              // Regroup products by store
              _groupProductsByStore();
            });
          }
          
          // Refresh data from API to ensure consistency
          if (_tabController.index == 0) {
            _loadForms(refresh: true);
          } else {
            _loadStoresData();
          }
        } else {
          final errorMessage = result['message'] ?? 'Failed to save price monitor';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving price monitor: $e');
      if (mounted) {
        // Check if loading dialog is still open
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context); // Close loading dialog
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving price monitor: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildFormsErrorWidget() {
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
              _formsErrorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadForms(refresh: true),
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

  // Stores Tab
  Widget _buildStoresTab() {
    if (_isLoading && _retailers.isEmpty) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null && _retailers.isEmpty) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildStoreSearchBar(),
          Expanded(
            child: _filteredRetailers.isEmpty
                ? _buildStoresEmptyState()
                : _buildStoresList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading stores data...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
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
              onPressed: _loadStoresData,
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

  Widget _buildStatsCards() {
    final totalStores = _retailers.length;
    final totalProducts = _allProducts.length;
    final totalViolations = _allProducts.where((p) => !p.isCompliant).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Stores',
              totalStores.toString(),
              Icons.store,
              const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Products',
              totalProducts.toString(),
              Icons.inventory,
              const Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Violations',
              totalViolations.toString(),
              Icons.warning,
              const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _storeSearchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterStores();
        },
        decoration: InputDecoration(
          hintText: 'Search stores or products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _storeSearchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStoresEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No stores found'
                  : 'No stores registered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search query'
                  : 'Stores will appear here once they register',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormsEmptyState() {
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

  Widget _buildStoresList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Card View
    return RefreshIndicator(
            onRefresh: _loadStoresData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRetailers.length,
        itemBuilder: (context, index) {
          final retailer = _filteredRetailers[index];
          final isExpanded = _expandedStores.contains(retailer.retailerId);
                return _buildMobileStoreCard(retailer, isExpanded);
        },
      ),
    );
        } else {
          // Desktop: Table View
          return RefreshIndicator(
            onRefresh: _loadStoresData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredRetailers.length,
              itemBuilder: (context, index) {
                final retailer = _filteredRetailers[index];
                final products = _getStoreProducts(retailer.retailerId);
                final isExpanded = _expandedStores.contains(retailer.retailerId);
                
                return Column(
                  children: [
                    // Store Row as Table - Clickable
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedStores.remove(retailer.retailerId);
                          } else {
                            _expandedStores.add(retailer.retailerId);
                          }
                        });
                      },
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFF2563EB)),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          dataRowMinHeight: 50,
                          dataRowMaxHeight: 80,
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Store Name')),
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Products'), numeric: true),
                            DataColumn(label: Text('Compliance'), numeric: true),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        color: const Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          retailer.storeName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(
                                  retailer.username,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                )),
                                DataCell(Text(
                                  retailer.locationName ?? 'N/A',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                )),
                                DataCell(Text(
                                  '${products.length}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                )),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: retailer.complianceRate >= 80
                                          ? Colors.green.withOpacity(0.1)
                                          : retailer.complianceRate >= 60
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${retailer.complianceRate.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: retailer.complianceRate >= 80
                                            ? Colors.green
                                            : retailer.complianceRate >= 60
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: const Color(0xFF2563EB),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expanded Products Table
                    // Products Table - Animated Dropdown
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isExpanded && products.isNotEmpty
                          ? Column(
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFF06B6D4)),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            dataRowMinHeight: 50,
                            dataRowMaxHeight: 70,
                            columns: const [
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Brand')),
                              DataColumn(label: Text('Manufacturer')),
                              DataColumn(label: Text('Current Price'), numeric: true),
                              DataColumn(label: Text('MRP'), numeric: true),
                              DataColumn(label: Text('Latest Price'), numeric: true),
                              DataColumn(label: Text('Price Dev. %'), numeric: true),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: products.map((product) {
                              final isViolation = !product.isCompliant;
                              final priceDifference = product.priceDeviationPercentage;
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        product.productName,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                    product.brand ?? 'N/A',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  )),
                                  DataCell(Text(
                                    product.manufacturer ?? 'N/A',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  )),
                                  DataCell(Text(
                                    '₱${product.currentRetailPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isViolation ? Colors.red : Colors.green,
                                    ),
                                  )),
                                  DataCell(Text(
                                    '₱${product.effectiveMrp.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  )),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '₱${(product.monitoredPrice ?? product.currentRetailPrice).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                                          onPressed: () => _showAddPriceMonitorDialog(product),
                                          tooltip: 'Edit Latest Price',
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isViolation
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isViolation ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isViolation
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.isCompliant ? 'Compliant' : 'Violation',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isViolation ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, size: 20, color: Color(0xFF10B981)),
                                      onPressed: () => _showAddPriceMonitorDialog(product),
                                      tooltip: 'Add Price Monitor',
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : (isExpanded && products.isEmpty
                              ? Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  padding: const EdgeInsets.all(24),
                                  child: const Text(
                                    'No products found for this store',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox.shrink()),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        }
      },
    );
  }

  // Mobile Store Card
  Widget _buildMobileStoreCard(Retailer retailer, bool isExpanded) {
    final products = _getStoreProducts(retailer.retailerId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Store Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedStores.remove(retailer.retailerId);
                } else {
                  _expandedStores.add(retailer.retailerId);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          retailer.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          retailer.username,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (retailer.locationName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                retailer.locationName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildComplianceBadge(retailer.complianceRate),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${products.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          
          // Products Table (Expanded) - Mobile Responsive with Animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1),
                      products.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No products found for this store',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFF06B6D4)),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 60,
                        columnSpacing: 8,
                        columns: const [
                          DataColumn(label: Text('Product', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Brand', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Price', style: TextStyle(fontSize: 10)), numeric: true),
                          DataColumn(label: Text('MRP', style: TextStyle(fontSize: 10)), numeric: true),
                          DataColumn(label: Text('Latest', style: TextStyle(fontSize: 10)), numeric: true),
                          DataColumn(label: Text('Dev %', style: TextStyle(fontSize: 10)), numeric: true),
                          DataColumn(label: Text('Status', style: TextStyle(fontSize: 10))),
                          DataColumn(label: Text('Action', style: TextStyle(fontSize: 10))),
                        ],
                        rows: products.map((product) {
                          final isViolation = !product.isCompliant;
                          final priceDifference = product.priceDeviationPercentage;
                          
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    product.productName,
                                    style: const TextStyle(fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    product.brand ?? 'N/A',
                                    style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                '₱${product.currentRetailPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isViolation ? Colors.red : Colors.green,
                                ),
                              )),
                              DataCell(Text(
                                '₱${product.effectiveMrp.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                              )),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₱${(product.monitoredPrice ?? product.currentRetailPrice).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF2563EB)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 14, color: Color(0xFF2563EB)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showAddPriceMonitorDialog(product),
                                      tooltip: 'Edit',
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
          Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
                                    color: isViolation
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isViolation ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isViolation
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.isCompliant ? '✓' : '✗',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isViolation ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.add_circle, size: 18, color: Color(0xFF10B981)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showAddPriceMonitorDialog(product),
                                  tooltip: 'Add Price',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                                ),
                              ),
                            ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Retailer retailer, bool isExpanded) {
    final products = _getStoreProducts(retailer.retailerId);
    final compliantProducts = products.where((p) => p.isCompliant).length;
    final violationProducts = products.where((p) => !p.isCompliant).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Store Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedStores.remove(retailer.retailerId);
                } else {
                  _expandedStores.add(retailer.retailerId);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          retailer.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          retailer.username,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (retailer.locationName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                retailer.locationName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                  ),
                ),
              ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildComplianceBadge(retailer.complianceRate),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${products.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          
          // Products Table (Expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            products.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No products found for this store',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Mobile: Card View
                        return Padding(
                    padding: const EdgeInsets.all(16),
                          child: Column(
                            children: products.map((product) {
                              return _buildMobileStoreProductCard(product);
                            }).toList(),
                          ),
                        );
                      } else {
                        // Desktop: Table View
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(const Color(0xFF2563EB)),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              dataRowMinHeight: 50,
                              dataRowMaxHeight: 70,
                              columns: const [
                                DataColumn(label: Text('Product Name')),
                                DataColumn(label: Text('Brand')),
                                DataColumn(label: Text('Manufacturer')),
                                DataColumn(label: Text('Current Price'), numeric: true),
                                DataColumn(label: Text('MRP'), numeric: true),
                                DataColumn(label: Text('Latest Price'), numeric: true),
                                DataColumn(label: Text('Price Dev. %'), numeric: true),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: products.map((product) {
                                final isViolation = !product.isCompliant;
                                final priceDifference = product.priceDeviationPercentage;
                                
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          product.productName,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      product.brand ?? 'N/A',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    )),
                                    DataCell(Text(
                                      product.manufacturer ?? 'N/A',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    )),
                                    DataCell(Text(
                                      '₱${product.currentRetailPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isViolation ? Colors.red : Colors.green,
                                      ),
                                    )),
                                    DataCell(Text(
                                      '₱${product.effectiveMrp.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    )),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₱${(product.monitoredPrice ?? product.currentRetailPrice).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                                            onPressed: () => _showAddPriceMonitorDialog(product),
                                            tooltip: 'Edit Latest Price',
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isViolation
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isViolation ? Colors.red : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isViolation
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.isCompliant ? 'Compliant' : 'Violation',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isViolation ? Colors.red : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, size: 20, color: Color(0xFF10B981)),
                                        onPressed: () => _showAddPriceMonitorDialog(product),
                                        tooltip: 'Add Price Monitor',
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceBadge(double complianceRate) {
    final color = complianceRate >= 80
        ? Colors.green
        : complianceRate >= 60
            ? Colors.orange
            : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${complianceRate.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(RetailerProduct product) {
    final isViolation = !product.isCompliant;
    final priceDifference = product.priceDeviationPercentage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isViolation
              ? Colors.red.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isViolation
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isViolation ? Icons.warning : Icons.check_circle,
              color: isViolation ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Brand: ${product.brand}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${product.currentRetailPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isViolation ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MRP: ₱${product.effectiveMrp.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              if (priceDifference != 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isViolation
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isViolation ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showFormDetails(Map<String, dynamic> form) {
    final storeName = form['store_name'] ?? form['storeName'] ?? 'N/A';
    // Get filtered products that are registered to this specific store
    final formProducts = _getFormProducts(form);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Monitoring Form: $storeName'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', form['id']?.toString() ?? 'N/A'),
                _buildDetailRow('Store Name', storeName),
                _buildDetailRow('Store Address', form['store_address'] ?? form['storeAddress'] ?? 'N/A'),
                _buildDetailRow('Monitoring Date', form['monitoring_date']?.toString().split(' ')[0] ?? 'N/A'),
                _buildDetailRow('Monitoring Mode', form['monitoring_mode'] ?? form['monitoringMode'] ?? 'N/A'),
                _buildDetailRow('Store Rep', form['store_rep'] ?? form['storeRep'] ?? 'N/A'),
                _buildDetailRow('DTI Monitor', form['dti_monitor'] ?? form['dtiMonitor'] ?? 'N/A'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Products Registered to Store (${formProducts.length}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (formProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No products found registered to this store',
                        style: TextStyle(color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Mobile: Card View
                        return Column(
                          children: formProducts.map((product) {
                            return _buildMobileStoreProductCard(product);
                          }).toList(),
                        );
                      } else {
                        // Desktop: Table View
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFF2563EB)),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            dataRowMinHeight: 50,
                            dataRowMaxHeight: 70,
                            columns: const [
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Brand')),
                              DataColumn(label: Text('Manufacturer')),
                              DataColumn(label: Text('Current Price'), numeric: true),
                              DataColumn(label: Text('MRP'), numeric: true),
                              DataColumn(label: Text('Latest Price'), numeric: true),
                              DataColumn(label: Text('Price Dev. %'), numeric: true),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: formProducts.map((product) {
                              final isViolation = !product.isCompliant;
                              final priceDifference = product.priceDeviationPercentage;
                              final latestPrice = product.monitoredPrice ?? product.currentRetailPrice;
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        product.productName,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                    product.brand ?? 'N/A',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  )),
                                  DataCell(Text(
                                    product.manufacturer ?? 'N/A',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  )),
                                  DataCell(Text(
                                    '₱${product.currentRetailPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isViolation ? Colors.red : Colors.green,
                                    ),
                                  )),
                                  DataCell(Text(
                                    '₱${product.effectiveMrp.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  )),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '₱${latestPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _showAddPriceMonitorDialog(product);
                                          },
                                          tooltip: 'Edit Latest Price',
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isViolation
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isViolation ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isViolation
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.isCompliant ? 'Compliant' : 'Violation',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isViolation ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, size: 20, color: Color(0xFF10B981)),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showAddPriceMonitorDialog(product);
                                      },
                                      tooltip: 'Add Price Monitor',
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
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

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> form) {
    final storeName = form['store_name'] ?? form['storeName'] ?? 'N/A';
    final formId = form['id'] ?? form['form_id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Monitoring Form'),
        content: Text(
          'Are you sure you want to delete the monitoring form for "$storeName"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality for product_monitoring_api.php
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
