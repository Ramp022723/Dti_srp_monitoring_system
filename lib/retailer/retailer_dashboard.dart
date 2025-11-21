import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/auth_service.dart';
import 'retailer_agreement_page.dart';
import 'retailer_store_products_page.dart';
import 'retailer_product_list_page.dart';
import 'retailer_profile_page.dart';
import 'retailer_login_page.dart';
import 'retailer_notifications_page.dart';

class RetailerDashboard extends StatefulWidget {
  const RetailerDashboard({Key? key}) : super(key: key);

  @override
  State<RetailerDashboard> createState() => _RetailerDashboardState();
}

class _RetailerDashboardState extends State<RetailerDashboard> {
  bool isMenuOpen = false;
  String activeTab = 'dashboard';
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _error;
  
  // Notification variables
  int _unreadNotificationCount = 0;
  List<dynamic> _recentNotifications = [];
  Timer? _notificationTimer;
  
  final List<Map<String, dynamic>> stats = [
    {
      'title': 'TOTAL SALES',
      'value': '0',
      'change': '+0% from last month',
      'trend': 'up',
      'icon': Icons.trending_up,
      'color': Colors.green
    },
    {
      'title': 'PRODUCTS',
      'value': '0',
      'change': '+0% from last month',
      'trend': 'up',
      'icon': Icons.inventory,
      'color': Colors.blue
    },
    {
      'title': 'COMPLAINTS',
      'value': '0',
      'change': '+0% from last month',
      'trend': 'down',
      'icon': Icons.warning,
      'color': Colors.orange
    }
  ];

  final List<Map<String, dynamic>> quickActions = [
    {'title': 'Manage Products', 'icon': Icons.inventory, 'color': Colors.blue},
    {'title': 'Store Products', 'icon': Icons.store, 'color': Colors.green},
    {'title': 'View Complaints', 'icon': Icons.warning, 'color': Colors.orange},
    {'title': 'Agreements', 'icon': Icons.description, 'color': Colors.purple},
    {'title': 'Profile', 'icon': Icons.person, 'color': Colors.indigo},
    {'title': 'Product List', 'icon': Icons.list_alt, 'color': Colors.teal}
  ];

  final List<Map<String, dynamic>> menuItems = [
    {'id': 'dashboard', 'title': 'Dashboard', 'icon': Icons.home},
    {'id': 'products', 'title': 'My Products', 'icon': Icons.inventory},
    {'id': 'store_products', 'title': 'Store Products', 'icon': Icons.store},
    {'id': 'product_list', 'title': 'Product List', 'icon': Icons.list_alt},
    {'id': 'complaints', 'title': 'Complaints', 'icon': Icons.warning},
    {'id': 'agreements', 'title': 'Agreements', 'icon': Icons.description},
    {'id': 'notifications', 'title': 'Notifications', 'icon': Icons.notifications},
    {'id': 'profile', 'title': 'Profile', 'icon': Icons.person},
    {'id': 'settings', 'title': 'Settings', 'icon': Icons.settings}
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadNotifications();
    
    // Set up periodic refresh for real-time data (every 30 seconds)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && activeTab == 'dashboard') {
        _loadDashboardData();
      }
    });
    
    // Set up periodic refresh for notifications (every 30 seconds)
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await AuthService.loadRetailerNotifications();
      if (result['status'] == 'success' && mounted) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final notifications = (data['notifications'] as List<dynamic>? ) ?? [];
        
        setState(() {
          _recentNotifications = notifications.take(5).toList();
          _unreadNotificationCount = notifications.where((n) => n['is_read'] == 0).length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Notification List
                Expanded(
                  child: _recentNotifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No notifications',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _recentNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _recentNotifications[index];
                            final isRead = notification['is_read'] == 1;
                            final message = notification['message'] ?? '';
                            
                            return ListTile(
                              leading: Icon(
                                isRead ? Icons.notifications_none : Icons.notifications,
                                color: isRead ? Colors.grey : const Color(0xFF2563EB),
                              ),
                              title: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                  color: isRead ? Colors.grey : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: !isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RetailerNotificationsPage(),
                                  ),
                                ).then((_) => _loadNotifications());
                              },
                            );
                          },
                        ),
                ),
                // View All Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RetailerNotificationsPage(),
                          ),
                        ).then((_) => _loadNotifications());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View All Notifications'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.loadRetailerDashboard();
      final dynamic rawStatus = result['http_status'];
      final int? httpStatus = rawStatus is int ? rawStatus : null;
      final String? code = result['code'] as String?;
      final bool unauthorized = httpStatus == 401 || code == 'UNAUTHORIZED';
      final bool forbidden = httpStatus == 403 || code == 'FORBIDDEN';

      if (unauthorized || forbidden) {
        // Do not auto-logout; show message and keep user until they choose to logout
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session issue detected. Please logout and login again.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Keep displaying cached/empty data rather than forcing logout
        setState(() {
          _dashboardData = {};
          _isLoading = false;
        });
        return;
      }

      if (result['status'] == 'success') {
        setState(() {
          _dashboardData = result['data'] ?? {};
          _isLoading = false;
          _updateStatsWithApiData();
        });
      } else {
        // Admin parity: do not block UI; show warning and render empty dashboard
        setState(() {
          _dashboardData = {};
          _isLoading = false;
          _error = null;
        });
        _showHttpResultSnack(result, fallbackError: 'Failed to load dashboard data');
      }
    } catch (e) {
      setState(() {
        _dashboardData = {};
        _isLoading = false;
        _error = null;
      });
      _showHttpResultSnack({'status': 'error', 'message': 'Connection error: $e'});
    }
  }

  void _updateStatsWithApiData() {
    try {
      // Map API data to stats based on the PHP API response structure
      final statsData = _dashboardData['stats'] ?? {};
      final productsListed = (statsData['products_listed'] ?? 0) as int;
      final activeComplaints = (statsData['active_complaints'] ?? 0) as int;
      final complianceRate = (statsData['compliance_rate'] ?? 0) as int;
      
      // Update stats array with real-time data
      stats[0]['value'] = '₱0'; // Sales data not available in current API
      stats[0]['change'] = 'Real-time data';
      stats[1]['value'] = '$productsListed';
      stats[1]['change'] = 'Products listed';
      stats[2]['value'] = '$activeComplaints';
      stats[2]['change'] = 'Active complaints';
      
      // Add compliance rate as a fourth stat if needed
      if (stats.length > 3) {
        stats[3]['value'] = '$complianceRate%';
        stats[3]['change'] = 'Compliance rate';
      }
    } catch (e) {
      print('Error updating stats with API data: $e');
    }
  }

  // Maps AuthService result objects to user-facing SnackBars mirroring admin behavior
  void _showHttpResultSnack(
    Map<String, dynamic> result, {
    String? fallbackSuccess,
    String? fallbackError,
  }) {
    if (!mounted) return;

    final dynamic rawStatus = result['http_status'];
    final int? httpStatus = rawStatus is int ? rawStatus : null;
    final String? code = result['code'] as String?;
    final bool isSuccess = (result['status'] == 'success') || httpStatus == 200 || code == 'HTTP_200';

    String message = (result['message'] as String?) ??
        (isSuccess ? (fallbackSuccess ?? 'Action completed successfully')
                   : (fallbackError ?? 'Action failed'));

    Color bg = Colors.green;
    if (!isSuccess) {
      final int? status = httpStatus ?? _codeToStatus(code);
      switch (status) {
        case 400:
          message = 'Bad Request: The request is invalid or unsupported.';
          bg = Colors.red;
          break;
        case 404:
          message = 'API endpoint not found. Please check the server configuration.';
          bg = Colors.red;
          break;
        case 500:
          message = 'Internal server error. Please try again later.';
          bg = Colors.red;
          break;
        default:
          final label = status != null ? '$status' : (code ?? 'UNKNOWN');
          message = 'Server error: $label';
          bg = Colors.red;
      }
      }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
        content: Text(message),
        backgroundColor: bg,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  int? _codeToStatus(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'HTTP_200':
        return 200;
      case 'HTTP_400':
        return 400;
      case 'HTTP_404':
        return 404;
      case 'HTTP_500':
        return 500;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Prevent going back to login page
        // User must use logout button to return to login
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
          Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
          ),
        ],
      ),
                child: SafeArea(
                  child: Padding(
        padding: const EdgeInsets.all(16),
                    child: Row(
          children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isMenuOpen = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: const Icon(Icons.menu, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                                'DTI TACP System',
                                style: TextStyle(
                                  fontSize: 18,
                      fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                    ),
                  ),
                  Text(
                                'Retailer Dashboard',
                        style: TextStyle(
                          fontSize: 14,
                                  color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                        ),
                        GestureDetector(
                          onTap: _loadDashboardData,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Notification Bell Icon
                        GestureDetector(
                          onTap: () {
                            _showNotificationsPopup(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications, color: Colors.grey),
                                if (_unreadNotificationCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 20,
                          child: Text(
                            'R',
              style: TextStyle(
                              color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
                        ),
                        const SizedBox(width: 8),
                        // Explicit Logout button in header
                        GestureDetector(
                          onTap: _confirmLogout,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.red.withOpacity(0.08),
                            ),
                            child: const Icon(Icons.logout, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),

          // Side Menu
          if (isMenuOpen)
            GestureDetector(
              onTap: () {
                setState(() {
                  isMenuOpen = false;
                });
              },
              child: Container(
                color: Colors.black54,
                child: Row(
                  children: [
            Container(
                      width: 280,
                      height: double.infinity,
                      color: Colors.white,
                      child: SafeArea(
                        child: Column(
                          children: [
                            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
            const Text(
                                    'Menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isMenuOpen = false;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                  children: [
                    Expanded(
                                      child: ListView(
                                        children: menuItems.map((item) {
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                activeTab = item['id'];
                                                isMenuOpen = false;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: activeTab == item['id']
                                                    ? Colors.blue[50]
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: activeTab == item['id']
                                                    ? Border.all(
                                                        color: Colors.blue[200]!,
                                                        width: 1,
                                                      )
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    item['icon'],
                                                    size: 20,
                                                    color: activeTab == item['id']
                                                        ? Colors.blue[600]
                                                        : Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                                                  Text(
                                                    item['title'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: activeTab == item['id']
                                                          ? Colors.blue[600]
                                                          : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.only(top: 16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: _confirmLogout,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.logout,
                                                size: 20,
                                                color: Colors.grey[700],
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Logout',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                                        ),
                                      ),
                                    ),
                                  ],
                        ),
                      ),
                    ),
                  ],
                ),
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  // Build main content based on active tab
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorWidget();
    }
    switch (activeTab) {
      case 'products':
        return _buildProductsContent();
      case 'store_products':
        return _buildStoreProductsContent();
      case 'product_list':
        return _buildProductListContent();
      case 'complaints':
        return _buildComplaintsContent();
      case 'agreements':
        return _buildAgreementsContent();
      case 'notifications':
        return _buildNotificationsContent();
      case 'profile':
        return _buildProfileContent();
      case 'settings':
        return _buildSettingsContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
              const Text(
            'Error Loading Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Dashboard content (default view)
  Widget _buildDashboardContent() {
    final userData = _dashboardData['user'] ?? {};
    final welcomeMessage = _dashboardData['welcome_message'] ?? 'Welcome to DTI Retailer Dashboard!';
    final subtitle = _dashboardData['subtitle'] ?? "Manage your products and monitor pricing effectively";
    final storeName = userData['store_name'] ?? userData['username'] ?? 'Retailer';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Color(0xFF1565C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            Text(
                        welcomeMessage,
                        style: const TextStyle(
                          fontSize: 20,
                                fontWeight: FontWeight.bold,
                          color: Colors.white,
                              ),
                            ),
                        const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(Icons.store, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Grid
          Column(
            children: stats.map((stat) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                        Row(
                          children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: stat['color'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(stat['icon'], color: Colors.white, size: 24),
                        ),
                        const Spacer(),
                            Text(
                          stat['title'],
                              style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                          stat['value'],
                          style: const TextStyle(
                            fontSize: 32,
                                fontWeight: FontWeight.bold,
                            color: Colors.black87,
                              ),
                            ),
                        const Spacer(),
                          ],
                        ),
                      const SizedBox(height: 8),
                        Row(
                          children: [
                        Icon(
                          stat['trend'] == 'up' ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: stat['trend'] == 'up' ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                            Text(
                          stat['change'],
                              style: TextStyle(
                            fontSize: 14,
                            color: stat['trend'] == 'up' ? Colors.green[600] : Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Store Information Section
          if (_dashboardData['store_information'] != null) ...[
            const Text(
              'Store Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  _buildInfoRow('Store Name', _dashboardData['store_information']['store_name'] ?? 'N/A'),
                  _buildInfoRow('Address', _dashboardData['store_information']['store_address'] ?? 'N/A'),
                  _buildInfoRow('Representative', _dashboardData['store_information']['store_rep'] ?? 'N/A'),
                  _buildInfoRow('Monitoring Date', _dashboardData['store_information']['monitoring_date'] ?? 'N/A'),
                  _buildInfoRow('Monitoring Mode', _dashboardData['store_information']['monitoring_mode'] ?? 'N/A'),
                  _buildInfoRow('DTI Monitor', _dashboardData['store_information']['dti_monitor'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Products Section
          if (_dashboardData['products'] != null && (_dashboardData['products'] as List).isNotEmpty) ...[
            const Text(
              'Recent Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                children: [
                  for (int i = 0; i < (_dashboardData['products'] as List).length && i < 5; i++) ...[
                    _buildProductRow(_dashboardData['products'][i]),
                    if (i < (_dashboardData['products'] as List).length - 1 && i < 4)
                      const Divider(height: 20),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Actions
            const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: quickActions.length,
                      itemBuilder: (context, index) {
              final action = quickActions[index];
              return GestureDetector(
                onTap: () {
                  switch (action['title']) {
                    case 'Manage Products':
                      setState(() => activeTab = 'products');
                      break;
                    case 'Store Products':
                      setState(() => activeTab = 'store_products');
                      break;
                    case 'View Complaints':
                      setState(() => activeTab = 'complaints');
                      break;
                    case 'Agreements':
                      setState(() => activeTab = 'agreements');
                      break;
                    case 'Profile':
                      setState(() => activeTab = 'profile');
                      break;
                    case 'Product List':
                      setState(() => activeTab = 'product_list');
                      break;
                  }
                },
                child: Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: action['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action['icon'], color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 12),
                              Text(
                        action['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                ),
                        );
                      },
            ),
          ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['product_name'] ?? 'Unknown Product',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (product['brand'] != null)
                Text(
                  'Brand: ${product['brand']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              if (product['category_name'] != null)
                Text(
                  'Category: ${product['category_name']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        if (product['srp'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '₱${product['srp']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Individual tab content
  Widget _buildProductsContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService.loadRetailerProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
              ],
            ),
          );
        }
        final products = snapshot.data?['data']?['products'] ?? [];
        return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              if (products.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: const Column(
        children: [
                      Icon(Icons.inventory, size: 64, color: Colors.blue),
                      SizedBox(height: 16),
                      Text('No Products Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('You haven\'t added any products yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.inventory, color: Colors.white)),
                        title: Text(product['product_name'] ?? 'Unknown Product'),
                        subtitle: Text('Price: ₱${product['price'] ?? '0.00'}'),
                        trailing: Text(
                          product['status'] ?? 'Active',
            style: TextStyle(
                            color: (product['status'] ?? 'active') == 'active' ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildComplaintsContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService.loadRetailerComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
              ],
            ),
          );
        }
        final complaints = snapshot.data?['data']?['complaints'] ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complaints', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              if (complaints.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning, size: 64, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('No Complaints Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('No complaints have been submitted yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    final status = complaint['status'] ?? complaint['complaint_status'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: status == 'resolved' ? Colors.green : Colors.orange,
                          child: Icon(status == 'resolved' ? Icons.check : Icons.warning, color: Colors.white),
                        ),
                        title: Text(complaint['issue_description'] ?? complaint['title'] ?? 'Unknown Complaint'),
                        subtitle: Text(status.isEmpty ? 'No status' : status),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'resolved' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.isEmpty ? 'Unknown' : status,
                style: TextStyle(
                              color: status == 'resolved' ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildAgreementsContent() {
    return const RetailerAgreementPage();
  }

  Widget _buildNotificationsContent() {
    return const RetailerNotificationsPage();
  }

  Widget _buildProfileContent() {
    return const RetailerProfilePage();
  }

  Widget _buildStoreProductsContent() {
    return const RetailerStoreProductsPage();
  }

  Widget _buildProductListContent() {
    return const RetailerProductListPage();
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1)),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.settings, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Store Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Configure your store settings, manage preferences, and handle store-related configurations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


