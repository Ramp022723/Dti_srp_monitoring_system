import 'package:flutter/material.dart';
import 'monitoring_page_table.dart';
import '../screens/monitoring/form_details_screen.dart';

/// Monitoring Module - Integrates price and supply monitoring functionality
/// This module is part of the Admin and Retailer Store Management features
/// Uses product_monitoring_api.php for data
class MonitoringModule {
  /// Navigate to Monitoring Dashboard (Table View)
  static void navigateToMonitoring(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonitoringPageTable(),
      ),
    );
  }

  /// Navigate to Monitoring Forms List (Table View)
  static void navigateToMonitoringForms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonitoringPageTable(),
      ),
    );
  }

  /// Navigate to Create Monitoring Form
  static void navigateToCreateForm(BuildContext context) {
    Navigator.pushNamed(context, '/monitoring/create-form');
  }

  /// Navigate to Form Details
  static void navigateToFormDetails(BuildContext context, {required dynamic form}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormDetailsScreen(form: form),
      ),
    );
  }
}

/// Monitoring Dashboard Widget for Admin
/// Displays monitoring forms in table format from product_monitoring_api.php
class MonitoringDashboard extends StatelessWidget {
  const MonitoringDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MonitoringPageTable();
  }
}

