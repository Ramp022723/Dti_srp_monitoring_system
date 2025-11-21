import 'package:flutter/material.dart';
import '../screens/retailers/retailer_store_screen.dart';
import '../services/retailer_realtime_service.dart';

/// Retailer Store Management Module
/// This module integrates retailer store management functionality into the admin dashboard
/// with real-time data capabilities
class RetailerStoreManagement {
  static final RetailerRealtimeService _realtimeService = RetailerRealtimeService();

  /// Initialize real-time service
  static Future<void> initialize() async {
    await _realtimeService.initialize();
  }

  /// Navigate to Retailer Store Management Dashboard
  static void navigateToRetailerStores(BuildContext context) {
    Navigator.pushNamed(context, '/retailers/stores');
  }

  /// Navigate to Retailer Details
  static void navigateToRetailerDetails(BuildContext context, {required dynamic retailer}) {
    Navigator.pushNamed(
      context,
      '/retailers/details',
      arguments: retailer,
    );
  }

  /// Navigate to Violation Alerts
  static void navigateToViolationAlerts(BuildContext context) {
    Navigator.pushNamed(context, '/retailers/violation-alerts');
  }

  /// Navigate to Analytics
  static void navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, '/retailers/analytics');
  }

  /// Get real-time service instance
  static RetailerRealtimeService get realtimeService => _realtimeService;

  /// Get real-time connection status
  static bool get isRealtimeConnected => _realtimeService.isConnected || _realtimeService.isPolling;

  /// Get last data update time
  static DateTime? get lastDataUpdate => _realtimeService.lastUpdate;

  /// Force refresh real-time data
  static Future<void> refreshData() async {
    await _realtimeService.refreshData();
  }

  /// Dispose real-time service
  static void dispose() {
    _realtimeService.dispose();
  }
}

/// Retailer Store Management Widget for Admin
class RetailerStoreManagementWidget extends StatelessWidget {
  const RetailerStoreManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const RetailerStoreScreen();
  }
}

