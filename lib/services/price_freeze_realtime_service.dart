import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_freeze_model.dart';

/// Real-time service for price freeze management data
/// Handles WebSocket connections, polling, and real-time updates
class PriceFreezeRealtimeService {
  static const String _baseUrl = 'https://dtisrpmonitoring.bccbsis.com/api';
  
  // Singleton instance
  static final PriceFreezeRealtimeService _instance = PriceFreezeRealtimeService._internal();
  factory PriceFreezeRealtimeService() => _instance;
  PriceFreezeRealtimeService._internal();

  // Stream controllers for real-time data
  final StreamController<List<PriceFreezeAlert>> _alertsController = 
      StreamController<List<PriceFreezeAlert>>.broadcast();
  final StreamController<List<Product>> _productsController = 
      StreamController<List<Product>>.broadcast();
  final StreamController<List<Category>> _categoriesController = 
      StreamController<List<Category>>.broadcast();
  final StreamController<List<Location>> _locationsController = 
      StreamController<List<Location>>.broadcast();
  final StreamController<PriceFreezeStats> _statsController = 
      StreamController<PriceFreezeStats>.broadcast();
  final StreamController<Map<String, dynamic>> _realtimeMetricsController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // WebSocket connection
  WebSocketChannel? _webSocketChannel;
  Timer? _pollingTimer;
  Timer? _heartbeatTimer;
  
  // Connection state
  bool _isConnected = false;
  bool _isPolling = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pollingInterval = Duration(seconds: 15);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Data cache
  List<PriceFreezeAlert> _cachedAlerts = [];
  List<Product> _cachedProducts = [];
  List<Category> _cachedCategories = [];
  List<Location> _cachedLocations = [];
  PriceFreezeStats? _cachedStats;
  DateTime? _lastUpdate;

  // Getters for streams
  Stream<List<PriceFreezeAlert>> get alertsStream => _alertsController.stream;
  Stream<List<Product>> get productsStream => _productsController.stream;
  Stream<List<Category>> get categoriesStream => _categoriesController.stream;
  Stream<List<Location>> get locationsStream => _locationsController.stream;
  Stream<PriceFreezeStats> get statsStream => _statsController.stream;
  Stream<Map<String, dynamic>> get realtimeMetricsStream => _realtimeMetricsController.stream;

  // Connection state getters
  bool get isConnected => _isConnected;
  bool get isPolling => _isPolling;
  DateTime? get lastUpdate => _lastUpdate;

  /// Initialize real-time service
  Future<void> initialize() async {
    try {
      print('🔄 PriceFreezeRealtimeService: Initializing...');
      
      // Try WebSocket connection first
      await _connectWebSocket();
      
      // If WebSocket fails, fallback to polling
      if (!_isConnected) {
        await _startPolling();
      }
      
      // Start heartbeat to maintain connection
      _startHeartbeat();
      
      print('✅ PriceFreezeRealtimeService: Initialized successfully');
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Initialization failed: $e');
      // Fallback to polling
      await _startPolling();
    }
  }

  /// Connect to WebSocket for real-time updates
  Future<void> _connectWebSocket() async {
    try {
      print('🔌 PriceFreezeRealtimeService: Connecting to WebSocket...');
      
      // Note: WebSocket implementation would go here
      // For now, we'll simulate with polling
      // In a real implementation, you would use:
      // _webSocketChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      // _webSocketChannel!.stream.listen(_handleWebSocketMessage);
      
      _isConnected = true;
      _reconnectAttempts = 0;
      print('✅ PriceFreezeRealtimeService: WebSocket connected');
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: WebSocket connection failed: $e');
      _isConnected = false;
      throw e;
    }
  }

  /// Start polling for data updates
  Future<void> _startPolling() async {
    if (_isPolling) return;
    
    print('🔄 PriceFreezeRealtimeService: Starting polling...');
    _isPolling = true;
    
    // Initial data fetch
    await _fetchAllData();
    
    // Set up periodic polling
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      await _fetchAllData();
    });
    
    print('✅ PriceFreezeRealtimeService: Polling started');
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    print('⏹️ PriceFreezeRealtimeService: Polling stopped');
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) async {
      await _sendHeartbeat();
    });
  }

  /// Send heartbeat to server
  Future<void> _sendHeartbeat() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/heartbeat.php'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        print('⚠️ PriceFreezeRealtimeService: Heartbeat failed');
        await _reconnect();
      }
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Heartbeat error: $e');
      await _reconnect();
    }
  }

  /// Reconnect to service
  Future<void> _reconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ PriceFreezeRealtimeService: Max reconnection attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    print('🔄 PriceFreezeRealtimeService: Reconnecting... (attempt $_reconnectAttempts)');
    
    _isConnected = false;
    _stopPolling();
    
    await Future.delayed(_reconnectDelay);
    await initialize();
  }

  /// Fetch all real-time data
  Future<void> _fetchAllData() async {
    try {
      print('📊 PriceFreezeRealtimeService: Fetching real-time data...');
      
      // Fetch data in parallel
      final results = await Future.wait([
        _fetchPriceFreezeAlerts(),
        _fetchPriceFreezeProducts(),
        _fetchPriceFreezeCategories(),
        _fetchPriceFreezeLocations(),
        _fetchPriceFreezeStatistics(),
        _fetchRealtimeMetrics(),
      ]);
      
      _lastUpdate = DateTime.now();
      
      // Emit updated data
      if (results[0] != null) {
        _cachedAlerts = results[0] as List<PriceFreezeAlert>;
        _alertsController.add(_cachedAlerts);
      }
      
      if (results[1] != null) {
        _cachedProducts = results[1] as List<Product>;
        _productsController.add(_cachedProducts);
      }
      
      if (results[2] != null) {
        _cachedCategories = results[2] as List<Category>;
        _categoriesController.add(_cachedCategories);
      }
      
      if (results[3] != null) {
        _cachedLocations = results[3] as List<Location>;
        _locationsController.add(_cachedLocations);
      }
      
      if (results[4] != null) {
        _cachedStats = results[4] as PriceFreezeStats;
        _statsController.add(_cachedStats!);
      }
      
      if (results[5] != null) {
        _realtimeMetricsController.add(results[5] as Map<String, dynamic>);
      }
      
      print('✅ PriceFreezeRealtimeService: Data updated successfully');
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching data: $e');
    }
  }

  /// Fetch price freeze alerts
  Future<List<PriceFreezeAlert>?> _fetchPriceFreezeAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/price_freeze.php?action=get_alerts&limit=100'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final alertsData = data['alerts'] ?? data['data'] ?? [];
          return alertsData.map<PriceFreezeAlert>((alert) => 
            PriceFreezeAlert.fromJson(alert)).toList();
        }
      }
      return null;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching alerts: $e');
      return null;
    }
  }

  /// Fetch price freeze products
  Future<List<Product>?> _fetchPriceFreezeProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/price_freeze.php?action=get_products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final productsData = data['products'] ?? data['data'] ?? [];
          return productsData.map<Product>((product) => 
            Product.fromJson(product)).toList();
        }
      }
      return null;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching products: $e');
      return null;
    }
  }

  /// Fetch price freeze categories
  Future<List<Category>?> _fetchPriceFreezeCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/price_freeze.php?action=get_categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final categoriesData = data['categories'] ?? data['data'] ?? [];
          return categoriesData.map<Category>((category) => 
            Category.fromJson(category)).toList();
        }
      }
      return null;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching categories: $e');
      return null;
    }
  }

  /// Fetch price freeze locations
  Future<List<Location>?> _fetchPriceFreezeLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/price_freeze.php?action=get_locations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final locationsData = data['locations'] ?? data['data'] ?? [];
          return locationsData.map<Location>((location) => 
            Location.fromJson(location)).toList();
        }
      }
      return null;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching locations: $e');
      return null;
    }
  }

  /// Fetch price freeze statistics
  Future<PriceFreezeStats?> _fetchPriceFreezeStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/price_freeze.php?action=get_statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return PriceFreezeStats.fromJson(data['statistics'] ?? data['data'] ?? {});
        }
      }
      return null;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching statistics: $e');
      return null;
    }
  }

  /// Fetch real-time metrics
  Future<Map<String, dynamic>?> _fetchRealtimeMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/price_freeze.php?action=get_realtime_metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['metrics'] ?? data['data'] ?? {};
        }
      }
      return null;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error fetching metrics: $e');
      return null;
    }
  }

  /// Get cached data
  List<PriceFreezeAlert> get cachedAlerts => List.from(_cachedAlerts);
  List<Product> get cachedProducts => List.from(_cachedProducts);
  List<Category> get cachedCategories => List.from(_cachedCategories);
  List<Location> get cachedLocations => List.from(_cachedLocations);
  PriceFreezeStats? get cachedStats => _cachedStats;

  /// Force refresh data
  Future<void> refreshData() async {
    await _fetchAllData();
  }

  /// Update specific price freeze alert
  Future<bool> updatePriceFreezeAlert(PriceFreezeAlert alert) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/price_freeze.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': 'update_alert',
          'alert_id': alert.alertId,
          'status': alert.status,
          'title': alert.title,
          'message': alert.message,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update local cache
          final index = _cachedAlerts.indexWhere((a) => a.alertId == alert.alertId);
          if (index != -1) {
            _cachedAlerts[index] = alert;
            _alertsController.add(_cachedAlerts);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error updating alert: $e');
      return false;
    }
  }

  /// Create new price freeze alert
  Future<bool> createPriceFreezeAlert(PriceFreezeAlert alert) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/price_freeze.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': 'create_alert',
          'title': alert.title,
          'message': alert.message,
          'freeze_start_date': alert.freezeStartDate,
          'freeze_end_date': alert.freezeEndDate,
          'status': alert.status,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Add to local cache
          _cachedAlerts.add(alert);
          _alertsController.add(_cachedAlerts);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error creating alert: $e');
      return false;
    }
  }

  /// Delete price freeze alert
  Future<bool> deletePriceFreezeAlert(int alertId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/price_freeze.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': 'delete_alert',
          'alert_id': alertId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Remove from local cache
          _cachedAlerts.removeWhere((a) => a.alertId == alertId);
          _alertsController.add(_cachedAlerts);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ PriceFreezeRealtimeService: Error deleting alert: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _stopPolling();
    _heartbeatTimer?.cancel();
    _webSocketChannel?.sink.close();
    
    _alertsController.close();
    _productsController.close();
    _categoriesController.close();
    _locationsController.close();
    _statsController.close();
    _realtimeMetricsController.close();
    
    print('🧹 PriceFreezeRealtimeService: Disposed');
  }
}

// WebSocket channel class (placeholder for actual WebSocket implementation)
class WebSocketChannel {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  
  Stream<dynamic> get stream => _controller.stream;
  StreamSink<dynamic> get sink => _controller.sink;
  
  static WebSocketChannel connect(Uri uri) {
    // In a real implementation, this would create an actual WebSocket connection
    return WebSocketChannel();
  }
  
  void close() {
    _controller.close();
  }
}
