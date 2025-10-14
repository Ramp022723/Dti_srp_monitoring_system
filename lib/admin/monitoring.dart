import 'package:flutter/material.dart';
import '../screens/monitoring/monitoring_screen.dart';
import '../screens/monitoring/form_details_screen.dart';

/// Monitoring Module - Integrates price and supply monitoring functionality
/// This module is part of the Admin and Retailer Store Management features
class MonitoringModule {
  /// Navigate to Monitoring Dashboard
  static void navigateToMonitoring(BuildContext context) {
    Navigator.pushNamed(context, '/monitoring');
  }

  /// Navigate to Monitoring Forms List
  static void navigateToMonitoringForms(BuildContext context) {
    Navigator.pushNamed(context, '/monitoring/forms');
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
class MonitoringDashboard extends StatelessWidget {
  const MonitoringDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MonitoringScreen();
  }
}

