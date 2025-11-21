import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_realtime_service.dart';
import '../services/auth_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Real-time service
  final NotificationRealtimeService _realtimeService = NotificationRealtimeService();
  
  // Stream subscriptions
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<NotificationStats>? _statsSubscription;
  StreamSubscription<Map<String, dynamic>>? _metricsSubscription;

  // Data
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  NotificationStats? _stats;
  Map<String, dynamic> _realtimeMetrics = {};
  
  // UI state
  bool _isLoading = true;
  bool _isRealtimeConnected = false;
  String? _error;
  DateTime? _lastDataUpdate;
  Timer? _connectionStatusTimer;
  
  // Filters and search
  String _searchQuery = '';
  String _selectedType = 'all';
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  bool _isGridView = false;

  // Filter options
  final List<String> _typeOptions = ['all', 'alert', 'info', 'success', 'error', 'price_freeze', 'complaint', 'system'];
  final List<String> _statusOptions = ['all', 'unread', 'read'];
  final List<String> _priorityOptions = ['all', 'high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRealtimeService();
  }

  @override
  void dispose() {
    _connectionStatusTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _notificationsSubscription?.cancel();
    _statsSubscription?.cancel();
    _metricsSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  /// Initialize animations
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

  /// Update connection status
  void _updateConnectionStatus() {
    if (mounted) {
      final isConnected = _realtimeService.isConnected || _realtimeService.isPolling;
      if (_isRealtimeConnected != isConnected) {
        setState(() {
          _isRealtimeConnected = isConnected;
        });
      }
    }
  }

  /// Initialize real-time service and set up data streams
  Future<void> _initializeRealtimeService() async {
    try {
      print('🔄 Initializing notifications real-time service...');
      
      // Set up stream subscriptions first
      _notificationsSubscription = _realtimeService.notificationsStream.listen(
        (notifications) {
          if (mounted) {
            setState(() {
              _notifications = notifications;
              _filteredNotifications = List.from(_notifications);
              _lastDataUpdate = DateTime.now();
              _isLoading = false;
              // Update connection status when data is received
              _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
            });
            _fadeController.forward();
            _slideController.forward();
          }
        },
        onError: (error) {
          print('❌ Notifications stream error: $error');
          if (mounted) {
            setState(() {
              _error = 'Real-time connection error: $error';
              _isLoading = false;
              // Update connection status on error
              _updateConnectionStatus();
            });
          }
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
              // Update connection status when metrics are received
              _isRealtimeConnected = _realtimeService.isConnected || _realtimeService.isPolling;
            });
          }
        },
        onError: (error) {
          print('❌ Metrics stream error: $error');
        },
      );
      
      // Initialize the real-time service
      await _realtimeService.initialize();
      
      // Update connection status immediately
      _updateConnectionStatus();
      
      // Start periodic connection status updates
      _connectionStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          _updateConnectionStatus();
        }
      });
      
      // If no data is loaded after a delay, show error message
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _notifications.isEmpty && _isLoading) {
          print('⚠️ No data received from real-time service');
          setState(() {
            _isLoading = false;
            _updateConnectionStatus();
            if (!_isRealtimeConnected) {
              _error = 'Unable to load notifications. Please check your connection and try again.';
            }
          });
        }
      });
      
      print('✅ Notifications real-time service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize notifications real-time service: $e');
      setState(() {
        _isRealtimeConnected = false;
        _error = 'Failed to connect to real-time service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    // Use real-time service to refresh data
    await _realtimeService.refreshData();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F2937),
      title: Row(
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 8),
          _buildRealtimeStatusIndicator(),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter',
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
        PopupMenuButton<String>(
          onSelected: _handleNotificationAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read, size: 20),
                  SizedBox(width: 8),
                  Text('Mark All Read'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRealtimeStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isRealtimeConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRealtimeConnected ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isRealtimeConnected ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            _isRealtimeConnected ? Icons.wifi : Icons.wifi_off,
            size: 12,
            color: _isRealtimeConnected ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            _isRealtimeConnected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _isRealtimeConnected ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading notifications...'),
          ],
        ),
      );
    }

    if (_error != null && _notifications.isEmpty) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            if (_error != null) _buildErrorBanner(),
            _buildMobileStatistics(),
            _buildSearchAndFilterBar(),
            Expanded(child: _buildMobileContent()),
          ],
        ),
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
              Icons.notifications_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _loadNotifications();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unable to load notifications. Please check your connection and try again.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatistics() {
    if (_stats == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _stats!.total.toString(),
                  Icons.notifications,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Unread',
                  _stats!.unread.toString(),
                  Icons.mark_email_unread,
                  const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'High Priority',
                  _stats!.highPriority.toString(),
                  Icons.priority_high,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRealtimeMetricsSection(),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeMetricsSection() {
    if (_realtimeMetrics.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Text(
            'Last update: ${_lastDataUpdate != null ? _formatTime(_lastDataUpdate!) : 'Never'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterNotifications();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
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
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];
        return _buildMobileNotificationCard(notification);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobileNotificationCard(notification),
        );
      },
    );
  }

  Widget _buildMobileNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: notification.isUnread 
            ? Border.all(color: const Color(0xFF3B82F6), width: 2)
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.typeIcon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: notification.isUnread 
                            ? const Color(0xFF1F2937) 
                            : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(notification.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(notification.priority),
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleNotificationAction(action, notification),
                  itemBuilder: (context) => [
                    if (notification.isUnread)
                      const PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_read, size: 16),
                            SizedBox(width: 8),
                            Text('Mark as Read'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
      case 'warning':
        return const Color(0xFFEF4444);
      case 'info':
      case 'information':
        return const Color(0xFF3B82F6);
      case 'success':
        return const Color(0xFF10B981);
      case 'error':
        return const Color(0xFFEF4444);
      case 'price_freeze':
        return const Color(0xFF8B5CF6);
      case 'complaint':
        return const Color(0xFFF59E0B);
      case 'system':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _filterNotifications() {
    setState(() {
      _filteredNotifications = _notifications.where((notification) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!notification.title.toLowerCase().contains(query) &&
              !notification.message.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // Type filter
        if (_selectedType != 'all' && notification.type != _selectedType) {
          return false;
        }
        
        // Status filter
        if (_selectedStatus != 'all') {
          if (_selectedStatus == 'unread' && notification.isRead) return false;
          if (_selectedStatus == 'read' && notification.isUnread) return false;
        }
        
        // Priority filter
        if (_selectedPriority != 'all' && notification.priority != _selectedPriority) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _typeOptions.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.toUpperCase()),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statusOptions.map((status) => DropdownMenuItem(
                value: status,
                child: Text(status.toUpperCase()),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: _priorityOptions.map((priority) => DropdownMenuItem(
                value: priority,
                child: Text(priority.toUpperCase()),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value ?? 'all';
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _filterNotifications();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    if (notification.isUnread) {
      _realtimeService.markAsRead(notification.id);
    }
    
    // Show notification details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDateTime(notification.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              if (notification.readAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Read: ${_formatDateTime(notification.readAt!)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
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

  void _handleNotificationAction(String action, [NotificationModel? notification]) {
    switch (action) {
      case 'mark_read':
        if (notification != null) {
          _realtimeService.markAsRead(notification.id);
        }
        break;
      case 'mark_all_read':
        _realtimeService.markAllAsRead();
        break;
      case 'refresh':
        _loadNotifications();
        break;
      case 'view':
        if (notification != null) {
          _onNotificationTap(notification);
        }
        break;
    }
  }

  String _formatTime(DateTime dateTime) {
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
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
