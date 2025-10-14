import 'package:flutter/material.dart';
import '../screens/products/products_screen.dart';

/// Products Module - Integrates product price management functionality
/// This module is part of the Admin Product Management features
class ProductsModule {
  /// Navigate to Products Dashboard
  static void navigateToProducts(BuildContext context) {
    Navigator.pushNamed(context, '/products');
  }

  /// Navigate to Product Details
  static void navigateToProductDetails(BuildContext context, {required dynamic product}) {
    Navigator.pushNamed(
      context,
      '/products/details',
      arguments: product,
    );
  }

  /// Navigate to Create Product
  static void navigateToCreateProduct(BuildContext context) {
    Navigator.pushNamed(context, '/products/create');
  }

  /// Navigate to Analytics
  static void navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, '/products/analytics');
  }
}

/// Products Dashboard Widget for Admin
class ProductsDashboard extends StatelessWidget {
  const ProductsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductsScreen();
  }
}

