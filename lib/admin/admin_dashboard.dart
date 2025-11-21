import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isMenuOpen = false;
  String activeTab = 'dashboard';
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _error;
  bool _isDarkMode = false;

  final List<Map<String, dynamic>> menuItems = [
    {'id': 'dashboard', 'title': 'Dashboard', 'icon': Icons.dashboard},
    {'id': 'products', 'title': 'Product Management', 'icon': Icons.inventory_2},
    {'id': 'retailers', 'title': 'Retailer Management', 'icon': Icons.store},
    {'id': 'users', 'title': 'User Management', 'icon': Icons.people},
    {'id': 'complaints', 'title': 'Complaints Management', 'icon': Icons.comment},
    {'id': 'price_freeze', 'title': 'Price Freeze Management', 'icon': Icons.ac_unit},
    {'id': 'settings', 'title': 'Settings', 'icon': Icons.settings}
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.loadAdminDashboard();
      
      print('Admin Dashboard API Response: ${result['success']} - ${result['message']}');

      if (result['success'] == true) {
        setState(() {
          _dashboardData = result['data'] ?? {};
          _isLoading = false;
          _error = null;
        });
      } else {
        // Use the user-friendly error message from AuthService
        setState(() {
          _error = result['message'] ?? 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback error handling if something unexpected happens
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
      print('❌ Admin Dashboard: Unexpected error: $e');
    }
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _switchTab(String tabId) {
    setState(() {
      activeTab = tabId;
    });
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  int _getBottomNavIndex() {
    switch (activeTab) {
      case 'dashboard':
        return 0;
      case 'products':
        return 1;
      case 'retailers':
        return 2;
      case 'monitoring':
        return 3;
      default:
        return 0;
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _switchTab('dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/admin/product-crud');
        break;
      case 2:
        Navigator.pushNamed(context, '/retailers/stores');
        break;
      case 3:
        Navigator.pushNamed(context, '/monitoring');
        break;
      case 4:
        // Open drawer for more options
        Scaffold.of(context).openDrawer();
        break;
    }
  }

  Future<void> _generateReport() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/admin/admin_dashboard.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
        body: 'generate_report=1',
      );

      if (response.statusCode == 200) {
        // Handle CSV download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    return MaterialApp(
      theme: theme,
      home: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Use the Logout button to exit your session.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        },
        child: Scaffold(
        backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        appBar: _buildMobileAppBar(),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? _buildErrorWidget()
            : _buildMobileContent(),
        bottomNavigationBar: _buildBottomNavigationBar(),
        drawer: _buildMobileDrawer(),
      ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Text(
        'DTI Admin Dashboard',
        style: TextStyle(
          color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 2,
      iconTheme: IconThemeData(
        color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
      ),
      actions: [
        // Dark Mode Toggle
        IconButton(
          onPressed: _toggleDarkMode,
          icon: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        // Notification Bell
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/notifications');
              },
              icon: Icon(
                Icons.notifications,
                color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            if ((_dashboardData['stats']?['price_freeze']?['active'] ?? 0) > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${(_dashboardData['stats']?['price_freeze']?['active'] ?? 0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        // Logout Button
        IconButton(
          onPressed: _confirmLogout,
          icon: Icon(
            Icons.logout,
            color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
          ),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'DTI TACP System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dashboardData['user']?['first_name'] != null && _dashboardData['user']?['last_name'] != null
                    ? '${_dashboardData['user']['first_name']} ${_dashboardData['user']['last_name']}'
                    : 'Administrator',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    _switchTab('dashboard');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: 'Product Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/product-crud');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.folder,
                  title: 'Product Folders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/product-folders');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.store,
                  title: 'Retailer Management',
                  onTap: () {
                    Navigator.pop(context);
                     Navigator.pushNamed(context, '/retailers/stores');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.monitor,
                  title: 'Monitoring',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/monitoring');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'Monitoring Forms',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/monitoring-forms');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.ac_unit,
                  title: 'Price Freeze Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/price-freeze');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/notifications');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.comment,
                  title: 'Complaints Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin/complaints');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Products Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _switchTab('settings');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
      currentIndex: _getBottomNavIndex(),
      onTap: _onBottomNavTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Retailers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor),
          label: 'Monitoring',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu Toggle
          IconButton(
            onPressed: _toggleMenu,
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Text(
            'DTI Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Search Bar
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for something...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Notification Bell
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications, color: Colors.white),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${(_dashboardData['stats']?['price_freeze']?['active'] ?? 0) + 2}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          
          // Dark Mode Toggle
          IconButton(
            onPressed: _toggleDarkMode,
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Profile
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    // Extract user-friendly error message (remove technical details)
    String errorMessage = _error ?? 'Unknown error occurred';
    
    // Remove technical details if present
    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('ClientException') ||
        errorMessage.contains('Connection reset by peer')) {
      // Extract meaningful part before technical details
      final parts = errorMessage.split(':');
      if (parts.isNotEmpty && !parts.first.contains('Connection error')) {
        errorMessage = parts.first.trim();
      }
      // Ensure we have a user-friendly message
      if (errorMessage.contains('Connection reset')) {
        errorMessage = 'Connection was reset. Please check your internet connection.';
      } else if (errorMessage.contains('Connection error')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      }
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent() {
    switch (activeTab) {
      case 'dashboard':
        return _buildMobileDashboard();
      case 'settings':
        return _buildSettingsTab();
      default:
        return _buildMobileDashboard();
    }
  }

  Widget _buildMobileDashboard() {
    final stats = _dashboardData['stats'] ?? {};
    final recentActivities = _dashboardData['recent_activities'] ?? [];
    final recentComplaints = _dashboardData['recent_complaints'] ?? [];
    final priceFreezeAlerts = _dashboardData['price_freeze_alerts'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s what\'s happening with your system today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions Grid
            _buildMobileQuickActions(),
            
            const SizedBox(height: 24),
            
            // Stats Cards
            _buildMobileStatsCards(stats),
            
            const SizedBox(height: 24),
            
            // Price Freeze Alerts (if any)
            if (priceFreezeAlerts.isNotEmpty) ...[
              _buildMobilePriceFreezeAlerts(priceFreezeAlerts),
              const SizedBox(height: 24),
            ],
            
            // Recent Activities
            _buildMobileRecentActivities(recentActivities),
            
            const SizedBox(height: 24),
            
            // Recent Complaints
            _buildMobileRecentComplaints(recentComplaints),
            
            const SizedBox(height: 100), // Bottom padding for navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildMobileQuickActions() {
    final quickActions = [
      {
        'title': 'Product Management',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF3B82F6),
        'onTap': () => Navigator.pushNamed(context, '/admin/product-crud'),
      },
      {
        'title': 'Product Folders',
        'icon': Icons.folder,
        'color': const Color(0xFF10B981),
        'onTap': () => Navigator.pushNamed(context, '/admin/product-folders'),
      },
      {
        'title': 'Retailer Management',
        'icon': Icons.store,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => Navigator.pushNamed(context, '/retailers/stores'),
      },
      {
        'title': 'Monitoring',
        'icon': Icons.monitor,
        'color': const Color(0xFFF59E0B),
        'onTap': () => Navigator.pushNamed(context, '/monitoring'),
      },
      {
        'title': 'Monitoring Forms',
        'icon': Icons.assignment,
        'color': const Color(0xFF10B981),
        'onTap': () => Navigator.pushNamed(context, '/admin/monitoring-forms'),
      },
      {
        'title': 'Price Freeze',
        'icon': Icons.ac_unit,
        'color': const Color(0xFFEF4444),
        'onTap': () => Navigator.pushNamed(context, '/admin/price-freeze'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: action['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isDarkMode ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatsCards(Map<String, dynamic> stats) {
    final statsData = [
      {
        'title': 'Consumers',
        'value': '${stats['consumers'] ?? 0}',
        'change': '+${stats['growth']?['consumers_percent']?.toStringAsFixed(1) ?? '5.2'}%',
        'trend': 'up',
        'icon': Icons.people,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Retailers',
        'value': '${stats['retailers'] ?? 0}',
        'change': '+${stats['growth']?['retailers_percent']?.toStringAsFixed(1) ?? '3.1'}%',
        'trend': 'up',
        'icon': Icons.store,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Products',
        'value': '${stats['products'] ?? 0}',
        'change': '${stats['growth']?['products_percent']?.toStringAsFixed(1) ?? '-1.2'}%',
        'trend': 'down',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Price Alerts',
        'value': '${stats['price_freeze']?['total'] ?? 0}',
        'change': '${stats['price_freeze']?['active'] ?? 0} active',
        'trend': stats['price_freeze']?['active'] > 0 ? 'warning' : 'normal',
        'icon': Icons.ac_unit,
        'color': stats['price_freeze']?['active'] > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final stat = statsData[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: stat['color'] as Color,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                  Icon(
                    stat['trend'] == 'up' ? Icons.arrow_upward : 
                    stat['trend'] == 'down' ? Icons.arrow_downward : Icons.remove,
                    color: stat['trend'] == 'up' ? Colors.green : 
                           stat['trend'] == 'down' ? Colors.red : Colors.grey,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                ),
              ),
              Text(
                stat['change'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: stat['trend'] == 'up' ? Colors.green : 
                         stat['trend'] == 'down' ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobilePriceFreezeAlerts(List<dynamic> alerts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(
                    'Price Freeze Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/price-freeze'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.take(3).map((alert) => _buildMobileAlertItem(alert)),
        ],
      ),
    );
  }

  Widget _buildMobileAlertItem(dynamic alert) {
    final status = alert['status'] ?? 'unknown';
    final statusColor = status == 'active' ? Colors.green : 
                      status == 'expired' ? Colors.red : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? 'Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildMobileRecentActivities(List<dynamic> activities) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activities',
                  style: TextStyle(
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ...activities.take(3).map((activity) => _buildMobileActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildMobileActivityItem(dynamic activity) {
    final icon = _getActivityIcon(activity['type'] ?? '');
    final color = _getActivityColor(activity['type'] ?? '');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  activity['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(activity['time']),
            style: TextStyle(
              fontSize: 10,
              color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRecentComplaints(List<dynamic> complaints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Complaints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/complaints'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (complaints.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent complaints',
                  style: TextStyle(
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ...complaints.take(3).map((complaint) => _buildMobileComplaintItem(complaint)),
        ],
      ),
    );
  }

  Widget _buildMobileComplaintItem(dynamic complaint) {
    final status = complaint['complaint_status'] ?? 'pending';
    final statusColor = _getComplaintStatusColor(status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.comment, color: Color(0xFF3B82F6), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['issue_description'] ?? 'Complaint',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(complaint['date_filed']),
            style: TextStyle(
              fontSize: 10,
              color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) => _toggleDarkMode(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Admin Profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/admin/profile'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Generate Report'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _generateReport,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildDashboardTab() {
    final stats = _dashboardData['stats'] ?? {};
    final recentActivities = _dashboardData['recent_activities'] ?? [];
    final recentComplaints = _dashboardData['recent_complaints'] ?? [];
    final priceFreezeAlerts = _dashboardData['price_freeze_alerts'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.download),
                label: const Text('Generate Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Stats Cards
          _buildStatsCards(stats),
          
          const SizedBox(height: 32),
          
          // Quick Actions
          _buildQuickActions(),
          
          const SizedBox(height: 32),
          
          // Price Freeze Alerts (if any)
          if (priceFreezeAlerts.isNotEmpty) ...[
            _buildPriceFreezeAlerts(priceFreezeAlerts),
            const SizedBox(height: 32),
          ],
          
          // Recent Activities and Complaints
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRecentActivities(recentActivities),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildRecentComplaints(recentComplaints),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    final statsData = [
      {
        'title': 'Consumers',
        'value': '${stats['consumers'] ?? 0}',
        'change': '+${stats['growth']?['consumers_percent']?.toStringAsFixed(1) ?? '5.2'}% from last month',
        'trend': 'up',
        'icon': Icons.people,
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEFF6FF),
      },
      {
        'title': 'Retailers',
        'value': '${stats['retailers'] ?? 0}',
        'change': '+${stats['growth']?['retailers_percent']?.toStringAsFixed(1) ?? '3.1'}% from last month',
        'trend': 'up',
        'icon': Icons.store,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFD1FAE5),
      },
      {
        'title': 'Products',
        'value': '${stats['products'] ?? 0}',
        'change': '${stats['growth']?['products_percent']?.toStringAsFixed(1) ?? '-1.2'}% from last month',
        'trend': 'down',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF8B5CF6),
        'bgColor': const Color(0xFFEDE9FE),
      },
      {
        'title': 'Price Freeze Alerts',
        'value': '${stats['price_freeze']?['total'] ?? 0}',
        'change': '${stats['price_freeze']?['active'] ?? 0} active',
        'trend': stats['price_freeze']?['active'] > 0 ? 'warning' : 'normal',
        'icon': Icons.ac_unit,
        'color': stats['price_freeze']?['active'] > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        'bgColor': stats['price_freeze']?['active'] > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final stat = statsData[index];
        return Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: stat['color'] as Color,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: stat['bgColor'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      stat['trend'] == 'up' ? Icons.arrow_upward : 
                      stat['trend'] == 'down' ? Icons.arrow_downward : Icons.remove,
                      color: stat['trend'] == 'up' ? Colors.green : 
                             stat['trend'] == 'down' ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stat['change'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: stat['trend'] == 'up' ? Colors.green : 
                               stat['trend'] == 'down' ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      {'title': 'Manage Users', 'icon': Icons.people, 'color': const Color(0xFF3B82F6)},
      {'title': 'Manage Products', 'icon': Icons.inventory_2, 'color': const Color(0xFF10B981)},
      {'title': 'Store Products', 'icon': Icons.store, 'color': const Color(0xFF8B5CF6)},
      {'title': 'View Complaints', 'icon': Icons.comment, 'color': const Color(0xFFF59E0B)},
      {'title': 'Registration Code', 'icon': Icons.qr_code, 'color': const Color(0xFFEF4444)},
      {'title': 'Consumer Management', 'icon': Icons.people_alt, 'color': const Color(0xFF06B6D4)},
      {'title': 'Retailer Management', 'icon': Icons.storefront, 'color': const Color(0xFF84CC16)},
      {'title': 'Consumer Verification', 'icon': Icons.verified_user, 'color': const Color(0xFFEC4899)},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Handle action tap
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action['title'] as String} tapped')),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isDarkMode ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFreezeAlerts(List<dynamic> alerts) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(
                    'Latest Price Freeze Alerts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _switchTab('price_freeze');
                },
                child: const Text('Manage All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final status = alert['status'] ?? 'unknown';
              final statusColor = status == 'active' ? Colors.green : 
                                status == 'expired' ? Colors.red : Colors.grey;
              
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: statusColor,
                      width: 4,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF9FAFB),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert['title'] ?? 'Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert['message'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          alert['created_by_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          _formatDate(alert['created_at']),
                          style: TextStyle(
                            fontSize: 10,
                            color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(List<dynamic> activities) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No recent activities',
                  style: TextStyle(
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ...activities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final icon = _getActivityIcon(activity['type'] ?? '');
    final color = _getActivityColor(activity['type'] ?? '');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  activity['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(activity['time']),
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentComplaints(List<dynamic> complaints) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Complaints',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (complaints.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No recent complaints',
                  style: TextStyle(
                    color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ...complaints.map((complaint) => _buildComplaintItem(complaint)),
        ],
      ),
    );
  }

  Widget _buildComplaintItem(Map<String, dynamic> complaint) {
    final status = complaint['complaint_status'] ?? 'pending';
    final statusColor = _getComplaintStatusColor(status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.comment,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['issue_description'] ?? 'Complaint',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(complaint['date_filed']),
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'consumer_registered':
        return Icons.person_add;
      case 'retailer_added':
        return Icons.store;
      case 'product_added':
        return Icons.inventory;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'consumer_registered':
        return const Color(0xFF3B82F6);
      case 'retailer_added':
        return const Color(0xFF10B981);
      case 'product_added':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getComplaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return '';
    try {
      final date = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return _formatDate(timeString);
      }
    } catch (e) {
      return timeString;
    }
  }
}