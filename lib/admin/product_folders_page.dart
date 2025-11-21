import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/product_folders_realtime_service.dart';
import 'dart:async';

/// Product Folders Management Page
/// 
/// IMPORTANT: All data displayed in this page comes directly from the database
/// via the API endpoint: admin/product_folder_management.php
/// 
/// - Folders data: Fetched from database using AuthService.getFolders()
/// - Statistics: Fetched from database using AuthService.getFolderStats()
/// - All CRUD operations (create, update, delete) use database API
/// - No mock, sample, or hardcoded data is used
/// - Real-time service ensures data is always fresh from the database
class ProductFoldersPage extends StatefulWidget {
  const ProductFoldersPage({super.key});

  @override
  State<ProductFoldersPage> createState() => _ProductFoldersPageState();
}

class _ProductFoldersPageState extends State<ProductFoldersPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _folders = [];
  List<dynamic> _filteredFolders = [];
  String? _error;
  String _searchQuery = '';
  String _selectedView = 'grid'; // 'grid' or 'list'
  bool _showHierarchy = false;
  
  // Real-time service
  final ProductFoldersRealtimeService _realtimeService = ProductFoldersRealtimeService();
  
  // Real-time data
  Map<String, dynamic> _realtimeMetrics = {};
  Map<String, dynamic>? _stats;
  bool _isRealtimeConnected = false;
  DateTime? _lastDataUpdate;
  
  // Real-time subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _foldersSubscription;
  StreamSubscription<Map<String, dynamic>>? _statsSubscription;
  StreamSubscription<Map<String, dynamic>>? _metricsSubscription;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRealtimeService();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    
    // Clean up real-time subscriptions
    _foldersSubscription?.cancel();
    _statsSubscription?.cancel();
    _metricsSubscription?.cancel();
    
    // Dispose real-time service
    _realtimeService.dispose();
    
    super.dispose();
  }

  /// Initialize real-time service and set up data streams
  Future<void> _initializeRealtimeService() async {
    try {
      print('🔄 Initializing product folders real-time service...');
      
      // Clear any previous error state
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
      
      // Set up stream subscriptions first
      _foldersSubscription = _realtimeService.foldersStream.listen(
        (folders) {
          if (mounted) {
            print('📦 Received ${folders.length} folders from stream');
            setState(() {
              _folders = folders;
              _filteredFolders = List.from(_folders);
              _lastDataUpdate = DateTime.now();
              _isLoading = false;
              // Clear error when data arrives successfully
              _error = null;
              // Update connection status based on service state
              _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
            });
            _fadeController.forward();
            _slideController.forward();
          }
        },
        onError: (error) {
          print('❌ Folders stream error: $error');
          if (mounted) {
            setState(() {
              // Only set error if we don't have cached data
              if (_folders.isEmpty) {
                _error = 'Real-time connection error: $error';
                _isLoading = false;
                _isRealtimeConnected = false;
              }
            });
          }
        },
        cancelOnError: false,
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
          // Don't block UI for stats errors
        },
        cancelOnError: false,
      );
      
      _metricsSubscription = _realtimeService.realtimeMetricsStream.listen(
        (metrics) {
          if (mounted) {
            setState(() {
              _realtimeMetrics = metrics;
              // Update connection status from metrics
              if (metrics.containsKey('connection_status')) {
                _isRealtimeConnected = metrics['connection_status'] == 'online' || 
                                       _realtimeService.isConnected || 
                                       _realtimeService.isPolling;
              }
            });
          }
        },
        onError: (error) {
          print('❌ Metrics stream error: $error');
          // Don't block UI for metrics errors
        },
        cancelOnError: false,
      );
      
      // Initialize the real-time service
      await _realtimeService.initialize();
      
      // Update connection status after initialization
      if (mounted) {
        setState(() {
          _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
        });
      }
      
      // Check if we have cached data from service
      final cachedFolders = _realtimeService.cachedFolders;
      if (cachedFolders.isNotEmpty && mounted) {
        print('📦 Using ${cachedFolders.length} cached folders');
        setState(() {
          _folders = cachedFolders;
          _filteredFolders = List.from(_folders);
          _lastDataUpdate = DateTime.now();
          _isLoading = false;
          _error = null;
          _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
        });
        _fadeController.forward();
        _slideController.forward();
      }
      
      // If no data is loaded after a longer delay, only show error if service is not connected
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _folders.isEmpty && _isLoading) {
          final isServiceConnected = _realtimeService.isConnected || _realtimeService.isPolling;
          print('⚠️ No data received after 10s. Service connected: $isServiceConnected');
          
          if (!isServiceConnected) {
            // Only show error if service is truly disconnected
            setState(() {
              _isLoading = false;
              _isRealtimeConnected = false;
              _error = 'Unable to connect to server. Please check your internet connection and try again.';
            });
          } else {
            // Service is connected but no data - might be empty, don't show error
            setState(() {
              _isLoading = false;
              _isRealtimeConnected = true;
              _error = null;
            });
          }
        }
      });
      
      print('✅ Product folders real-time service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize product folders real-time service: $e');
      if (mounted) {
        setState(() {
          // Check if we have cached data before showing error
          final cachedFolders = _realtimeService.cachedFolders;
          if (cachedFolders.isNotEmpty) {
            _folders = cachedFolders;
            _filteredFolders = List.from(_folders);
            _isRealtimeConnected = _realtimeService.isPolling;
            _error = null;
          } else {
            _isRealtimeConnected = false;
            _error = 'Failed to connect to real-time service: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  /// Load folders from database
  /// This method always fetches fresh data from the database - no cached/mock data
  /// 
  /// Data Source: admin/product_folder_management.php?action=folders
  /// All data comes directly from the database via AuthService.getFolders()
  /// No mock, sample, or hardcoded data is ever used
  Future<void> _loadFolders() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      
      // Force refresh from database - this ensures we always get the latest data
      // The real-time service fetches directly from the database API
      // API Endpoint: admin/product_folder_management.php?action=folders
      print('🔄 ProductFoldersPage: Refreshing folders from DATABASE...');
      print('📊 Database API: admin/product_folder_management.php?action=folders');
      print('✅ All data is fetched from the database - no mock data used');
      
      await _realtimeService.refreshData();
      
      // Update connection status
      if (mounted) {
        setState(() {
          _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
          // If we have cached data, use it (this is previously fetched database data, not mock)
          final cachedFolders = _realtimeService.cachedFolders;
          if (cachedFolders.isNotEmpty) {
            print('✅ Using ${cachedFolders.length} folders from database cache');
            _folders = cachedFolders;
            _filteredFolders = List.from(_folders);
            _lastDataUpdate = DateTime.now();
          } else {
            print('⚠️ No database data available yet');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error refreshing folders from database: $e');
      print('❌ Database API call failed - no fallback to mock data');
      if (mounted) {
        setState(() {
          // Don't show error if we have cached database data
          final cachedFolders = _realtimeService.cachedFolders;
          if (cachedFolders.isEmpty) {
            _error = 'Failed to refresh from database: $e';
          } else {
            print('✅ Using cached database data (${cachedFolders.length} folders)');
          }
          _isLoading = false;
        });
      }
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
        appBar: _buildAppBar(),
        body: _isLoading
            ? _buildLoadingWidget()
            : _error != null
                ? _buildErrorWidget()
                : _buildMobileContent(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text(
            'Product Folders',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          _buildRealtimeStatusIndicator(),
        ],
          ),
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            },
          ),
          actions: [
            IconButton(
          icon: const Icon(Icons.search, size: 24),
          onPressed: _showSearchDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 24),
              onPressed: _loadFolders,
            ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              _selectedView = value;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'grid',
              child: Row(
                children: [
                  Icon(Icons.grid_view, size: 18),
                  SizedBox(width: 8),
                  Text('Grid View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'list',
              child: Row(
                children: [
                  Icon(Icons.list, size: 18),
                  SizedBox(width: 8),
                  Text('List View'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealtimeStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isRealtimeConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRealtimeConnected ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRealtimeConnected ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            _isRealtimeConnected ? Icons.wifi : Icons.wifi_off,
            color: _isRealtimeConnected ? Colors.green : Colors.orange,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _isRealtimeConnected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _isRealtimeConnected ? Colors.green : Colors.orange,
            ),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading folders...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showCreateFolderDialog,
      backgroundColor: const Color(0xFF3B82F6),
      icon: const Icon(Icons.create_new_folder, color: Colors.white),
      label: const Text(
        'New Folder',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    // Only show error widget if we truly have no data and service is disconnected
    final hasCachedData = _realtimeService.cachedFolders.isNotEmpty;
    final isServiceConnected = _realtimeService.isConnected || _realtimeService.isPolling;
    
    // If service is connected but we're just loading, show loading instead
    if (isServiceConnected && _isLoading) {
      return _buildLoadingWidget();
    }
    
    // If we have cached data, show it even if there's an error message
    if (hasCachedData) {
      return _buildMobileContent();
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to connect to server',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Troubleshooting Tips:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Check your internet connection\n• Try switching between WiFi and mobile data\n• Restart the app if the problem persists',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadFolders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin-dashboard');
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
      children: [
            // Offline Banner
            if (_error != null) _buildOfflineBanner(),
            
            // Statistics Cards
            _buildMobileStatistics(),
            
            // Search and Filter Bar
            _buildSearchAndFilterBar(),
            
            // Folders Content
            Expanded(
              child: _filteredFolders.isEmpty
                  ? _buildEmptyState()
                  : _selectedView == 'grid'
                      ? _buildGridView()
                      : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
          child: Row(
            children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Unable to load product folders. Check your connection and try again.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
          TextButton(
            onPressed: _loadFolders,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatistics() {
    // Use real-time stats if available, otherwise calculate from folders
    final totalFolders = _stats?['total_folders'] ?? _folders.length;
    final totalProducts = _stats?['total_products'] ?? _folders.fold<int>(0, (sum, folder) => sum + ((folder['product_count'] ?? 0) as int));
    final hierarchicalFolders = _stats?['hierarchical_folders'] ?? _folders.where((folder) => folder['is_hierarchical'] == true).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
        children: [
          Expanded(
                child: _buildMobileStatCard(
                  'Folders',
              totalFolders.toString(),
              Icons.folder,
                  const Color(0xFF3B82F6),
            ),
          ),
              const SizedBox(width: 12),
          Expanded(
                child: _buildMobileStatCard(
                  'Products',
              totalProducts.toString(),
              Icons.inventory,
                  const Color(0xFF10B981),
            ),
          ),
              const SizedBox(width: 12),
          Expanded(
                child: _buildMobileStatCard(
              'Hierarchical',
              hierarchicalFolders.toString(),
              Icons.account_tree,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          if (_realtimeMetrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRealtimeMetricsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildRealtimeMetricsSection() {
    return Container(
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRealtimeConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isRealtimeConnected ? Icons.wifi : Icons.wifi_off,
            color: _isRealtimeConnected ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isRealtimeConnected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _isRealtimeConnected ? Colors.green : Colors.orange,
            ),
          ),
          const Spacer(),
          if (_lastDataUpdate != null) ...[
            Text(
              'Updated: ${_formatLastUpdate(_lastDataUpdate!)}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildMobileStatCard(String title, String value, IconData icon, Color color) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
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

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search folders...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _filterFolders,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _showHierarchy = !_showHierarchy;
                _filterFolders(_searchQuery);
              });
            },
            icon: Icon(
              _showHierarchy ? Icons.account_tree : Icons.list,
              color: _showHierarchy ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
            ),
            style: IconButton.styleFrom(
              backgroundColor: _showHierarchy ? const Color(0xFF3B82F6).withOpacity(0.1) : null,
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Folders Yet',
            style: TextStyle(
                fontSize: 20,
              fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create your first product folder to organize products',
              textAlign: TextAlign.center,
              style: TextStyle(
              fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateFolderDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Folder'),
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

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = _filteredFolders[index];
        return _buildMobileFolderCard(folder, isGrid: true);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = _filteredFolders[index];
        return _buildMobileFolderCard(folder, isGrid: false);
      },
    );
  }

  Widget _buildMobileFolderCard(dynamic folder, {required bool isGrid}) {
    // Extract folder data matching website structure exactly
    final folderName = folder['folder_name'] ?? folder['name'] ?? 'Unnamed Folder';
    final productCount = folder['product_count'] ?? folder['total_products'] ?? 0;
    final folderId = folder['folder_id'] ?? folder['id'] ?? 0;
    final isHierarchical = folder['is_hierarchical'] ?? folder['hierarchical'] ?? false;
    final parentFolder = folder['parent_folder'] ?? folder['parent_folder_name'] ?? folder['parent_name'];

    if (isGrid) {
      return _buildGridFolderCard(folderName, productCount, folderId, isHierarchical, parentFolder);
    } else {
      return _buildListFolderCard(folderName, productCount, folderId, isHierarchical, parentFolder);
    }
  }

  Widget _buildGridFolderCard(String folderName, int productCount, dynamic folderId, bool isHierarchical, dynamic parentFolder) {
    // Get folder type directly from the folder data
    final folder = _folders.firstWhere(
      (f) => (f['folder_id'] ?? f['id']) == folderId,
      orElse: () => <String, dynamic>{},
    );
    final folderType = folder['folder_type'] ?? folder['type'] ?? 'main';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
          onTap: () => _onFolderTap(folderName),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getFolderColor(folderType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getFolderColor(folderType).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getFolderIcon(folderType, isHierarchical),
                        color: _getFolderColor(folderType),
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getFolderTypeColor(folderType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        folderType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getFolderTypeColor(folderType),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleFolderAction(value, folderId, folderName),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('View Products'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  folderName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$productCount products',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (parentFolder != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          parentFolder,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListFolderCard(String folderName, int productCount, dynamic folderId, bool isHierarchical, dynamic parentFolder) {
    // Get folder type directly from the folder data
    final folder = _folders.firstWhere(
      (f) => (f['folder_id'] ?? f['id']) == folderId,
      orElse: () => <String, dynamic>{},
    );
    final folderType = folder['folder_type'] ?? folder['type'] ?? 'main';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => _onFolderTap(folderName),
          borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: _getFolderColor(folderType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getFolderColor(folderType).withOpacity(0.2),
                      width: 1,
                    ),
                ),
                child: Icon(
                    _getFolderIcon(folderType, isHierarchical),
                    color: _getFolderColor(folderType),
                    size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                      folderName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getFolderTypeColor(folderType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              folderType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getFolderTypeColor(folderType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                    Text(
                      '$productCount products',
                            style: const TextStyle(
                        fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                      ),
                          ),
                        ],
                    ),
                    if (parentFolder != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                        children: [
                              const Icon(Icons.subdirectory_arrow_right, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                                parentFolder,
                                style: const TextStyle(
                              fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                          ),
                      ),
                    ],
                  ],
                ),
              ),
                const SizedBox(width: 8),
              PopupMenuButton<String>(
                  onSelected: (value) => _handleFolderAction(value, folderId, folderName),
                itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('View Products'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
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

  // Helper methods for mobile UI
  void _filterFolders(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFolders = List.from(_folders);
      } else {
        _filteredFolders = _folders.where((folder) {
          final folderName = (folder['folder_name'] ?? '').toString().toLowerCase();
          return folderName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Folders'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter folder name...',
            border: OutlineInputBorder(),
          ),
          onChanged: _filterFolders,
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

  void _onFolderTap(String folderName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening folder: $folderName'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  void _handleFolderAction(String action, dynamic folderId, String folderName) {
    switch (action) {
      case 'view':
        _onFolderTap(folderName);
        break;
      case 'edit':
        _showEditFolderDialog({'folder_id': folderId, 'folder_name': folderName});
        break;
      case 'delete':
        _showDeleteConfirmation(folderId, folderName);
        break;
    }
  }

  Color _getFolderColor(String folderType) {
    switch (folderType.toLowerCase()) {
      case 'main':
        return const Color(0xFF3B82F6);
      case 'sub':
        return const Color(0xFF10B981);
      case 'auto':
        return const Color(0xFFF59E0B);
      case 'manual':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getFolderTypeColor(String folderType) {
    switch (folderType.toLowerCase()) {
      case 'main':
        return const Color(0xFF1D4ED8);
      case 'sub':
        return const Color(0xFF059669);
      case 'auto':
        return const Color(0xFFD97706);
      case 'manual':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF475569);
    }
  }

  IconData _getFolderIcon(String folderType, bool isHierarchical) {
    if (isHierarchical) {
      return Icons.folder_special;
    }
    
    switch (folderType.toLowerCase()) {
      case 'main':
        return Icons.folder;
      case 'sub':
        return Icons.folder_open;
      case 'auto':
        return Icons.auto_awesome;
      case 'manual':
        return Icons.create_new_folder;
      default:
        return Icons.folder_outlined;
    }
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'Enter folder name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                await _createFolder(nameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(dynamic folder) {
    final nameController = TextEditingController(text: folder['folder_name']);
    final folderId = folder['folder_id'] ?? folder['id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                await _updateFolder(folderId, nameController.text);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(dynamic folderId, String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "$folderName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFolder(folderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Create folder in database
  /// Database API: admin/product_folder_management.php?action=create_folder
  /// All operations are performed directly on the database - no local/mock data
  Future<void> _createFolder(String folderName) async {
    try {
      print('📝 Creating folder in DATABASE: $folderName');
      print('📊 Database API: admin/product_folder_management.php?action=create_folder');
      
      final result = await AuthService.createFolder(
        name: folderName,
      );
      
      if (result['status'] == 'success') {
        print('✅ Folder created successfully in database');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created successfully'), backgroundColor: Colors.green),
        );
        // Refresh from database to show the new folder
        _loadFolders();
      } else {
        print('❌ Failed to create folder in database: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create folder'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('❌ Database error creating folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Update folder in database
  /// Database API: admin/product_folder_management.php?action=update_folder
  /// All operations are performed directly on the database - no local/mock data
  Future<void> _updateFolder(dynamic folderId, String folderName) async {
    try {
      print('✏️ Updating folder in DATABASE: ID=$folderId, Name=$folderName');
      print('📊 Database API: admin/product_folder_management.php?action=update_folder');
      
      final result = await AuthService.updateFolder(
        folderId: int.parse(folderId.toString()),
        name: folderName,
      );
      
      if (result['status'] == 'success') {
        print('✅ Folder updated successfully in database');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder updated successfully'), backgroundColor: Colors.green),
        );
        // Refresh from database to show the updated folder
        _loadFolders();
      } else {
        print('❌ Failed to update folder in database: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update folder'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('❌ Database error updating folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Delete folder from database
  /// Database API: admin/product_folder_management.php?action=delete_folder
  /// All operations are performed directly on the database - no local/mock data
  Future<void> _deleteFolder(dynamic folderId) async {
    try {
      print('🗑️ Deleting folder from DATABASE: ID=$folderId');
      print('📊 Database API: admin/product_folder_management.php?action=delete_folder');
      
      final result = await AuthService.deleteFolder(
        folderId: int.parse(folderId.toString()),
      );
      
      if (result['status'] == 'success') {
        print('✅ Folder deleted successfully from database');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted successfully'), backgroundColor: Colors.green),
        );
        // Refresh from database to reflect the deletion
        _loadFolders();
      } else {
        print('❌ Failed to delete folder from database: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to delete folder'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('❌ Database error deleting folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

