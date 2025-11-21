import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/retailer_model.dart';
import '../services/retailer_api_service.dart';
import '../services/retailer_realtime_service.dart';
import 'dart:async';

class RetailerStoreManagementPage extends StatefulWidget {
  const RetailerStoreManagementPage({super.key});

  @override
  State<RetailerStoreManagementPage> createState() => _RetailerStoreManagementPageState();
}

class _RetailerStoreManagementPageState extends State<RetailerStoreManagementPage>
    with TickerProviderStateMixin {
  
  // Real-time service
  final RetailerRealtimeService _realtimeService = RetailerRealtimeService();
  
  // Data state
  List<RetailerProduct> _retailerProducts = [];
  List<Retailer> _retailers = [];
  List<ViolationAlert> _violationAlerts = [];
  RetailerStats? _stats;
  Map<String, dynamic> _realtimeMetrics = {};
  
  // UI state
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _selectedTab = 'products';
  bool _isRealtimeConnected = false;
  DateTime? _lastDataUpdate;
  
  // Performance optimization
  Timer? _searchTimer;
  bool _isSearching = false;
  bool _hasSession = false;
  
  // Real-time subscriptions
  StreamSubscription<List<RetailerProduct>>? _productsSubscription;
  StreamSubscription<List<Retailer>>? _retailersSubscription;
  StreamSubscription<List<ViolationAlert>>? _violationsSubscription;
  StreamSubscription<RetailerStats>? _statsSubscription;
  StreamSubscription<Map<String, dynamic>>? _metricsSubscription;
  
  // Filters
  String _searchQuery = '';
  String _anomalyFilter = '';
  int? _selectedRetailerId;
  String _sortBy = 'retailer_username';
  String _sortOrder = 'ASC';
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final RetailerApiService _retailerApi = RetailerApiService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRealtimeService();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  /// Initialize real-time service and set up data streams
  Future<void> _initializeRealtimeService() async {
    try {
      print('🔄 Initializing real-time service...');
      
      // Initialize the real-time service
      await _realtimeService.initialize();
      
      // Set up stream subscriptions
      _productsSubscription = _realtimeService.productsStream.listen(
        (products) {
          if (mounted) {
            setState(() {
              _retailerProducts = products;
              _lastDataUpdate = DateTime.now();
            });
          }
        },
        onError: (error) {
          print('❌ Products stream error: $error');
        },
      );
      
      _retailersSubscription = _realtimeService.retailersStream.listen(
        (retailers) {
          if (mounted) {
            setState(() {
              _retailers = retailers;
            });
          }
        },
        onError: (error) {
          print('❌ Retailers stream error: $error');
        },
      );
      
      _violationsSubscription = _realtimeService.violationsStream.listen(
        (violations) {
          if (mounted) {
            setState(() {
              _violationAlerts = violations;
            });
          }
        },
        onError: (error) {
          print('❌ Violations stream error: $error');
        },
      );
      
      _statsSubscription = _realtimeService.statsStream.listen(
        (stats) {
          if (mounted) {
            setState(() {
              _stats = stats;
            });
          }
        },
        onError: (error) {
          print('❌ Stats stream error: $error');
        },
      );
      
      _metricsSubscription = _realtimeService.realtimeMetricsStream.listen(
        (metrics) {
          if (mounted) {
            setState(() {
              _realtimeMetrics = metrics;
            });
          }
        },
        onError: (error) {
          print('❌ Metrics stream error: $error');
        },
      );
      
      // Update connection status
      setState(() {
        _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
      });
      
      print('✅ Real-time service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize real-time service: $e');
      setState(() {
        _isRealtimeConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    
    // Clean up real-time subscriptions
    _productsSubscription?.cancel();
    _retailersSubscription?.cancel();
    _violationsSubscription?.cancel();
    _statsSubscription?.cancel();
    _metricsSubscription?.cancel();
    
    // Dispose real-time service
    _realtimeService.dispose();
    
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMoreData = true;
    });

    try {
      // Test API connection to store prices endpoint
      final ok = await _retailerApi.testConnection();
      if (!ok) {
        setState(() {
          _errorMessage = 'Cannot connect to retailer API. Please check your internet connection.';
        });
        return;
      }
      
      // Load public data first
      await _loadRetailerProducts();
      _loadViolationAlerts();

      // Load protected data only if we have a valid session cookie
      _hasSession = AuthService.getSessionCookie() != null && AuthService.getSessionCookie()!.isNotEmpty;
      if (_hasSession) {
        await _loadRetailers();
      _loadStats();
      }
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadRetailers() async {
    try {
      final result = await AuthService.getRetailers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: 1,
        limit: 20, // Reduced limit for better performance
      );
      
      if (result['status'] == 'success') {
        final retailersData = result['data'];
        final retailersList = retailersData?['retailers'] ?? retailersData?['data'] ?? [];
        
        // Convert to Retailer objects
        final retailers = retailersList.map<Retailer>((retailerData) {
          return Retailer.fromJson(retailerData);
        }).toList();
        
        if (mounted) {
          setState(() {
            _retailers = retailers;
          });
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to load retailers');
      }
    } catch (e) {
      print('Error loading retailers: $e');
      if (mounted && _retailers.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to load retailers: $e';
        });
      }
    }
  }

  Future<void> _loadRetailerProducts() async {
    try {
      // The endpoint returns the full list (no pagination). We'll fetch and filter client-side.
      final allPrices = await _retailerApi.getStorePrices();
      // Apply unified search filter locally - searches both products and retailers
      final searchTerm = _searchQuery.toLowerCase();
      final filtered = allPrices.where((p) {
        // Unified search: matches retailer/store name OR product name/brand
        final matchSearch = searchTerm.isEmpty || 
          p.retailerUsername.toLowerCase().contains(searchTerm) || 
          p.storeName.toLowerCase().contains(searchTerm) ||
          p.productName.toLowerCase().contains(searchTerm) || 
          (p.brand ?? '').toLowerCase().contains(searchTerm);
        
        // Apply anomaly filter
        bool matchAnomaly = true;
        if (_anomalyFilter == 'anomaly') {
          // Show all violations (both high prices and other violations)
          matchAnomaly = !p.isCompliant;
        } else if (_anomalyFilter == 'high_price') {
          // Show only high price violations
          matchAnomaly = p.currentRetailPrice > p.effectiveMrp;
        }
        
        return matchSearch && matchAnomaly;
        }).toList();
        
        if (mounted) {
          setState(() {
            _retailerProducts = filtered;
            _hasMoreData = false;
          });

          // Load violation alerts after products are loaded
          _loadViolationAlerts();

        // If stores list is empty (because protected retailers endpoint is disabled),
        // synthesize store entries from the fetched products for a better UX.
        if (_retailers.isEmpty && _retailerProducts.isNotEmpty) {
          final Map<String, List<RetailerProduct>> byStore = {};
          for (final p in _retailerProducts) {
            final key = '${p.retailerUsername}__${p.storeName}';
            byStore.putIfAbsent(key, () => <RetailerProduct>[]).add(p);
          }
          final synthesized = <Retailer>[];
          byStore.forEach((key, list) {
            final sample = list.first;
            final total = list.length;
            final compliant = list.where((p) => p.isCompliant).length;
            final violations = list.where((p) => !p.isCompliant).length;
            final complianceRate = total > 0 ? (compliant / total) * 100.0 : 0.0;
            synthesized.add(Retailer(
              retailerId: sample.retailerId,
              username: sample.retailerUsername,
              storeName: sample.storeName,
              locationId: sample.locationId,
              productCount: total,
              complianceRate: complianceRate,
              violationCount: violations,
            ));
          });
          if (mounted) {
            setState(() {
              _retailers = synthesized;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading retailer products: $e');
      if (mounted) {
        setState(() {
          if (_retailerProducts.isEmpty) {
            _errorMessage = 'Failed to load products: ${e.toString().replaceAll('Exception: ', '')}';
            // Load empty list to prevent further errors
            _retailerProducts = [];
          }
          // Don't show error if we already have some data
        });
      }
    }
  }

  Future<void> _loadViolationAlerts() async {
    try {
      // Synthesize alerts from violating products when backend alerts are not available
      final List<ViolationAlert> synthesizedAlerts = _retailerProducts
          .where((p) => !p.isCompliant)
          .map((p) {
            final severity = p.isCriticalViolation
                ? 'critical'
                : (p.isMinorViolation ? 'medium' : 'low');
            final deviationPct = p.priceDeviationPercentage;
            return ViolationAlert(
              alertId: p.retailPriceId,
              retailPriceId: p.retailPriceId,
              productId: p.productId,
              retailerId: p.retailerId,
              violationType: p.isAboveMrp ? 'above_mrp' : (p.isBelowMrp ? 'below_mrp' : 'other_violation'),
              currentPrice: p.currentRetailPrice,
              mrpThreshold: p.effectiveMrp,
              deviationPercentage: deviationPct,
              severity: severity,
              status: 'open',
              createdAt: p.dateRecorded,
              updatedAt: null,
              resolvedAt: null,
              productName: p.productName,
              retailerName: p.retailerUsername,
              storeName: p.storeName,
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _violationAlerts = synthesizedAlerts;
        });
      }
    } catch (e) {
      print('Error loading violation alerts: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await AuthService.getStats();
      
      if (result['status'] == 'success') {
        final statsData = result['data'];
        
        // Create a simple stats object from the data
        if (mounted) {
          setState(() {
            _stats = RetailerStats(
              totalRetailers: statsData?['total_retailers'] ?? 0,
              totalProducts: statsData?['total_products'] ?? 0,
              compliantProducts: statsData?['compliant_products'] ?? 0,
              violatingProducts: statsData?['violating_products'] ?? 0,
              overallComplianceRate: (statsData?['overall_compliance_rate'] ?? 0.0).toDouble(),
              averageDeviation: (statsData?['average_deviation'] ?? 0.0).toDouble(),
              criticalViolations: statsData?['critical_violations'] ?? 0,
              minorViolations: statsData?['minor_violations'] ?? 0,
              topViolators: List<Map<String, dynamic>>.from(statsData?['top_violators'] ?? []),
              topCompliant: List<Map<String, dynamic>>.from(statsData?['top_compliant'] ?? []),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadRetailerProducts();
  }

  Future<void> _refreshData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Force refresh real-time data
      await _realtimeService.refreshData();
      
      // Also load initial data as fallback
    await _loadInitialData();
      
      setState(() {
        _isLoading = false;
        _lastDataUpdate = DateTime.now();
      });
    } catch (e) {
      print('❌ Error refreshing data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to refresh data: $e';
      });
    }
  }

  void _applyFilters() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _currentPage = 1;
          _hasMoreData = true;
          _isSearching = true;
        });
        _loadRetailerProducts().then((_) {
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
          }
        });
        // Also reload retailers if we have a session
        if (_hasSession) {
          _loadRetailers();
        }
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _anomalyFilter = '';
      _selectedRetailerId = null;
      _currentPage = 1;
      _hasMoreData = true;
    });
    _loadRetailerProducts();
    if (_hasSession) {
      _loadRetailers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _isInitialLoading
            ? _buildLoadingWidget()
            : _errorMessage != null && _retailers.isEmpty
                ? _buildErrorWidget()
                : _buildMainContent(),
        floatingActionButton: _buildFloatingActionButton(),
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
            'Loading retailer data...',
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
              onPressed: _refreshData,
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

  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildModernAppBar(),
        if (!_hasSession)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing public product prices. Sign in to load registered retailers/stores and stats.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: _buildStatsCards(),
        ),
        SliverToBoxAdapter(
          child: _buildSearchAndFilters(),
        ),
        SliverToBoxAdapter(
          child: _buildTabBar(),
        ),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2563EB),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
      ),
      actions: [
        // Real-time status indicator
        _buildRealtimeStatusIndicator(),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.download, color: Colors.white),
          onPressed: _showExportDialog,
          tooltip: 'Export Data',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
          'Retailer Store Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_lastDataUpdate != null)
              Text(
                'Last updated: ${_formatLastUpdate(_lastDataUpdate!)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
          ),
        ),
      ),
    );
  }

  /// Build real-time status indicator
  Widget _buildRealtimeStatusIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRealtimeConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            _isRealtimeConnected ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  /// Format last update time
  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Regular stats cards
            if (_stats != null)
              Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Stores',
                _stats!.totalRetailers?.toString() ?? '0',
                Icons.store,
                const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Products',
                _stats!.totalProducts?.toString() ?? '0',
                Icons.inventory,
                const Color(0xFF06B6D4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Alerts',
                _violationAlerts.length.toString(),
                Icons.warning,
                const Color(0xFFEF4444),
              ),
            ),
                ],
              ),
            const SizedBox(height: 16),
            // Real-time metrics section
            _buildRealtimeMetricsSection(),
          ],
        ),
      ),
    );
  }

  /// Build real-time metrics section
  Widget _buildRealtimeMetricsSection() {
    if (_realtimeMetrics.isEmpty) return const SizedBox.shrink();
    
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Real-time Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isRealtimeConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isRealtimeConnected ? 'LIVE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Online Stores',
                  _realtimeMetrics['online_stores']?.toString() ?? '0',
                  Icons.store,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  'Price Updates',
                  _realtimeMetrics['price_updates']?.toString() ?? '0',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  'New Violations',
                  _realtimeMetrics['new_violations']?.toString() ?? '0',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual metric item
  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
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
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Unified search bar
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  onChanged: (value) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Search products and retailer stores...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _clearFilters();
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
                );
              },
            ),
            const SizedBox(height: 12),
            // Filter chips and actions
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _anomalyFilter.isEmpty,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _anomalyFilter = '');
                            _applyFilters();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Anomalies'),
                        selected: _anomalyFilter == 'anomaly',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _anomalyFilter = 'anomaly');
                            _applyFilters();
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('High Prices'),
                        selected: _anomalyFilter == 'high_price',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _anomalyFilter = 'high_price');
                            _applyFilters();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _applyFilters,
                  icon: _isSearching 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                  tooltip: 'Apply Filters',
                ),
                IconButton(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Filters',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('stores', 'Stores', Icons.store),
          ),
          Expanded(
            child: _buildTabButton('products', 'Products', Icons.inventory),
          ),
          Expanded(
            child: _buildTabButton('store_prices', 'Store Prices', Icons.storefront),
          ),
          Expanded(
            child: _buildTabButton('alerts', 'Alerts', Icons.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'stores':
        return _buildStoresList();
      case 'products':
        return _buildProductsList();
      case 'store_prices':
        return _buildStorePricesTab();
      case 'alerts':
        return _buildAlertsList();
      default:
        return _buildStoresList();
    }
  }

  Widget _buildStorePricesTab() {
    // Group products by retailer
    final Map<int, List<RetailerProduct>> groupedProducts = {};
    for (final product in _retailerProducts) {
      groupedProducts.putIfAbsent(product.retailerId, () => []).add(product);
    }

    if (groupedProducts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No store prices available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Store prices will appear here once retailers submit their prices.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = groupedProducts.entries.elementAt(index);
            final retailerId = entry.key;
            final products = entry.value;
            
            // Find the retailer info
            final retailer = _retailers.firstWhere(
              (r) => r.retailerId == retailerId,
              orElse: () => Retailer(
                retailerId: retailerId,
                username: 'Unknown',
                storeName: 'Unknown Store',
              ),
            );
            
            return _buildStorePricesCard(retailer, products);
          },
          childCount: groupedProducts.length,
        ),
      ),
    );
  }

  Widget _buildStorePricesCard(Retailer retailer, List<RetailerProduct> products) {
    final isOnline = _realtimeMetrics['online_stores'] != null
        ? (_realtimeMetrics['online_stores'] as int) > 0
        : false;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        retailer.storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        retailer.locationName ?? retailer.address ?? 'Location not specified',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Products list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: products.map((product) => _buildStorePriceItem(product)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorePriceItem(RetailerProduct product) {
    final priceDifference = product.priceDeviationPercentage;
    final isHighPrice = priceDifference > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighPrice ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MRP: ₱${product.effectiveMrp.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
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
                  color: isHighPrice ? Colors.red : Colors.green,
                ),
              ),
              if (priceDifference != 0) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isHighPrice ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isHighPrice ? Colors.red : Colors.green,
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

  Widget _buildStoresList() {
    // Filter retailers based on search query
    final searchTerm = _searchQuery.toLowerCase();
    final filteredRetailers = searchTerm.isEmpty
        ? _retailers
        : _retailers.where((retailer) {
            return retailer.storeName.toLowerCase().contains(searchTerm) ||
                   retailer.username.toLowerCase().contains(searchTerm) ||
                   (retailer.locationName ?? '').toLowerCase().contains(searchTerm);
          }).toList();
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < filteredRetailers.length) {
              return _buildRetailerCard(filteredRetailers[index]);
            } else if (_hasMoreData && !_isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMoreData();
              });
              return _buildLoadingCard();
            }
            return null;
          },
          childCount: filteredRetailers.length + (_hasMoreData ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_retailerProducts.isEmpty && !_isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: const Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Color(0xFF64748B),
              ),
              SizedBox(height: 16),
              Text(
                'No Products Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No retailer products available at the moment',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _retailerProducts.length) {
              return _buildProductCard(_retailerProducts[index]);
            } else if (_hasMoreData && !_isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMoreData();
              });
              return _buildLoadingCard();
            }
            return null;
          },
          childCount: _retailerProducts.length + (_hasMoreData ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _violationAlerts.length) {
              return _buildAlertCard(_violationAlerts[index]);
            }
            return null;
          },
          childCount: _violationAlerts.length,
        ),
      ),
    );
  }

  Widget _buildRetailerCard(Retailer retailer) {
    if (!mounted) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showStoreProducts(retailer),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
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
                        color: const Color(0xFF8B5CF6),
                        size: 32,
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            retailer.username,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          if (retailer.locationName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              retailer.locationName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildComplianceBadge(retailer.complianceRate),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '${retailer.productCount}',
                        'Products',
                        Icons.inventory,
                        const Color(0xFF06B6D4),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        '${retailer.violationCount}',
                        'Violations',
                        Icons.warning,
                        const Color(0xFFEF4444),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        '${retailer.complianceRate.toStringAsFixed(0)}%',
                        'Compliance',
                        Icons.check_circle,
                        _getComplianceColor(retailer.complianceRate),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(RetailerProduct product) {
    if (!mounted) return const SizedBox.shrink();
    final isAnomaly = !product.isCompliant;
    final priceDifference = product.priceDeviationPercentage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isAnomaly ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory,
                  color: isAnomaly ? Colors.red : Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      'Retailer: ${product.retailerUsername}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₱${product.currentRetailPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SRP: ₱${product.srp.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (priceDifference != 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priceDifference > 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${priceDifference > 0 ? '+' : ''}${priceDifference.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priceDifference > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isAnomaly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ANOMALY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(ViolationAlert alert) {
    if (!mounted) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSeverityColor(alert.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning,
                  color: _getSeverityColor(alert.severity),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.violationType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.violationType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSeverityChip(alert.severity),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(alert.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(alert.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _updateAlertStatus(alert),
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark as Resolved',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
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

  Widget _buildComplianceBadge(double complianceRate) {
    final color = _getComplianceColor(complianceRate);
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

  Widget _buildSeverityChip(String severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: const Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddRetailerDialog(),
      icon: const Icon(Icons.add),
      label: const Text('Add Retailer'),
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
    );
  }

  Color _getComplianceColor(double compliance) {
    if (compliance >= 80) return Colors.green;
    if (compliance >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showRetailerDetails(Retailer retailer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(retailer.storeName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${retailer.username}'),
            if (retailer.locationName != null) Text('Location: ${retailer.locationName}'),
            if (retailer.contactNumber != null) Text('Contact: ${retailer.contactNumber}'),
            if (retailer.email != null) Text('Email: ${retailer.email}'),
            Text('Products: ${retailer.productCount}'),
            Text('Compliance: ${retailer.complianceRate.toStringAsFixed(1)}%'),
            Text('Violations: ${retailer.violationCount}'),
          ],
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

  void _showStoreProducts(Retailer retailer) {
    final products = _retailerProducts.where((p) =>
      p.retailerUsername.toLowerCase() == retailer.username.toLowerCase() &&
      p.storeName.toLowerCase() == retailer.storeName.toLowerCase()
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.store, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              retailer.storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              retailer.username,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('${products.length} items',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF9CA3AF)),
                              SizedBox(height: 12),
                              Text('No products found for this store', style: TextStyle(color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _buildProductCard(products[index]),
                      ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateAlertStatus(ViolationAlert alert) async {
    try {
      // For now, just show a success message since we don't have the API endpoint
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert marked as resolved')),
      );
      
      _loadViolationAlerts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating alert: $e')),
      );
    }
  }

  void _showAddRetailerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Retailer'),
        content: const Text('Retailer registration feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as Excel'),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
