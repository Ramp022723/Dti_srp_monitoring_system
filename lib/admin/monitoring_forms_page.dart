import 'package:flutter/material.dart';
import '../models/retailer_model.dart';
import '../services/auth_service.dart';
import '../services/retailer_api_service.dart';
import 'dart:async';

/// Monitoring Forms Page
/// 
/// Displays all registered stores and the products they are selling
/// Data is fetched directly from the database via API endpoints
class MonitoringFormsPage extends StatefulWidget {
  const MonitoringFormsPage({super.key});

  @override
  State<MonitoringFormsPage> createState() => _MonitoringFormsPageState();
}

class _MonitoringFormsPageState extends State<MonitoringFormsPage>
    with TickerProviderStateMixin {
  // Services
  final RetailerApiService _retailerApi = RetailerApiService();
  
  // Data
  List<Retailer> _retailers = [];
  List<RetailerProduct> _allProducts = [];
  Map<int, List<RetailerProduct>> _storeProducts = {};
  
  // UI State
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  Set<int> _expandedStores = {};
  
  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
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
    _fadeController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null && _retailers.isEmpty
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          onPressed: _loadData,
          tooltip: 'Refresh Data',
        ),
      ],
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
            'Loading monitoring data...',
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
              onPressed: _loadData,
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

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildStatsCards(),
          _buildSearchBar(),
          Expanded(
            child: _filteredRetailers.isEmpty
                ? _buildEmptyState()
                : _buildStoresList(),
          ),
        ],
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
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
                    _searchController.clear();
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

  Widget _buildEmptyState() {
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

  Widget _buildStoresList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRetailers.length,
        itemBuilder: (context, index) {
          final retailer = _filteredRetailers[index];
          final isExpanded = _expandedStores.contains(retailer.retailerId);
          return _buildStoreCard(retailer, isExpanded);
        },
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
          
          // Store Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Products',
                    products.length.toString(),
                    Icons.inventory_2,
                    const Color(0xFF06B6D4),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Compliant',
                    compliantProducts.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Violations',
                    violationProducts.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // Products List (Expanded)
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
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductItem(products[index]);
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
}

