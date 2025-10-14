import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'retailer_notification_detail_page.dart';

class RetailerNotificationsPage extends StatefulWidget {
  const RetailerNotificationsPage({Key? key}) : super(key: key);

  @override
  State<RetailerNotificationsPage> createState() => _RetailerNotificationsPageState();
}

class _RetailerNotificationsPageState extends State<RetailerNotificationsPage> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String? _error;
  
  // Real-time update variables
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  bool _isMarkingAllRead = false;

  // Color scheme matching the PHP version
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF1D4ED8);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningOrange = Color(0xFFFD7E14);
  static const Color dangerRed = Color(0xFFDC3545);
  static const Color gray = Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  void _initializeData() {
    _loadNotifications();
  }

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadNotifications(showLoading: false);
    } catch (e) {
      print('Error refreshing notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await AuthService.loadRetailerNotifications();
      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _notifications = (data['notifications'] as List<dynamic>? ) ?? [];
          if (showLoading) _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load notifications';
          if (showLoading) _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        if (showLoading) _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead) return;
    
    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      final result = await AuthService.markAllRetailerNotificationsRead();
      
      if (result['status'] == 'success') {
        // Refresh data immediately after successful operation
        await _refreshData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to mark notifications as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notifications as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Navigate back to dashboard instead of login page
        Navigator.pushReplacementNamed(context, '/retailer-dashboard');
      },
      child: Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/retailer-dashboard');
            },
          ),
          actions: [
            IconButton(
              icon: _isRefreshing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
      floatingActionButton: _notifications.isNotEmpty && _notifications.any((n) => n['is_read'] == 0)
          ? FloatingActionButton.extended(
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
              icon: _isMarkingAllRead 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.done_all),
              label: Text(_isMarkingAllRead ? 'Marking...' : 'Mark All Read'),
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
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
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textLight),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! No new notifications.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final isRead = notification['is_read'] == 1;
          final message = notification['message'] ?? '';
          final createdAt = notification['created_at'] ?? '';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isRead ? bgWhite : lightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRead ? borderLight : primaryBlue.withOpacity(0.3),
                width: isRead ? 1 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRead ? gray.withOpacity(0.2) : primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications,
                  color: isRead ? gray : primaryBlue,
                  size: 24,
                ),
              ),
              title: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  color: isRead ? textLight : textDark,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatDateTime(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textLight,
                  ),
                ),
              ),
              trailing: isRead
                  ? null
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RetailerNotificationDetailPage(
                      notification: notification,
                    ),
                  ),
                ).then((_) {
                  // Refresh notifications after returning
                  _refreshData();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
