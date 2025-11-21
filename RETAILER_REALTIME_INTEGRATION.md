# Retailer Store Management - Real-time Data Integration

This document explains the real-time data integration for the Retailer Store Management system, which now supports live data updates from both API website and mobile sources.

## 🚀 Features

### Real-time Data Capabilities
- **Live Data Streaming**: Continuous updates from API and mobile sources
- **WebSocket Support**: Real-time bidirectional communication (when available)
- **Polling Fallback**: Automatic fallback to HTTP polling when WebSocket is unavailable
- **Connection Monitoring**: Visual indicators for connection status
- **Auto-reconnection**: Automatic reconnection with exponential backoff
- **Data Caching**: Local caching for offline capability

### Real-time Metrics
- **Online Stores**: Live count of active retailer stores
- **Price Updates**: Real-time price change notifications
- **New Violations**: Instant violation alerts
- **Connection Status**: Live/Offline indicators
- **Last Update Time**: Timestamp of last data refresh

## 📁 File Structure

```
lib/
├── services/
│   └── retailer_realtime_service.dart     # Core real-time service
├── admin/
│   ├── retailer_store_management_page.dart # Enhanced UI with real-time features
│   └── retailer_store_management.dart     # Management module with real-time integration
└── models/
    └── retailer_model.dart                # Data models for retailer entities
```

## 🔧 Implementation Details

### 1. RetailerRealtimeService

The core service that handles all real-time functionality:

```dart
// Initialize the service
final realtimeService = RetailerRealtimeService();
await realtimeService.initialize();

// Subscribe to data streams
realtimeService.productsStream.listen((products) {
  // Handle real-time product updates
});

realtimeService.retailersStream.listen((retailers) {
  // Handle real-time retailer updates
});

realtimeService.violationsStream.listen((violations) {
  // Handle real-time violation alerts
});
```

### 2. Connection Management

The service automatically handles:
- **WebSocket Connection**: Primary connection method
- **HTTP Polling**: Fallback when WebSocket fails
- **Heartbeat Monitoring**: Maintains connection health
- **Auto-reconnection**: Reconnects on connection loss

### 3. Data Streams

Available real-time data streams:
- `productsStream`: Live retailer product updates
- `retailersStream`: Real-time retailer information
- `violationsStream`: Instant violation alerts
- `statsStream`: Live statistics updates
- `realtimeMetricsStream`: Real-time performance metrics

## 🎨 UI Components

### Real-time Status Indicators

The UI includes several real-time indicators:

1. **Connection Status**: Green/red dot with WiFi icon
2. **Last Update Time**: Shows time since last data refresh
3. **Live Metrics Section**: Real-time performance metrics
4. **Connection Badge**: "LIVE" or "OFFLINE" status

### Enhanced App Bar

```dart
// Real-time status indicator in app bar
Widget _buildRealtimeStatusIndicator() {
  return Container(
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRealtimeConnected ? Colors.green : Colors.red,
          ),
        ),
        Icon(
          _isRealtimeConnected ? Icons.wifi : Icons.wifi_off,
          color: Colors.white,
          size: 16,
        ),
      ],
    ),
  );
}
```

## 📊 Real-time Metrics

The system displays live metrics including:

- **Online Stores**: Number of currently active stores
- **Price Updates**: Count of recent price changes
- **New Violations**: Number of new violation alerts
- **Connection Quality**: Real-time connection status

## 🔄 Data Flow

```
API/Mobile Sources → RetailerRealtimeService → Stream Controllers → UI Components
                                    ↓
                            Local Cache (for offline)
```

### Data Update Process

1. **Data Collection**: Service fetches data from API endpoints
2. **Stream Broadcasting**: Updates are broadcast to all subscribers
3. **UI Updates**: Components automatically update with new data
4. **Cache Update**: Local cache is updated for offline access

## 🛠️ Configuration

### API Endpoints

The service connects to these endpoints:
- Base URL: `https://dtisrpmonitoring.bccbsis.com/api`
- Products: `/admin/store_prices.php?action=get_retailer_products`
- Retailers: `/admin/store_prices.php?action=get_retailers`
- Violations: `/admin/store_prices.php?action=get_violation_alerts`
- Stats: `/admin/store_prices.php?action=get_retailer_stats`
- Metrics: `/admin/store_prices.php?action=get_realtime_metrics`

### Polling Configuration

```dart
static const Duration _pollingInterval = Duration(seconds: 10);
static const Duration _heartbeatInterval = Duration(seconds: 30);
static const Duration _reconnectDelay = Duration(seconds: 5);
static const int _maxReconnectAttempts = 5;
```

## 🚀 Usage Examples

### Basic Initialization

```dart
class MyRetailerPage extends StatefulWidget {
  @override
  _MyRetailerPageState createState() => _MyRetailerPageState();
}

class _MyRetailerPageState extends State<MyRetailerPage> {
  final RetailerRealtimeService _realtimeService = RetailerRealtimeService();
  
  @override
  void initState() {
    super.initState();
    _initializeRealtime();
  }
  
  Future<void> _initializeRealtime() async {
    await _realtimeService.initialize();
    
    // Subscribe to real-time updates
    _realtimeService.productsStream.listen((products) {
      setState(() {
        // Update UI with new products
      });
    });
  }
}
```

### Manual Data Refresh

```dart
Future<void> _refreshData() async {
  await _realtimeService.refreshData();
  // UI will automatically update via streams
}
```

### Connection Status Monitoring

```dart
bool get isConnected => _realtimeService.isConnected;
bool get isPolling => _realtimeService.isPolling;
DateTime? get lastUpdate => _realtimeService.lastUpdate;
```

## 🔧 Troubleshooting

### Common Issues

1. **Connection Failures**
   - Check network connectivity
   - Verify API endpoint availability
   - Review server logs for errors

2. **Data Not Updating**
   - Ensure stream subscriptions are active
   - Check for JavaScript errors in console
   - Verify API response format

3. **Performance Issues**
   - Adjust polling intervals
   - Implement data pagination
   - Use data filtering to reduce payload

### Debug Information

Enable debug logging by checking console output:
- `🔄` - Initialization and connection attempts
- `✅` - Successful operations
- `❌` - Errors and failures
- `📊` - Data updates and metrics

## 🔮 Future Enhancements

### Planned Features

1. **WebSocket Implementation**: Full WebSocket support for real-time communication
2. **Push Notifications**: Mobile push notifications for critical updates
3. **Data Synchronization**: Conflict resolution for concurrent updates
4. **Performance Analytics**: Detailed performance metrics and monitoring
5. **Offline Support**: Enhanced offline capabilities with data synchronization

### API Enhancements

1. **GraphQL Support**: More efficient data fetching
2. **Real-time Subscriptions**: Server-sent events for instant updates
3. **Data Compression**: Reduced bandwidth usage
4. **Caching Headers**: Better HTTP caching support

## 📝 Notes

- The service automatically falls back to polling if WebSocket is unavailable
- All data is cached locally for offline access
- Connection status is monitored continuously
- Automatic reconnection attempts with exponential backoff
- Real-time metrics are updated every 10 seconds by default

## 🤝 Contributing

When adding new real-time features:

1. Update the `RetailerRealtimeService` with new endpoints
2. Add corresponding UI components for new metrics
3. Update this documentation
4. Test both online and offline scenarios
5. Ensure proper error handling and fallbacks
