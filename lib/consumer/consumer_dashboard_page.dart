import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ConsumerDashboardPage extends StatefulWidget {
  const ConsumerDashboardPage({Key? key}) : super(key: key);

  @override
  State<ConsumerDashboardPage> createState() => _ConsumerDashboardPageState();
}

class _ConsumerDashboardPageState extends State<ConsumerDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String? _error;
  int _notificationCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _priceUpdates = [];
  String _username = 'Consumer';
  
  // Additional data for new API methods
  List<dynamic> _complaints = [];
  List<dynamic> _products = [];
  Map<String, dynamic> _profile = {};
  bool _isLoadingComplaints = false;
  bool _isLoadingProducts = false;
  bool _isLoadingProfile = false;

  // Color scheme matching Bootstrap theme from server
  static const Color primaryBlue = Color(0xFF0D6EFD); // Bootstrap primary blue
  static const Color secondaryBlue = Color(0xFF0A58CA); // Bootstrap primary hover
  static const Color lightBlue = Color(0xFFE7F1FF); // Light blue background
  static const Color accentBlue = Color(0xFF0D6EFD); // Same as primary
  static const Color textDark = Color(0xFF212529); // Bootstrap dark text
  static const Color textLight = Color(0xFF6C757D); // Bootstrap gray-600
  static const Color bgWhite = Color(0xFFFFFFFF); // White background
  static const Color bgLight = Color(0xFFF8F9FA); // Bootstrap gray-100
  static const Color borderLight = Color(0xFFDEE2E6); // Bootstrap gray-300
  static const Color successGreen = Color(0xFF198754); // Bootstrap success
  static const Color warningYellow = Color(0xFFFFC107); // Bootstrap warning
  static const Color dangerRed = Color(0xFFDC3545); // Bootstrap danger
  static const Color infoCyan = Color(0xFF0DCAF0); // Bootstrap info

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load dashboard data using API service
      final dashboardResult = await ConsumerDashboardAPI.loadDashboardData();
      
      if (dashboardResult['status'] == 'success') {
        setState(() {
          _dashboardData = dashboardResult['data'];
        });
      } else {
        setState(() {
          _error = dashboardResult['message'] ?? 'Failed to load dashboard data';
        });
      }

      // Load notifications
      await _loadNotifications();
      
      // Load price updates
      await _loadPriceUpdates();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await ConsumerDashboardAPI.loadNotifications();
      
      if (result['status'] == 'success') {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _notificationCount = _notifications.where((n) => n['is_read'] == 0).length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadPriceUpdates() async {
    try {
      final result = await ConsumerDashboardAPI.loadPriceUpdates();
      
      if (result['status'] == 'success') {
        setState(() {
          _priceUpdates = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      } else {
        // Show error message instead of sample data
        print('Error loading price updates: ${result['message']}');
        setState(() {
          _priceUpdates = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load price updates: ${result['message']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading price updates: $e');
      setState(() {
        _priceUpdates = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error loading price updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performConsumerAction(String action, [Map<String, dynamic>? params]) async {
    try {
      final result = await ConsumerDashboardAPI.performAction(action, params: params);
      
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']['message'] ?? 'Action completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Action failed'),
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

  // Load consumer complaints
  Future<void> _loadComplaints() async {
    setState(() {
      _isLoadingComplaints = true;
    });
    
    try {
      final result = await AuthService.loadConsumerComplaints();
      if (result['status'] == 'success') {
        setState(() {
          _complaints = result['data']['complaints'] ?? [];
          _isLoadingComplaints = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${_complaints.length} complaints')),
        );
      } else {
        setState(() {
          _isLoadingComplaints = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load complaints')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingComplaints = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading complaints: $e')),
      );
    }
  }

  // Load consumer products
  Future<void> _loadProducts({String? search, String? category}) async {
    setState(() {
      _isLoadingProducts = true;
    });
    
    try {
      final result = await AuthService.loadConsumerProducts(search: search, category: category);
      if (result['status'] == 'success') {
        setState(() {
          _products = result['data']['products'] ?? [];
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${_products.length} products')),
        );
      } else {
        setState(() {
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load products')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  // Load consumer profile
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });
    
    try {
      final result = await AuthService.getConsumerProfile();
      if (result['status'] == 'success') {
        setState(() {
          _profile = result['data'] ?? {};
          _isLoadingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile loaded: ${_profile['first_name'] ?? 'Unknown'}')),
        );
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load profile')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  // Submit complaint
  Future<void> _submitComplaint(String issueDescription, String retailerName, {String? additionalDetails}) async {
    try {
      final result = await AuthService.submitConsumerComplaint(
        issueDescription: issueDescription,
        retailerName: retailerName,
        additionalDetails: additionalDetails,
      );
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint submitted successfully')),
        );
        // Refresh complaints list
        _loadComplaints();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to submit complaint')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
      );
    }
  }

  // Add product to watchlist
  Future<void> _addToWatchlist(int productId) async {
    try {
      final result = await AuthService.addProductToWatchlist(productId: productId);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added to watchlist')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to add to watchlist')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to watchlist: $e')),
      );
    }
  }

  // Show complaint submission dialog
  void _showComplaintDialog() {
    final TextEditingController issueController = TextEditingController();
    final TextEditingController retailerController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Submit Complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: issueController,
                  decoration: InputDecoration(
                    labelText: 'Issue Description *',
                    hintText: 'Describe the problem...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: retailerController,
                  decoration: InputDecoration(
                    labelText: 'Retailer Name *',
                    hintText: 'Name of the retailer...',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  decoration: InputDecoration(
                    labelText: 'Additional Details',
                    hintText: 'Any additional information...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (issueController.text.isNotEmpty && retailerController.text.isNotEmpty) {
                  _submitComplaint(
                    issueController.text,
                    retailerController.text,
                    additionalDetails: detailsController.text.isNotEmpty ? detailsController.text : null,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in required fields')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Prevent back navigation - user must logout to exit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Use the Logout button in Settings to exit your session.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.shield, color: Colors.white),
              SizedBox(width: 8),
              Text('DTI Consumer', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: _showNotifications,
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: TextStyle(
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
          // Profile dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _navigateToProfile();
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: textDark),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_username, style: TextStyle(color: Colors.white)),
                  SizedBox(width: 4),
                  Icon(Icons.person, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? _buildErrorWidget()
              : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: textLight),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            SizedBox(height: 24),

            // Statistics Cards
            _buildStatsCards(),
            SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
            SizedBox(height: 24),

            // Loaded Data Display
            if (_complaints.isNotEmpty || _products.isNotEmpty || _profile.isNotEmpty) ...[
              _buildLoadedDataSection(),
              SizedBox(height: 24),
            ],

            // Price Updates and Notifications
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildPriceUpdatesTable(),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildNotificationsSection(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $_username!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Monitor product prices and file complaints with ease',
            style: TextStyle(
              fontSize: 18,
              color: textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            '150+',
            'Products Monitored',
            Icons.inventory,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            '25',
            'Active Retailers',
            Icons.store,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            '98%',
            'Price Accuracy',
            Icons.verified,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(String number, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.flash_on, color: primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  'Load Products',
                  'Browse and search products from retailers',
                  Icons.inventory_2,
                  () => _loadProducts(),
                ),
                _buildActionCard(
                  'My Complaints',
                  'View and manage your submitted complaints',
                  Icons.report_problem,
                  () => _loadComplaints(),
                ),
                _buildActionCard(
                  'My Profile',
                  'View and update your profile information',
                  Icons.person,
                  () => _loadProfile(),
                ),
                _buildActionCard(
                  'Submit Complaint',
                  'Report pricing issues or unfair practices',
                  Icons.add_alert,
                  () => _showComplaintDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String description, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceUpdatesTable() {
    return Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Recent Price Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _priceUpdates.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, size: 48, color: textLight),
                          SizedBox(height: 12),
                          Text(
                            'No price updates available',
                            style: TextStyle(color: textLight),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _priceUpdates.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final update = _priceUpdates[index];
                      final changePercent = update['change_percent'] ?? 0.0;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                update['product'] ?? 'Unknown Product',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₱${update['previous_price']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(color: textLight),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₱${update['current_price']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getChangeColor(changePercent).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  changePercent > 0 
                                      ? '+${changePercent.toStringAsFixed(1)}%'
                                      : changePercent < 0
                                          ? '${changePercent.toStringAsFixed(1)}%'
                                          : 'No Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getChangeColor(changePercent),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.notifications, color: primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, size: 32, color: Colors.green),
                          SizedBox(height: 8),
                          Text(
                            'No new notifications',
                            style: TextStyle(color: textLight),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _notifications.take(3).length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info,
                              color: primaryBlue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(notification['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textLight,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    notification['message'] ?? 'No message',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedDataSection() {
    return Container(
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.data_usage, color: primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Loaded Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Profile Display
                if (_profile.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              'Profile: ${_profile['first_name'] ?? 'Unknown'} ${_profile['last_name'] ?? ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        if (_profile['email'] != null) ...[
                          SizedBox(height: 4),
                          Text('Email: ${_profile['email']}'),
                        ],
                        if (_profile['phone'] != null) ...[
                          SizedBox(height: 4),
                          Text('Phone: ${_profile['phone']}'),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                
                // Products Display
                if (_products.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: successGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2, color: successGreen),
                            SizedBox(width: 8),
                            Text(
                              'Products (${_products.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: successGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ..._products.take(3).map((product) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('• ${product['product_name'] ?? 'Unknown Product'}'),
                              Spacer(),
                              Text('₱${product['price'] ?? '0'}'),
                            ],
                          ),
                        )),
                        if (_products.length > 3)
                          Text('... and ${_products.length - 3} more'),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                
                // Complaints Display
                if (_complaints.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dangerRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: dangerRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.report_problem, color: dangerRed),
                            SizedBox(width: 8),
                            Text(
                              'Complaints (${_complaints.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dangerRed,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ..._complaints.take(3).map((complaint) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text('• ${complaint['issue_description'] ?? 'No description'} - ${complaint['complaint_status'] ?? 'Unknown'}'),
                        )),
                        if (_complaints.length > 3)
                          Text('... and ${_complaints.length - 3} more'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: bgWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications ($_notificationCount)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(color: textLight),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryBlue.withOpacity(0.1),
                            child: Icon(
                              Icons.notifications,
                              color: primaryBlue,
                              size: 20,
                            ),
                          ),
                          title: Text(notification['message'] ?? ''),
                          subtitle: Text(
                            _formatDate(notification['created_at']),
                            style: TextStyle(color: textLight),
                          ),
                          trailing: notification['is_read'] == 0
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
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

  void _navigateToBrowseProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to Browse Products')),
    );
  }

  void _navigateToFileComplaint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to File Complaint')),
    );
  }

  void _navigateToProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to Profile')),
    );
  }

  void _showGuideTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Guide & Tips'),
        content: Text('Here are some helpful tips for using the DTI Consumer app...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getChangeColor(double changePercent) {
    if (changePercent > 0) {
      return Colors.red; // Price increase
    } else if (changePercent < 0) {
      return Colors.green; // Price decrease
    } else {
      return Colors.grey; // No change
    }
  }
}