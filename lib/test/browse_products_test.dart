import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../widgets/browse_products_widget.dart';

void main() {
  group('BrowseProductsWidget Tests', () {
    testWidgets('BrowseProductsWidget should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrowseProductsWidget(),
          ),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('BrowseProductsWidget should have search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrowseProductsWidget(),
          ),
        ),
      );

      // Should have search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products...'), findsOneWidget);
    });

    testWidgets('BrowseProductsWidget should have filter section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrowseProductsWidget(),
          ),
        ),
      );

      // Wait for the widget to load
      await tester.pumpAndSettle();

      // Should have filter section with category filter
      expect(find.text('All Categories'), findsOneWidget);
    });

    testWidgets('BrowseProductsWidget should have browse products title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrowseProductsWidget(),
          ),
        ),
      );

      // Should have title
      expect(find.text('Browse Products'), findsOneWidget);
      expect(find.text('Discover products and compare prices from local retailers'), findsOneWidget);
    });
  });
}
