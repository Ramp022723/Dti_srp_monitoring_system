import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ConsumerDashboard extends StatefulWidget {
  const ConsumerDashboard({Key? key}) : super(key: key);

  @override
  State<ConsumerDashboard> createState() => _ConsumerDashboardState();
}

class _ConsumerDashboardState extends State<ConsumerDashboard> {
  bool isMenuOpen = false;
  String activeTab = 'dashboard';
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _error;

  final List<Map<String, dynamic>> stats = [
    {
      'title': 'COMPLAINTS',
      'value': '0',
      'change': '+0% from last month',
      'trend': 'up',
      'icon': Icons.report,
      'color': Colors.orange
    },
    {
      'title': 'REVIEWS',
      'value': '0',
      'change': '+0% from last month',
      'trend': 'up',
      'icon': Icons.rate_review,
      'color': Colors.blue
    },
    {
      'title': 'FAVORITES',
      'value': '0',
      'change': '+0% from last month',
      'trend': 'up',
      'icon': Icons.favorite,
      'color': Colors.red
    }
  ];

  final List<Map<String, dynamic>> quickActions = [
    {'title': 'File Complaint', 'icon': Icons.report, 'color': Colors.red},
    {'title': 'View Products', 'icon': Icons.shopping_bag, 'color': Colors.blue},
    {'title': 'Notifications', 'icon': Icons.notifications, 'color': Colors.orange},
    {'title': 'Profile', 'icon': Icons.person, 'color': Colors.green},
  ];

  final List<Map<String, dynamic>> menuItems = [
    {'id': 'dashboard', 'title': 'Dashboard', 'icon': Icons.home},
    {'id': 'complaints', 'title': 'My Complaints', 'icon': Icons.report},
    {'id': 'notifications', 'title': 'Notifications', 'icon': Icons.notifications},
    {'id': 'products', 'title': 'Products', 'icon': Icons.shopping_bag},
    {'id': 'profile', 'title': 'Profile', 'icon': Icons.person},
    {'id': 'settings', 'title': 'Settings', 'icon': Icons.settings},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _performConsumerAction(String action, [Map<String, dynamic>? params]) async {
    try {
      Map<String, dynamic> result = {'status': 'error', 'message': 'Unknown action'};
      switch (action) {
        case 'file_complaint':
          result = await AuthService.submitConsumerComplaint(
            issueDescription: params?['issue_description'] ?? 'Complaint',
            retailerName: params?['retailer_name'] ?? 'Unknown Retailer',
            additionalDetails: params?['additional_details'] ?? 'No details',
          );
          break;
        case 'add_price_monitor':
          // Placeholder: No direct API found; show info
          result = {'status': 'success', 'message': 'Price monitor feature coming soon'};
          break;
        case 'get_verified_stores':
          // Placeholder: No direct API found; show info
          result = {'status': 'success', 'message': 'Verified stores feature coming soon'};
          break;
        default:
          result = {'status': 'error', 'message': 'Unknown action: $action'};
      }

      if (!mounted) return;
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Success'), backgroundColor: Colors.green),
        );
        await _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Action failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.loadDashboardDataByRole('consumer');
      if (result['status'] == 'success') {
          setState(() {
          _dashboardData = result['data'] ?? {};
            _isLoading = false;
          _updateStatsWithApiData();
          });
        } else {
          setState(() {
          _error = result['message'] ?? 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _updateStatsWithApiData() {
    try {
      final protection = _dashboardData['consumer_protection'] ?? {};
      final complaints = protection['complaints_filed'] ?? 0;
      final reviews = _dashboardData['marketplace_activity']?['reviews_written'] ?? 0;
      final favorites = _dashboardData['marketplace_activity']?['favorite_stores'] ?? 0;
      stats[0]['value'] = '$complaints';
      stats[1]['value'] = '$reviews';
      stats[2]['value'] = '$favorites';
    } catch (_) {}
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
                                'Consumer Dashboard',
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
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 20,
                          child: Text(
                            'C',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
                                                    ? Colors.green[50]
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: activeTab == item['id']
                                                    ? Border.all(
                                                        color: Colors.green[200]!,
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
                                                        ? Colors.green[600]
                                                        : Colors.grey[700],
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    item['title'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: activeTab == item['id']
                                                          ? Colors.green[600]
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
                                        onTap: () async {
                                          await AuthService.logout();
                                          if (!mounted) return;
                                          Navigator.pushReplacementNamed(context, '/login');
                                        },
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

  // Build main content by tab
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorWidget();
    }
    switch (activeTab) {
      case 'complaints':
        return _buildComplaintsTab();
      case 'notifications':
        return _buildNotificationsTab();
      case 'products':
        return _buildProductsTab();
      case 'profile':
        return _buildProfileTab();
      case 'settings':
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
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

  // Dashboard tab (default)
  Widget _buildDashboardTab() {
    final protection = _dashboardData['consumer_protection'] ?? {};
    final marketplaceActivity = _dashboardData['marketplace_activity'] ?? {};

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
                colors: [Colors.green, Color(0xFF2E7D32)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                        'Welcome back, Consumer!',
                        style: TextStyle(
                          fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      SizedBox(height: 4),
                            Text(
                        "Here's your account overview",
                        style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(Icons.person, color: Colors.white, size: 24),
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
                    case 'File Complaint':
                      _performConsumerAction('file_complaint', {
                        'title': 'Sample',
                        'description': 'Sample description',
                        'category': 'general',
                        'priority': 'medium',
                      });
          break;
                    case 'View Products':
                      setState(() => activeTab = 'products');
          break;
                    case 'Notifications':
                      setState(() => activeTab = 'notifications');
          break;
                    case 'Profile':
                      setState(() => activeTab = 'profile');
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

  // Tabs
  Widget _buildComplaintsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService.loadConsumerComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data?['data']?['complaints'] ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final c = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (c['status'] ?? '') == 'resolved' ? Colors.green : Colors.orange,
                  child: Icon((c['status'] ?? '') == 'resolved' ? Icons.check : Icons.warning, color: Colors.white),
                ),
                title: Text(c['title'] ?? 'Complaint'),
                subtitle: Text(c['description'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService.loadConsumerNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data?['data']?['notifications'] ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final n = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.notifications)),
                title: Text(n['title'] ?? 'Notification'),
                subtitle: Text(n['message'] ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService.loadConsumerProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data?['data']?['products'] ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
                title: Text(p['product_name'] ?? 'Product'),
                subtitle: Text('₱${p['price'] ?? '0.00'}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final profile = _dashboardData['profile'] ?? {};
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(profile['name'] ?? 'Consumer'),
              subtitle: Text(profile['email'] ?? ''),
                    ),
                  ),
                ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
        children: [
                  Icon(Icons.settings, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Manage your account preferences and privacy settings.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
