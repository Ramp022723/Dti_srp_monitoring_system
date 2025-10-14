import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class RetailerProductListPage extends StatefulWidget {
  const RetailerProductListPage({Key? key}) : super(key: key);

  @override
  State<RetailerProductListPage> createState() => _RetailerProductListPageState();
}

class _RetailerProductListPageState extends State<RetailerProductListPage> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _sortBy = 'product_name';
  String _sortOrder = 'ASC';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.loadRetailerProductCatalog(limit: 500);
      
      if (result['status'] == 'success') {
        setState(() {
          final data = result['data'] as Map<String, dynamic>? ?? {};
          _products = (data['products'] as List<dynamic>? ) ?? [];
          _filteredProducts = List.from(_products);
          // Prefer categories from API when available
          final apiCategories = (data['categories'] as List<dynamic>? ) ?? [];
          _categories = apiCategories.isNotEmpty
              ? apiCategories
                  .map((e) => (e['name']?.toString() ?? '').trim())
                  .where((s) => s.isNotEmpty)
                  .cast<String>()
                  .toList()
              : _extractCategories();
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

  List<String> _extractCategories() {
    final categories = <String>{};
    for (final product in _products) {
      final category = product['category_name']?.toString() ?? '';
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }
    return categories.toList()..sort();
  }

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
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, Color color, bool isStrikethrough) {
    final priceValue = double.tryParse(price) ?? 0;
    final formattedPrice = '₱${priceValue.toStringAsFixed(2)}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            formattedPrice,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              decorationColor: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Navigate back to dashboard instead of login page
        Navigator.pushReplacementNamed(context, '/retailer-dashboard');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Catalog'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/retailer-dashboard');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProducts,
              tooltip: 'Refresh',
            ),
          ],
        ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, brand, or manufacturer...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                
                const SizedBox(height: 12),
                
                // Category Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        value: _selectedCategory.isEmpty ? null : _selectedCategory,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All Categories'),
                          ),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sorting Controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                ),
                
                const SizedBox(width: 12),
                
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
              ],
            ),
          ),
          
          // Results Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.list, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_filteredProducts.length} of ${_products.length} product${_products.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                if (_sortBy != 'product_name' || _sortOrder != 'ASC') ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort, color: Colors.blue[700], size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Sorted by ${_sortBy.replaceAll('_', ' ')} (${_sortOrder == 'ASC' ? 'A-Z' : 'Z-A'})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading products...'),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _products.isEmpty ? 'No products available' : 'No products match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_products.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = '';
                                    _sortBy = 'product_name';
                                    _sortOrder = 'ASC';
                                  });
                                  _applyFiltersAndSort();
                                },
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
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
          ),
        ],
      ),
      ),
    );
  }

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
}
