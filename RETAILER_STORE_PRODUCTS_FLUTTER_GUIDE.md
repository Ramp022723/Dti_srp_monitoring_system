# Retailer Store Products Flutter Page - Implementation Guide

This document explains the Flutter implementation of the retailer store products page, which is a mobile version of the PHP `product_list_retailer.php` frontend.

## 📱 **Overview**

The `RetailerStoreProductsPage` is a comprehensive Flutter page that replicates all the functionality of the PHP version, including:

- ✅ **Store Products Management** - View, add, and remove products from retailer's store
- ✅ **SRP Compliance Monitoring** - Visual indicators for price violations
- ✅ **Product Information Display** - Complete product details with images
- ✅ **Feedback Reports Section** - Admin feedback on SRP violations
- ✅ **Add Product Modal** - Easy product selection and addition
- ✅ **Violation Status Indicators** - Color-coded compliance status
- ✅ **Price Deviation Tracking** - Percentage above/below SRP
- ✅ **Responsive Design** - Mobile-optimized layout

## 🎨 **Design Features**

### **Color Scheme**
Matches the PHP version's Bootstrap theme:
```dart
static const Color primaryBlue = Color(0xFF2563EB);
static const Color successGreen = Color(0xFF28A745);
static const Color dangerRed = Color(0xFFDC3545);
static const Color warningOrange = Color(0xFFFD7E14);
static const Color infoCyan = Color(0xFF17A2B8);
```

### **Violation Status Colors**
- **Critical Violation**: Red (`#DC3545`) - Price > 110% of SRP
- **Minor Violation**: Orange (`#FD7E14`) - Price > SRP
- **Below SRP**: Green (`#28A745`) - Price < 80% of SRP
- **Compliant**: Gray (`#6C757D`) - Price within acceptable range

## 🔧 **API Integration**

### **AuthService Methods Used**

1. **Load Store Products**
```dart
final result = await AuthService.loadRetailerStoreProducts();
```

2. **Add Product to Store**
```dart
final result = await AuthService.addRetailerStoreProduct(
  productId: int.parse(_selectedProductId),
  price: 0.0,
);
```

3. **Remove Product from Store**
```dart
final result = await AuthService.removeRetailerStoreProduct(productId: productId);
```

4. **Load Product Catalog**
```dart
final result = await AuthService.loadRetailerProductCatalog();
```

### **API Endpoints**
- **Store Products**: `https://dtisrpmonitoring.bccbsis.com/api/retailer/store_products.php`
- **Product Catalog**: `https://dtisrpmonitoring.bccbsis.com/api/retailer/product_catalog.php`

## 📋 **Page Structure**

### **1. Main Page (`RetailerStoreProductsPage`)**
```dart
Scaffold(
  appBar: AppBar(...),                    // Header with title and refresh
  body: _buildContent(),                  // Main content area
  floatingActionButton: FloatingActionButton.extended(...), // Add product button
)
```

### **2. Content Sections**
- **Store Products Section** - List of retailer's products with compliance status
- **Feedback Reports Section** - Admin feedback on SRP violations

### **3. Store Products List**
```dart
ListView.separated(
  itemBuilder: (context, index) => _buildProductCard(product),
  // Product cards with violation indicators
)
```

### **4. Add Product Modal**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => _buildAddProductModal(),
)
```

## 🎯 **Key Features**

### **1. SRP Compliance Monitoring**
```dart
Color _getViolationColor(String violationLevel) {
  switch (violationLevel) {
    case 'critical_violation': return dangerRed;
    case 'minor_violation': return warningOrange;
    case 'below_srp': return successGreen;
    default: return gray;
  }
}
```

### **2. Product Card Design**
- **Violation Indicator** - Left border color based on compliance status
- **Product Image** - With fallback icon if no image available
- **Price Information** - SRP vs monitored price with deviation percentage
- **Category Badge** - Color-coded category display
- **Remove Button** - Easy product removal with confirmation

### **3. Add Product Modal**
- **Product Selection** - Scrollable list of available products
- **Visual Selection** - Selected product highlighted with checkmark
- **Loading States** - Proper loading indicators during API calls

### **4. Feedback Reports Section**
- **Collapsible Design** - Expandable section for admin feedback
- **Status Indicators** - Severity and status badges
- **Empty State** - Encouraging message when no violations

## 🔄 **Navigation Integration**

### **From Retailer Dashboard**
The store products page is accessible from the retailer dashboard:

```dart
// In retailer_dashboard.dart
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const RetailerStoreProductsPage(),
    ),
  ),
  icon: const Icon(Icons.storefront),
  label: const Text('Store Products'),
)
```

## 📱 **Mobile Optimizations**

### **1. Card-Based Layout**
- Single column layout for mobile
- Touch-friendly product cards
- Swipe gestures for interactions

### **2. Modal Design**
- Bottom sheet modal (mobile-friendly)
- Handle bar for easy dismissal
- Scrollable product selection

### **3. Floating Action Button**
- Quick access to add product functionality
- Material Design guidelines
- Prominent placement for primary action

## 🎨 **UI Components**

### **1. Product Cards**
```dart
Container(
  decoration: BoxDecoration(
    color: violationBgColor,
    border: Border(left: BorderSide(color: violationColor, width: 4)),
  ),
  child: Row(
    children: [
      // Product image with violation indicator
      // Product details
      // Remove button
    ],
  ),
)
```

### **2. Violation Status Badges**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: violationColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(violationText, style: TextStyle(color: Colors.white)),
)
```

### **3. Category Badges**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
    color: lightBlue,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(categoryName, style: TextStyle(color: primaryBlue)),
)
```

## 🔧 **Error Handling**

### **1. Network Errors**
```dart
try {
  final result = await AuthService.loadRetailerStoreProducts();
  // Handle success
} catch (e) {
  setState(() {
    _error = 'Connection error: $e';
    _isLoading = false;
  });
}
```

### **2. Empty States**
```dart
Widget _buildEmptyState() {
  return Container(
    child: Column(
      children: [
        Icon(Icons.inventory_2_outlined, size: 80),
        Text('No products added yet'),
        ElevatedButton.icon(
          onPressed: () => _showAddProductModal(),
          icon: const Icon(Icons.add),
          label: const Text('Add Your First Product'),
        ),
      ],
    ),
  );
}
```

### **3. Image Loading Errors**
```dart
Image.network(
  imageUrl,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: bgLight,
      child: Icon(Icons.inventory_2, color: textLight),
    );
  },
)
```

## 🚀 **Usage Example**

```dart
// Navigate to store products page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RetailerStoreProductsPage(),
  ),
);

// The page will automatically:
// 1. Load store products from API
// 2. Display products with compliance status
// 3. Show feedback reports section
// 4. Allow adding/removing products
```

## 📊 **Data Flow**

```
User opens page
    ↓
_loadStoreProducts() called
    ↓
AuthService.loadRetailerStoreProducts()
    ↓
API call to store_products.php
    ↓
JSON response with products data
    ↓
UI updates with product cards showing compliance status
    ↓
User taps "Add Product" button
    ↓
Modal opens with product selection
    ↓
User selects product and confirms
    ↓
AuthService.addRetailerStoreProduct()
    ↓
API call to add product
    ↓
Success message and list refresh
```

## 🎯 **Key Differences from PHP Version**

| Feature | PHP Version | Flutter Version |
|---------|-------------|-----------------|
| Layout | Bootstrap Table | Flutter ListView |
| Modals | Bootstrap Modal | Bottom Sheet Modal |
| Styling | CSS Classes | Flutter Widgets |
| Navigation | Page Redirects | Navigator.push |
| State Management | Server-side | Client-side State |
| Images | HTML img | Image.network |
| Forms | HTML Forms | Flutter Form Widgets |
| Violation Indicators | CSS Classes | Color-coded Widgets |

## 🔮 **Future Enhancements**

1. **Price Update Functionality** - Allow retailers to update product prices
2. **Bulk Operations** - Select multiple products for batch operations
3. **Search and Filter** - Search products by name, category, or brand
4. **Price History** - View price change history for products
5. **Push Notifications** - Notify when SRP violations occur
6. **Offline Support** - Cache products for offline viewing
7. **Export Functionality** - Export product list to PDF/Excel

## 📋 **SRP Compliance Logic**

The page implements the same SRP compliance logic as the PHP version:

### **Violation Levels**
- **Critical Violation**: Price > 110% of SRP
- **Minor Violation**: Price > SRP but ≤ 110%
- **Below SRP**: Price < 80% of SRP
- **Compliant**: Price within 80% - 100% of SRP

### **Visual Indicators**
- **Red Border**: Critical violations
- **Orange Border**: Minor violations
- **Green Border**: Below SRP (compliant)
- **Gray Border**: Normal compliance

### **Price Deviation Display**
```dart
Text(
  '${deviation > 0 ? '+' : ''}${_formatPercentage(deviation)}% ${deviation > 0 ? 'above' : 'below'} SRP',
  style: TextStyle(color: violationColor),
)
```

The Flutter version maintains all the functionality of the PHP version while providing a native mobile experience with better performance, touch interactions, and visual feedback for SRP compliance monitoring.
