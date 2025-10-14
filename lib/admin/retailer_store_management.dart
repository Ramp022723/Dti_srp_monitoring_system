import 'package:flutter/material.dart';
import '../screens/retailers/retailer_store_screen.dart';

/// Retailer Store Management Module
/// This module integrates retailer store management functionality into the admin dashboard
class RetailerStoreManagement {
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
}

/// Retailer Store Management Widget for Admin
class RetailerStoreManagementWidget extends StatelessWidget {
  const RetailerStoreManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const RetailerStoreScreen();
  }
}

