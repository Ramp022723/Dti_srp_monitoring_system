import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../consumer/consumer_dashboard.dart';
import '../retailer/retailer_dashboard.dart';

class DashboardService {
  // Route to appropriate dashboard based on user role
  static Widget getDashboardByRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminDashboard();
      case 'consumer':
        return const ConsumerDashboard();
      case 'retailer':
        return const RetailerDashboard();
      default:
        // Fallback to consumer dashboard or show error
        return const ConsumerDashboard();
    }
  }

  // Navigate to appropriate dashboard after login
  static void navigateToDashboard(BuildContext context, String role) {
    print('🧭 DashboardService: Navigating to dashboard for role: $role');
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => getDashboardByRole(role),
        ),
      );
      print('✅ DashboardService: Navigation successful');
    } catch (e) {
      print('❌ DashboardService: Navigation failed: $e');
    }
  }

  // Check if user should be redirected to dashboard
  static Future<void> checkAndRedirect(BuildContext context) async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final role = await AuthService.getUserRole();
      if (role != null) {
        navigateToDashboard(context, role);
      }
    }
  }

  // ================= DASHBOARD DATA LOADING =================
  
  // Load dashboard data for a specific role
  static Future<Map<String, dynamic>> loadDashboardData(String role) async {
    try {
      print('🔄 DashboardService: Loading dashboard data for role: $role');
      final data = await AuthService.loadDashboardDataByRole(role);
      print('✅ DashboardService: Dashboard data loaded successfully');
      return data;
    } catch (e) {
      print('❌ DashboardService: Failed to load dashboard data: $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  // Load admin dashboard data
  static Future<Map<String, dynamic>> loadAdminDashboardData() async {
    return await AuthService.loadAdminDashboard();
  }

  // Load consumer dashboard data
  static Future<Map<String, dynamic>> loadConsumerDashboardData() async {
    return await AuthService.loadConsumerDashboard();
  }

  // Load retailer dashboard data
  static Future<Map<String, dynamic>> loadRetailerDashboardData() async {
    return await AuthService.loadRetailerDashboard();
  }

  // Refresh dashboard data for a specific role
  static Future<Map<String, dynamic>> refreshDashboardData(String role) async {
    return await AuthService.refreshDashboardData(role);
  }

  // Check API health for all dashboard endpoints
  static Future<Map<String, dynamic>> checkDashboardApiHealth() async {
    return await AuthService.checkDashboardApiHealth();
  }
}
