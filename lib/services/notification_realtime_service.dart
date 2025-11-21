import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../models/notification_model.dart';

class NotificationRealtimeService {
  static final NotificationRealtimeService _instance = NotificationRealtimeService._internal();
  factory NotificationRealtimeService() => _instance;
  NotificationRealtimeService._internal();

  // Stream controllers
  final StreamController<List<NotificationModel>> _notificationsController = StreamController<List<NotificationModel>>.broadcast();
  final StreamController<NotificationStats> _statsController = StreamController<NotificationStats>.broadcast();
  final StreamController<Map<String, dynamic>> _realtimeMetricsController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;
  Stream<NotificationStats> get statsStream => _statsController.stream;
  Stream<Map<String, dynamic>> get realtimeMetricsStream => _realtimeMetricsController.stream;

  // Connection state
  bool _isConnected = false;
  bool _isPolling = false;
  Timer? _pollingTimer;
  Timer? _heartbeatTimer;
  WebSocket? _webSocket;

  // Cached data
  List<NotificationModel> _cachedNotifications = [];
  NotificationStats? _cachedStats;
  Map<String, dynamic> _realtimeMetrics = {};
  DateTime? _lastUpdate;

  // Connection state getters
  bool get isConnected => _isConnected;
  bool get isPolling => _isPolling;
  DateTime? get lastUpdate => _lastUpdate;

  /// Initialize real-time service
  Future<void> initialize() async {
    try {
      print('🔄 NotificationRealtimeService: Initializing...');
      
      // Try WebSocket connection first
      await _connectWebSocket();
      
      // If WebSocket fails, fallback to polling
      if (!_isConnected) {
        await _startPolling();
      }
      
      // Start heartbeat to maintain connection
      _startHeartbeat();
      
      // Force initial data fetch
      await _fetchAllData();
      
      print('✅ NotificationRealtimeService: Initialized successfully');
    } catch (e) {
      print('❌ NotificationRealtimeService: Initialization failed: $e');
      // Fallback to polling
      await _startPolling();
    }
  }

  /// Connect to WebSocket for real-time updates
  Future<void> _connectWebSocket() async {
    try {
      print('🔌 NotificationRealtimeService: Connecting to WebSocket...');
      
      // For now, we'll use polling as WebSocket endpoint might not be available
      // This is a placeholder for future WebSocket implementation
      _isConnected = false;
      
    } catch (e) {
      print('❌ NotificationRealtimeService: WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  /// Start polling for data updates
  Future<void> _startPolling() async {
    if (_isPolling) return;
    
    print('🔄 NotificationRealtimeService: Starting polling...');
    _isPolling = true;
    
    // Poll every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchAllData();
    });
    
    // Initial fetch
    await _fetchAllData();
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    print('⏹️ NotificationRealtimeService: Polling stopped');
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat to server
  void _sendHeartbeat() {
    if (_isConnected) {
      // Send WebSocket heartbeat
      _webSocket?.add(jsonEncode({'type': 'heartbeat', 'timestamp': DateTime.now().millisecondsSinceEpoch}));
    } else if (_isPolling) {
      // Verify polling is still working
      _fetchAllData();
    }
  }

  /// Reconnect to service
  Future<void> _reconnect() async {
    print('🔄 NotificationRealtimeService: Reconnecting...');
    
    // Stop current connections
    _webSocket?.close();
    _stopPolling();
    
    // Wait a bit before reconnecting
    await Future.delayed(const Duration(seconds: 2));
    
    // Try to reconnect
    await initialize();
  }

  /// Fetch all data from API
  Future<void> _fetchAllData() async {
    try {
      print('📊 NotificationRealtimeService: Fetching all data...');
      
      // Fetch notifications and stats in parallel
      await Future.wait([
        _fetchNotifications(),
        _fetchNotificationStats(),
        _fetchRealtimeMetrics(),
      ]);
      
      _lastUpdate = DateTime.now();
      
    } catch (e) {
      print('❌ NotificationRealtimeService: Error fetching data: $e');
    }
  }

  /// Fetch notifications data
  Future<void> _fetchNotifications() async {
    try {
      print('📊 NotificationRealtimeService: Fetching notifications data...');
      final result = await AuthService.getNotifications(
        page: 1,
        limit: 100,
        type: 'all',
        status: 'all',
      );
      
      print('📊 Notifications API Response: $result');
      
      if (result['status'] == 'success') {
        final apiData = result['data'] ?? {};
        final notificationsData = apiData['notifications'] ?? apiData['data'] ?? [];
        
        print('📊 Found ${notificationsData.length} notifications');
        
        // Convert to NotificationModel objects
        final notifications = notificationsData.map<NotificationModel>((notification) {
          return NotificationModel.fromJson(notification);
        }).toList();
        
        _cachedNotifications = notifications;
        _notificationsController.add(notifications);
      } else {
        print('❌ Notifications API returned error: ${result['message']}');
      }
    } catch (e) {
      print('❌ NotificationRealtimeService: Error fetching notifications: $e');
    }
  }

  /// Fetch notification statistics
  Future<void> _fetchNotificationStats() async {
    try {
      final result = await AuthService.getNotifications(
        page: 1,
        limit: 1,
        type: 'all',
        status: 'all',
      );
      
      if (result['status'] == 'success') {
        final apiData = result['data'] ?? {};
        final statsData = apiData['stats'] ?? {};
        
        final stats = NotificationStats.fromJson(statsData);
        _cachedStats = stats;
        _statsController.add(stats);
      }
    } catch (e) {
      print('❌ NotificationRealtimeService: Error fetching stats: $e');
    }
  }

  /// Fetch real-time metrics
  Future<void> _fetchRealtimeMetrics() async {
    try {
      final metrics = {
        'connection_status': _isConnected ? 'websocket' : (_isPolling ? 'polling' : 'disconnected'),
        'last_update': _lastUpdate?.toIso8601String(),
        'total_notifications': _cachedNotifications.length,
        'unread_count': _cachedNotifications.where((n) => n.isUnread).length,
        'high_priority_count': _cachedNotifications.where((n) => n.priority == 'high').length,
        'recent_activity': _cachedNotifications.take(5).map((n) => {
          'id': n.id,
          'title': n.title,
          'type': n.type,
          'time_ago': n.timeAgo,
        }).toList(),
      };
      
      _realtimeMetrics = metrics;
      _realtimeMetricsController.add(metrics);
    } catch (e) {
      print('❌ NotificationRealtimeService: Error fetching metrics: $e');
    }
  }

  /// Refresh data manually
  Future<void> refreshData() async {
    await _fetchAllData();
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final result = await AuthService.markNotificationRead(notificationId: notificationId);
      
      if (result['status'] == 'success') {
        // Update local cache
        final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _cachedNotifications[index];
          final updatedNotification = NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            priority: notification.priority,
            status: 'read',
            actionUrl: notification.actionUrl,
            metadata: notification.metadata,
            createdAt: notification.createdAt,
            readAt: DateTime.now(),
            senderId: notification.senderId,
            senderName: notification.senderName,
            recipientId: notification.recipientId,
            recipientName: notification.recipientName,
          );
          
          _cachedNotifications[index] = updatedNotification;
          _notificationsController.add(_cachedNotifications);
          
          // Update stats
          _fetchNotificationStats();
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ NotificationRealtimeService: Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final result = await AuthService.markAllNotificationsRead();
      
      if (result['status'] == 'success') {
        // Update local cache
        _cachedNotifications = _cachedNotifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            priority: notification.priority,
            status: 'read',
            actionUrl: notification.actionUrl,
            metadata: notification.metadata,
            createdAt: notification.createdAt,
            readAt: DateTime.now(),
            senderId: notification.senderId,
            senderName: notification.senderName,
            recipientId: notification.recipientId,
            recipientName: notification.recipientName,
          );
        }).toList();
        
        _notificationsController.add(_cachedNotifications);
        
        // Update stats
        _fetchNotificationStats();
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ NotificationRealtimeService: Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _webSocket?.close();
    _stopPolling();
    _heartbeatTimer?.cancel();
    _notificationsController.close();
    _statsController.close();
    _realtimeMetricsController.close();
  }
}
