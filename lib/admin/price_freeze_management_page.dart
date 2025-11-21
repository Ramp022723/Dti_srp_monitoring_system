import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/price_freeze_realtime_service.dart';
import '../models/price_freeze_model.dart';
import 'dart:async';

class PriceFreezeManagementPage extends StatefulWidget {
  const PriceFreezeManagementPage({super.key});

  @override
  State<PriceFreezeManagementPage> createState() => _PriceFreezeManagementPageState();
}

class _PriceFreezeManagementPageState extends State<PriceFreezeManagementPage> 
    with TickerProviderStateMixin {
  
  // Real-time service
  final PriceFreezeRealtimeService _realtimeService = PriceFreezeRealtimeService();
  
  bool _isLoading = false;
  String? _error;
  List<dynamic> _alerts = [];
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _locations = [];
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _realtimeMetrics = {};
  
  // Filter states
  String _selectedCategory = 'all';
  String _selectedLocation = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // UI states
  bool _isRefreshing = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRealtimeConnected = false;
  DateTime? _lastDataUpdate;
  
  // Real-time subscriptions
  StreamSubscription<List<PriceFreezeAlert>>? _alertsSubscription;
  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Location>>? _locationsSubscription;
  StreamSubscription<PriceFreezeStats>? _statsSubscription;
  StreamSubscription<Map<String, dynamic>>? _metricsSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRealtimeService();
    _loadData();
    _scrollController.addListener(_onScroll);
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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Initialize real-time service and set up data streams
  Future<void> _initializeRealtimeService() async {
    try {
      print('🔄 Initializing price freeze real-time service...');
      
      // Initialize the real-time service
      await _realtimeService.initialize();
      
      // Set up stream subscriptions
      _alertsSubscription = _realtimeService.alertsStream.listen(
        (alerts) {
          if (mounted) {
            setState(() {
              _alerts = alerts.map((alert) => alert.toJson()).toList();
              _lastDataUpdate = DateTime.now();
            });
          }
        },
        onError: (error) {
          print('❌ Alerts stream error: $error');
        },
      );
      
      _productsSubscription = _realtimeService.productsStream.listen(
        (products) {
          if (mounted) {
            setState(() {
              _products = products.map((product) => product.toJson()).toList();
            });
          }
        },
        onError: (error) {
          print('❌ Products stream error: $error');
        },
      );
      
      _categoriesSubscription = _realtimeService.categoriesStream.listen(
        (categories) {
          if (mounted) {
            setState(() {
              _categories = categories.map((category) => category.toJson()).toList();
            });
          }
        },
        onError: (error) {
          print('❌ Categories stream error: $error');
        },
      );
      
      _locationsSubscription = _realtimeService.locationsStream.listen(
        (locations) {
          if (mounted) {
            setState(() {
              _locations = locations.map((location) => location.toJson()).toList();
            });
          }
        },
        onError: (error) {
          print('❌ Locations stream error: $error');
        },
      );
      
      _statsSubscription = _realtimeService.statsStream.listen(
        (stats) {
          if (mounted) {
            setState(() {
              _statistics = {
                'total_alerts': stats.totalAlerts,
                'active_alerts': stats.activeAlerts,
                'expired_alerts': stats.expiredAlerts,
                'scheduled_alerts': stats.scheduledAlerts,
              };
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
      
      print('✅ Price freeze real-time service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize price freeze real-time service: $e');
      setState(() {
        _isRealtimeConnected = false;
      });
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    
    // Clean up real-time subscriptions
    _alertsSubscription?.cancel();
    _productsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _locationsSubscription?.cancel();
    _statsSubscription?.cancel();
    _metricsSubscription?.cancel();
    
    // Dispose real-time service
    _realtimeService.dispose();
    
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMoreData = true;
    });

    try {
      // Load all data in parallel using AuthService
      final results = await Future.wait([
        AuthService.getPriceFreezeAlerts(
          status: _selectedStatus != 'all' ? _selectedStatus : null,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          page: _currentPage,
          limit: 20,
        ),
        AuthService.getPriceFreezeProducts(),
        AuthService.getPriceFreezeCategories(),
        AuthService.getPriceFreezeLocations(),
        AuthService.getPriceFreezeStatistics(),
      ]);

      // Parse AuthService responses
      final alertsResult = results[0];
      final productsResult = results[1];
      final categoriesResult = results[2];
      final locationsResult = results[3];
      final statsResult = results[4];

      setState(() {
        // Parse alerts
        if (alertsResult['status'] == 'success') {
          final alertsData = alertsResult['data'];
          _alerts = alertsData?['data']?['alerts'] ?? alertsData?['alerts'] ?? [];
        } else {
          _alerts = [];
        }

        // Parse products
        if (productsResult['status'] == 'success') {
          final productsData = productsResult['data'];
          _products = productsData?['data']?['products'] ?? productsData?['products'] ?? [];
        } else {
          _products = [];
        }

        // Parse categories
        if (categoriesResult['status'] == 'success') {
          final categoriesData = categoriesResult['data'];
          _categories = categoriesData?['data']?['categories'] ?? categoriesData?['categories'] ?? [];
        } else {
          _categories = [];
        }

        // Parse locations
        if (locationsResult['status'] == 'success') {
          final locationsData = locationsResult['data'];
          _locations = locationsData?['data']?['locations'] ?? locationsData?['locations'] ?? [];
        } else {
          _locations = [];
        }

        // Parse statistics
        if (statsResult['status'] == 'success') {
          final statsData = statsResult['data'];
          _statistics = {
            'total_alerts': statsData?['total_alerts'] ?? 0,
            'active_alerts': statsData?['active_alerts'] ?? 0,
            'resolved_alerts': statsData?['expired_alerts'] ?? 0,
          };
        } else {
          _statistics = {
            'total_alerts': 0,
            'active_alerts': 0,
            'resolved_alerts': 0,
          };
        }

        _isLoading = false;
        _hasMoreData = _alerts.length >= 20;
      });
      
      print('Loaded ${_alerts.length} alerts');
      print('Loaded ${_products.length} products');
      print('Loaded ${_categories.length} categories');
      print('Loaded ${_locations.length} locations');
      
      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
      print('Error loading price freeze data: $e');
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.getPriceFreezeAlerts(
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: _currentPage + 1,
        limit: 20,
      );

      if (result['status'] == 'success') {
        final alertsData = result['data'];
        final newAlerts = alertsData?['data']?['alerts'] ?? alertsData?['alerts'] ?? [];
        
        setState(() {
          _alerts.addAll(newAlerts);
          _currentPage++;
          _hasMoreData = newAlerts.length >= 20;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMoreData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasMoreData = false;
        _isLoading = false;
      });
      print('Error loading more data: $e');
    }
  }
  
  Future<void> _refreshData() async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      
      // Force refresh real-time data
      await _realtimeService.refreshData();
      
      // Also load initial data as fallback
      await _loadData();
      
      setState(() {
        _isRefreshing = false;
        _lastDataUpdate = DateTime.now();
      });
    } catch (e) {
      print('❌ Error refreshing data: $e');
      setState(() {
        _isRefreshing = false;
        _error = 'Failed to refresh data: $e';
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildModernAppBar(),
        body: _isLoading && _alerts.isEmpty
            ? _buildLoadingWidget()
            : _error != null
                ? _buildErrorWidget()
                : _buildMainContent(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }
  
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.ac_unit, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Freeze',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Management',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (_lastDataUpdate != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${_formatLastUpdate(_lastDataUpdate!)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFF475569)),
        ),
        onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
      ),
      actions: [
        // Real-time status indicator
        _buildRealtimeStatusIndicator(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isRefreshing ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF475569)),
          ),
          onPressed: _isRefreshing ? null : _refreshData,
        ),
        const SizedBox(width: 8),
      ],
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
            color: const Color(0xFF475569),
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
  
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading price freeze alerts...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showCreateAlertDialog,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Create Alert'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF3B82F6),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Statistics Cards
              SliverToBoxAdapter(
                child: _buildStatisticsCards(),
              ),
              
              // Filters
              SliverToBoxAdapter(
                child: _buildFilters(),
              ),
              
              // Alerts List Header
              SliverToBoxAdapter(
                child: _buildAlertsHeader(),
              ),
              
              // Alerts List
              _buildAlertsList(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlertsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Price Freeze Alerts (${_alerts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (_alerts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_alerts.where((alert) => alert['status'] == 'active').length} Active',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final statsData = [
      {
        'title': 'Total Alerts',
        'value': _statistics['total_alerts']?.toString() ?? '0',
        'icon': Icons.notifications_outlined,
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEFF6FF),
        'trend': _realtimeMetrics['total_alerts_trend'] ?? 0,
      },
      {
        'title': 'Active Alerts',
        'value': _statistics['active_alerts']?.toString() ?? '0',
        'icon': Icons.warning_outlined,
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFEF3C7),
        'trend': _realtimeMetrics['active_alerts_trend'] ?? 0,
      },
      {
        'title': 'Resolved',
        'value': _statistics['expired_alerts']?.toString() ?? '0',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFD1FAE5),
        'trend': _realtimeMetrics['expired_alerts_trend'] ?? 0,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: statsData.map((stat) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildModernStatCard(
              stat['title'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              stat['color'] as Color,
              stat['bgColor'] as Color,
              stat['trend'] as int,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color, Color bgColor, int trend) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != 0) _buildTrendIndicator(trend),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build trend indicator widget
  Widget _buildTrendIndicator(int trend) {
    if (trend == 0) return const SizedBox.shrink();
    
    final isPositive = trend > 0;
    final trendColor = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, color: trendColor, size: 12),
          const SizedBox(width: 2),
          Text(
            '${trend.abs()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search alerts...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Status', _selectedStatus == 'all', () {
                  setState(() {
                    _selectedStatus = 'all';
                  });
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Active', _selectedStatus == 'active', () {
                  setState(() {
                    _selectedStatus = 'active';
                  });
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', _selectedStatus == 'resolved', () {
                  setState(() {
                    _selectedStatus = 'resolved';
                  });
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', _selectedStatus == 'expired', () {
                  setState(() {
                    _selectedStatus = 'expired';
                  });
                  _applyFilters();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    final filteredAlerts = _getFilteredAlerts();
    
    if (filteredAlerts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No alerts found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No price freeze alerts match your current filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateAlertDialog,
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Create First Alert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < filteredAlerts.length) {
            final alert = filteredAlerts[index];
            return _buildModernAlertCard(alert, index);
          } else if (_hasMoreData && _isLoading) {
            return _buildLoadingIndicator();
          }
          return null;
        },
        childCount: filteredAlerts.length + (_hasMoreData && _isLoading ? 1 : 0),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  Widget _buildModernAlertCard(dynamic alert, int index) {
    final status = alert['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () => _showAlertDetails(alert),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'] ?? 'Price Freeze Alert',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['message'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Status: ${alert['status'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAlertAction(value, alert),
                      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18),
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
                                Icon(Icons.check_circle_outline, size: 18),
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
                                Icon(Icons.refresh, size: 18),
                                SizedBox(width: 8),
                                Text('Reactivate'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Price Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPriceInfo(
                          'Start Date',
                          _formatDate(alert['freeze_start_date']),
                          const Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: _buildPriceInfo(
                          'End Date',
                          alert['freeze_end_date'] != null 
                            ? _formatDate(alert['freeze_end_date']) 
                            : 'Indefinite',
                          statusColor,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: _buildPriceInfo(
                          'Affected',
                          _getAffectedItemsText(alert),
                          const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert['created_by_name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(alert['created_at']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPriceInfo(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFFFEF3C7);
      case 'resolved':
        return const Color(0xFFD1FAE5);
      case 'expired':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
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

  String _getAffectedItemsText(dynamic alert) {
    final products = alert['affected_products'] ?? 'all';
    final categories = alert['affected_categories'] ?? 'all';
    final locations = alert['affected_locations'] ?? 'all';
    
    if (products == 'all' && categories == 'all' && locations == 'all') {
      return 'All Items';
    }
    
    List<String> items = [];
    if (products != 'all') items.add('Products');
    if (categories != 'all') items.add('Categories');
    if (locations != 'all') items.add('Locations');
    
    return items.join(', ');
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
    // Reload data with new filters
    _loadData();
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
        alertId: int.parse(alert['alert_id'].toString()),
        status: 'expired',
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
        alertId: int.parse(alert['alert_id'].toString()),
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
        content: Text('Are you sure you want to delete the alert "${alert['title']}"?'),
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
          alertId: int.parse(alert['alert_id'].toString()),
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
          title: 'Price Freeze Alert',
          message: _notesController.text.isEmpty ? 'Price freeze alert created' : _notesController.text,
          freezeStartDate: DateTime.now().toIso8601String().split('T')[0],
          freezeEndDate: null, // Indefinite
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
      final result = await AuthService.updatePriceFreezeAlertStatus(
        alertId: int.parse(widget.alert['alert_id'].toString()),
        status: widget.alert['status'], // Keep current status
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
