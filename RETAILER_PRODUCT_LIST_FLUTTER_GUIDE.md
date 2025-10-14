# Retailer Product List - Flutter Implementation Guide

## Overview

This document provides a comprehensive guide for the Flutter implementation of the `retailer_product_list.php` page. The mobile version replicates all the functionality of the original web interface with mobile-optimized UI components and enhanced user experience.

## File Location

- **Flutter Implementation**: `lib/pages/retailer_product_list_page.dart`
- **Original PHP**: `c:\xampp\htdocs\dti_web\_\indexes\retailer_product_list.php`

## Key Features Replicated

### 1. **Product Catalog Display**
- **Original**: Grid layout with product cards showing images, names, prices, and categories
- **Flutter**: Responsive grid layout using `GridView.builder` with 2 columns
- **Mobile Enhancement**: Optimized card aspect ratio (0.75) for better mobile viewing

### 2. **Search Functionality**
- **Original**: Text input with search by product name, brand, or manufacturer
- **Flutter**: `TextField` with real-time filtering
- **Mobile Enhancement**: Clear visual feedback and instant results

### 3. **Category Filtering**
- **Original**: Dropdown select for category filtering
- **Flutter**: `DropdownButtonFormField` with dynamic category list
- **Mobile Enhancement**: Touch-friendly dropdown interface

### 4. **Advanced Sorting**
- **Original**: Sort by multiple fields (name, brand, manufacturer, prices, unit, category)
- **Flutter**: `DropdownButtonFormField` for sort field selection
- **Mobile Enhancement**: Toggle buttons for ASC/DESC order selection

### 5. **Product Details Modal**
- **Original**: Bootstrap modal with detailed product information
- **Flutter**: `ModalBottomSheet` with comprehensive product details
- **Mobile Enhancement**: Native bottom sheet behavior with smooth animations

## UI Components Comparison

### Search and Filter Section
```dart
// Search Bar
TextField(
  decoration: InputDecoration(
    hintText: 'Search by name, brand, or manufacturer...',
    prefixIcon: const Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.grey[50],
  ),
  onChanged: (value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFiltersAndSort();
  },
),

// Category Filter
DropdownButtonFormField<String>(
  decoration: InputDecoration(
    labelText: 'Category',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.grey[50],
  ),
  value: _selectedCategory.isEmpty ? null : _selectedCategory,
  items: [
    const DropdownMenuItem(value: '', child: Text('All Categories')),
    ..._categories.map((category) => DropdownMenuItem(
      value: category,
      child: Text(category),
    )),
  ],
  onChanged: (value) {
    setState(() {
      _selectedCategory = value ?? '';
    });
    _applyFiltersAndSort();
  },
),
```

### Sorting Controls
```dart
// Sort Field Selection
DropdownButtonFormField<String>(
  decoration: InputDecoration(
    labelText: 'Sort By',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  value: _sortBy,
  items: const [
    DropdownMenuItem(value: 'product_name', child: Text('Product Name')),
    DropdownMenuItem(value: 'brand', child: Text('Brand')),
    DropdownMenuItem(value: 'manufacturer', child: Text('Manufacturer')),
    DropdownMenuItem(value: 'srp', child: Text('SRP (Price)')),
    DropdownMenuItem(value: 'monitored_price', child: Text('Monitored Price')),
    DropdownMenuItem(value: 'prevailing_price', child: Text('Prevailing Price')),
    DropdownMenuItem(value: 'unit', child: Text('Unit Size')),
    DropdownMenuItem(value: 'category_name', child: Text('Category')),
  ],
  onChanged: (value) {
    setState(() {
      _sortBy = value ?? 'product_name';
    });
    _applyFiltersAndSort();
  },
),

// Sort Order Toggle
ToggleButtons(
  isSelected: [_sortOrder == 'ASC', _sortOrder == 'DESC'],
  onPressed: (index) {
    setState(() {
      _sortOrder = index == 0 ? 'ASC' : 'DESC';
    });
    _applyFiltersAndSort();
  },
  borderRadius: BorderRadius.circular(8),
  selectedColor: Colors.white,
  fillColor: Colors.blue[600],
  color: Colors.grey[600],
  children: const [
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward, size: 16),
          SizedBox(width: 4),
          Text('ASC'),
        ],
      ),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_downward, size: 16),
          SizedBox(width: 4),
          Text('DESC'),
        ],
      ),
    ),
  ],
),
```

### Product Grid
```dart
GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: _filteredProducts.length,
  itemBuilder: (context, index) {
    final product = _filteredProducts[index];
    return _buildProductCard(product);
  },
),
```

### Product Card
```dart
Widget _buildProductCard(dynamic product) {
  final srp = double.tryParse(product['srp']?.toString() ?? '0') ?? 0;
  final monitoredPrice = double.tryParse(product['monitored_price']?.toString() ?? '0') ?? 0;
  final prevailingPrice = double.tryParse(product['prevailing_price']?.toString() ?? '0') ?? 0;
  
  return GestureDetector(
    onTap: () => _showProductDetails(product),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: product['profile_pic'] != null && 
                   product['profile_pic'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      '${AuthService.baseUrl}/uploads/profile_pics/${product['profile_pic']}',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.inventory_2_outlined,
                          size: 32,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    color: Colors.grey,
                  ),
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product['product_name']?.toString() ?? 'Unknown Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Brand
                  Text(
                    product['brand']?.toString() ?? 'Unknown Brand',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price Comparison
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SRP: ₱${srp.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Monitored: ₱${monitoredPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Prevailing: ₱${prevailingPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product['category_name']?.toString() ?? 'Uncategorized',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Product ID
                  Text(
                    'ID: ${product['product_id']?.toString() ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

## API Integration

### Product Catalog Loading
```dart
Future<void> _loadProducts() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final result = await AuthService.loadRetailerProductCatalog();
    
    if (result['status'] == 'success') {
      setState(() {
        _products = result['data'] ?? [];
        _filteredProducts = List.from(_products);
        _categories = _extractCategories();
        _isLoading = false;
      });
      
      _applyFiltersAndSort();
    } else {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load products'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Filtering and Sorting Logic
```dart
void _applyFiltersAndSort() {
  setState(() {
    _filteredProducts = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) {
        final name = product['product_name']?.toString().toLowerCase() ?? '';
        final brand = product['brand']?.toString().toLowerCase() ?? '';
        final manufacturer = product['manufacturer']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        
        return name.contains(searchLower) || 
               brand.contains(searchLower) || 
               manufacturer.contains(searchLower);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) {
        return product['category_name']?.toString() == _selectedCategory;
      }).toList();
    }

    // Apply sorting
    _filteredProducts.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortBy) {
        case 'product_name':
          aValue = a['product_name']?.toString() ?? '';
          bValue = b['product_name']?.toString() ?? '';
          break;
        case 'brand':
          aValue = a['brand']?.toString() ?? '';
          bValue = b['brand']?.toString() ?? '';
          break;
        case 'manufacturer':
          aValue = a['manufacturer']?.toString() ?? '';
          bValue = b['manufacturer']?.toString() ?? '';
          break;
        case 'srp':
          aValue = double.tryParse(a['srp']?.toString() ?? '0') ?? 0;
          bValue = double.tryParse(b['srp']?.toString() ?? '0') ?? 0;
          break;
        case 'monitored_price':
          aValue = double.tryParse(a['monitored_price']?.toString() ?? '0') ?? 0;
          bValue = double.tryParse(b['monitored_price']?.toString() ?? '0') ?? 0;
          break;
        case 'prevailing_price':
          aValue = double.tryParse(a['prevailing_price']?.toString() ?? '0') ?? 0;
          bValue = double.tryParse(b['prevailing_price']?.toString() ?? '0') ?? 0;
          break;
        case 'unit':
          aValue = a['unit']?.toString() ?? '';
          bValue = b['unit']?.toString() ?? '';
          break;
        case 'category_name':
          aValue = a['category_name']?.toString() ?? '';
          bValue = b['category_name']?.toString() ?? '';
          break;
        default:
          aValue = a['product_name']?.toString() ?? '';
          bValue = b['product_name']?.toString() ?? '';
      }

      int comparison = 0;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is double && bValue is double) {
        comparison = aValue.compareTo(bValue);
      }

      return _sortOrder == 'ASC' ? comparison : -comparison;
    });
  });
}
```

## Modal Implementation

### Product Details Modal
```dart
void _showProductDetails(dynamic product) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _buildProductDetailsModal(product),
  );
}

Widget _buildProductDetailsModal(dynamic product) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.85,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Product Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
        ),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: product['profile_pic'] != null && 
                           product['profile_pic'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              '${AuthService.baseUrl}/uploads/profile_pics/${product['profile_pic']}',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Product Name
                Text(
                  product['product_name']?.toString() ?? 'Unknown Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Product Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Brand', product['brand']?.toString() ?? 'N/A'),
                      _buildInfoRow('Manufacturer', product['manufacturer']?.toString() ?? 'N/A'),
                      _buildInfoRow('Category', product['category_name']?.toString() ?? 'N/A'),
                      _buildInfoRow('Unit Size', '${product['unit']?.toString() ?? 'N/A'}ml'),
                      _buildInfoRow('Product ID', product['product_id']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Price Details
                Text(
                  'Price Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'Suggested Retail Price (SRP)',
                        product['srp']?.toString() ?? '0',
                        Colors.grey[600]!,
                        true,
                      ),
                      _buildPriceRow(
                        'Monitored Price',
                        product['monitored_price']?.toString() ?? '0',
                        Colors.green[600]!,
                        false,
                      ),
                      _buildPriceRow(
                        'Prevailing Price',
                        product['prevailing_price']?.toString() ?? '0',
                        Colors.red[600]!,
                        false,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

## Mobile Optimizations

### 1. **Touch-Friendly Interface**
- Large tap targets for all interactive elements
- Swipe gestures for modal dismissal
- Responsive grid layout that adapts to screen size

### 2. **Performance Optimizations**
- Lazy loading of product images with error handling
- Efficient filtering and sorting algorithms
- Minimal rebuilds with proper state management

### 3. **Visual Enhancements**
- Modern Material Design components
- Consistent color scheme matching DTI branding
- Smooth animations and transitions
- Clear visual hierarchy

### 4. **Accessibility Features**
- Semantic labels for all interactive elements
- High contrast color combinations
- Proper text scaling support
- Screen reader compatibility

## Navigation Integration

### Dashboard Navigation
The product list page is integrated into the retailer dashboard with a dedicated navigation button:

```dart
// In retailer_dashboard.dart
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const RetailerProductListPage(),
    ),
  ),
  icon: const Icon(Icons.list_alt),
  label: const Text('Product List'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white,
  ),
),
```

## State Management

### State Variables
```dart
class _RetailerProductListPageState extends State<RetailerProductListPage> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _sortBy = 'product_name';
  String _sortOrder = 'ASC';
}
```

### State Updates
- **Loading State**: Managed with `_isLoading` boolean
- **Product Data**: Stored in `_products` and `_filteredProducts` lists
- **Filter State**: Managed with `_searchQuery` and `_selectedCategory`
- **Sort State**: Managed with `_sortBy` and `_sortOrder`

## Error Handling

### Network Errors
```dart
try {
  final result = await AuthService.loadRetailerProductCatalog();
  // Handle success
} catch (e) {
  setState(() {
    _isLoading = false;
  });
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading products: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Image Loading Errors
```dart
Image.network(
  '${AuthService.baseUrl}/uploads/profile_pics/${product['profile_pic']}',
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    return const Icon(
      Icons.inventory_2_outlined,
      size: 32,
      color: Colors.grey,
    );
  },
),
```

## Key Differences from Original

### 1. **UI Framework**
- **Original**: Bootstrap CSS with custom styling
- **Flutter**: Material Design with custom theming

### 2. **Modal Implementation**
- **Original**: Bootstrap modal with JavaScript
- **Flutter**: Native `ModalBottomSheet` with smooth animations

### 3. **Sorting Implementation**
- **Original**: Server-side sorting with page reload
- **Flutter**: Client-side sorting with instant updates

### 4. **Search Implementation**
- **Original**: JavaScript filtering on page load
- **Flutter**: Real-time filtering with `onChanged` callback

### 5. **Navigation**
- **Original**: Page navigation with URL changes
- **Flutter**: Stack navigation with `Navigator.push`

## Usage Examples

### Basic Usage
```dart
// Navigate to product list page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RetailerProductListPage(),
  ),
);
```

### Custom Filtering
```dart
// Set initial filters
setState(() {
  _searchQuery = 'search term';
  _selectedCategory = 'Category Name';
  _sortBy = 'srp';
  _sortOrder = 'DESC';
});
_applyFiltersAndSort();
```

### Show Product Details
```dart
// Show product details modal
_showProductDetails(product);
```

## Testing Considerations

### 1. **Unit Tests**
- Test filtering logic with various inputs
- Test sorting algorithms with different data types
- Test error handling scenarios

### 2. **Widget Tests**
- Test product card rendering
- Test modal display functionality
- Test search and filter interactions

### 3. **Integration Tests**
- Test API integration
- Test navigation flow
- Test user interactions

## Future Enhancements

### 1. **Performance Improvements**
- Implement pagination for large product catalogs
- Add image caching for better performance
- Implement virtual scrolling for better memory usage

### 2. **Feature Additions**
- Add product comparison functionality
- Implement favorites/wishlist feature
- Add product sharing capabilities

### 3. **UI Enhancements**
- Add pull-to-refresh functionality
- Implement infinite scroll
- Add skeleton loading states

## Conclusion

The Flutter implementation of the retailer product list page successfully replicates all the functionality of the original PHP version while providing a superior mobile user experience. The implementation includes:

- ✅ Complete feature parity with the original
- ✅ Mobile-optimized UI components
- ✅ Real-time search and filtering
- ✅ Advanced sorting capabilities
- ✅ Comprehensive product details modal
- ✅ Robust error handling
- ✅ Smooth animations and transitions
- ✅ Accessibility features
- ✅ Performance optimizations

The page is fully integrated into the retailer dashboard and provides retailers with an intuitive way to browse and explore the complete product catalog on their mobile devices.
