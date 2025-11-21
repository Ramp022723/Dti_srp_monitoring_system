import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../models/retailer_model.dart';
import '../services/retailer_api_service.dart';

class BrowseProductsWidget extends StatefulWidget {
  const BrowseProductsWidget({super.key});

  @override
  State<BrowseProductsWidget> createState() => _BrowseProductsWidgetState();
}

class _BrowseProductsWidgetState extends State<BrowseProductsWidget> {
  final RetailerApiService _apiService = RetailerApiService();
  List<Product> _allProducts = []; // Store all products
  List<Product> _filteredProducts = []; // Displayed products after filtering
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedBrand;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'product_name';
  String _sortOrder = 'ASC';
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });
    
    // Debounce search to avoid too many filter operations
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch products from store_prices.php API
      print('📊 BrowseProductsWidget: Fetching products from DATABASE...');
      print('📊 API Endpoint: admin/store_prices.php (via RetailerApiService.getStorePrices())');
      final retailerProducts = await _apiService.getStorePrices();
      print('✅ BrowseProductsWidget: Successfully retrieved ${retailerProducts.length} products from DATABASE via store_prices.php');
      print('📊 All products are from store_prices.php API - no mock/sample data used');
      
      // Convert RetailerProduct to Product and aggregate unique products
      // Group by productId to get unique products with average/current prices
      final Map<int, Product> productMap = {};
      final Set<String> categoryNames = {};
      
      for (final retailerProduct in retailerProducts) {
        final productId = retailerProduct.productId;
        
        // If product doesn't exist or this is a more recent price, update it
        if (!productMap.containsKey(productId) || 
            retailerProduct.dateRecorded.isAfter(
              productMap[productId]!.updatedAt ?? DateTime(1970)
            )) {
          productMap[productId] = _convertRetailerProductToProduct(retailerProduct);
        } else {
          // Update with current retail price if available
          final existing = productMap[productId]!;
          productMap[productId] = Product(
            productId: existing.productId,
            productName: existing.productName,
            brand: existing.brand,
            manufacturer: existing.manufacturer,
            srp: existing.srp,
            monitoredPrice: retailerProduct.currentRetailPrice > 0 
                ? retailerProduct.currentRetailPrice 
                : existing.monitoredPrice,
            prevailingPrice: existing.prevailingPrice,
            unit: existing.unit,
            profilePic: existing.profilePic ?? retailerProduct.profilePic,
            imageUrl: existing.imageUrl ?? retailerProduct.profilePic,
            priceDifference: existing.priceDifference,
            priceVariancePercent: existing.priceVariancePercent,
            createdAt: existing.createdAt,
            updatedAt: retailerProduct.dateRecorded.isAfter(
              existing.updatedAt ?? DateTime(1970)
            ) ? retailerProduct.dateRecorded : existing.updatedAt,
            categoryName: existing.categoryName ?? retailerProduct.categoryName,
            categoryId: existing.categoryId ?? retailerProduct.categoryId,
            folderName: existing.folderName ?? retailerProduct.mainFolderName,
            folderPath: existing.folderPath,
            folderId: existing.folderId,
            mainFolderId: existing.mainFolderId ?? retailerProduct.mainFolderId,
            subFolderId: existing.subFolderId ?? retailerProduct.subFolderId,
          );
        }
        
        // Collect category names
        if (retailerProduct.categoryName != null) {
          categoryNames.add(retailerProduct.categoryName!);
        }
      }
      
      // Convert map to list and sort
      final productsList = productMap.values.toList();
      productsList.sort((a, b) {
        switch (_sortBy) {
          case 'product_name':
            return _sortOrder == 'ASC' 
                ? a.productName.compareTo(b.productName)
                : b.productName.compareTo(a.productName);
          case 'srp':
            return _sortOrder == 'ASC' 
                ? a.srp.compareTo(b.srp)
                : b.srp.compareTo(a.srp);
          default:
            return 0;
        }
      });
      
      // Create categories list from collected names
      // Use index + 1 as ID to ensure unique IDs for filtering
      final categories = categoryNames.toList().asMap().entries.map((entry) => Category(
        id: entry.key + 1, // Use index + 1 as unique ID
        name: entry.value,
      )).toList();

      setState(() {
        _allProducts = productsList; // Store all products
        _categories = categories;
        _isLoading = false;
      });
      
      // Apply initial filters
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Product _convertRetailerProductToProduct(RetailerProduct retailerProduct) {
    return Product(
      productId: retailerProduct.productId,
      productName: retailerProduct.productName,
      brand: retailerProduct.brand,
      manufacturer: retailerProduct.manufacturer,
      srp: retailerProduct.srp,
      monitoredPrice: retailerProduct.currentRetailPrice > 0 
          ? retailerProduct.currentRetailPrice 
          : retailerProduct.monitoredPrice,
      prevailingPrice: retailerProduct.prevailingPrice,
      unit: retailerProduct.unit,
      profilePic: retailerProduct.profilePic,
      imageUrl: retailerProduct.profilePic,
      createdAt: retailerProduct.dateRecorded,
      updatedAt: retailerProduct.dateRecorded,
      categoryName: retailerProduct.categoryName,
      categoryId: retailerProduct.categoryId,
      folderName: retailerProduct.mainFolderName ?? retailerProduct.subFolderName,
      mainFolderId: retailerProduct.mainFolderId,
      subFolderId: retailerProduct.subFolderId,
    );
  }

  /// Apply all filters and search to display products
  void _applyFilters() {
    List<Product> filtered = List.from(_allProducts);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        return product.productName.toLowerCase().contains(query) ||
               (product.brand ?? '').toLowerCase().contains(query) ||
               (product.manufacturer ?? '').toLowerCase().contains(query) ||
               (product.categoryName ?? '').toLowerCase().contains(query);
      }).toList();
    }
    
    // Filter by category
    if (_selectedCategoryId != null && _categories.isNotEmpty) {
      final categoryName = _categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => _categories.first,
      ).name;
      filtered = filtered.where((product) => 
        product.categoryName == categoryName
      ).toList();
    }
    
    // Filter by brand
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      filtered = filtered.where((product) => 
        product.brand == _selectedBrand
      ).toList();
    }
    
    // Filter by price range
    if (_minPrice != null) {
      filtered = filtered.where((product) => product.srp >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((product) => product.srp <= _maxPrice!).toList();
    }
    
    // Sort products
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'product_name':
          return _sortOrder == 'ASC' 
              ? a.productName.compareTo(b.productName)
              : b.productName.compareTo(a.productName);
        case 'srp':
          return _sortOrder == 'ASC' 
              ? a.srp.compareTo(b.srp)
              : b.srp.compareTo(a.srp);
        default:
          return 0;
      }
    });
    
    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Browse Products',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover products and compare prices from local retailers',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products by name, brand, or category...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _applyFilters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category chips (quick filter)
                      _buildCategoryChips(),
                      const SizedBox(width: 12),
                      // Category Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedCategoryId,
                            hint: Text(
                              'All Categories',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: GoogleFonts.poppins(color: Colors.black),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ..._categories.map((category) => DropdownMenuItem<int?>(
                                value: category.id,
                                child: Text(category.name),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Filter Button (for advanced filters)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                          onPressed: _showAdvancedFilters,
                          tooltip: 'Advanced Filters',
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Sort Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: '$_sortBy-$_sortOrder',
                            hint: Text(
                              'Sort By',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: GoogleFonts.poppins(color: Colors.black),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'product_name-ASC',
                                child: Text('Name A-Z'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'product_name-DESC',
                                child: Text('Name Z-A'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'srp-ASC',
                                child: Text('Price Low-High'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'srp-DESC',
                                child: Text('Price High-Low'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                final parts = value.split('-');
                                setState(() {
                                  _sortBy = parts[0];
                                  _sortOrder = parts[1];
                                });
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    final List<Widget> chips = [];
    chips.add(
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: const Text('All'),
          selected: _selectedCategoryId == null,
          onSelected: (sel) {
            setState(() => _selectedCategoryId = null);
            _applyFilters();
          },
        ),
      ),
    );
    for (final category in _categories.take(10)) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(category.name),
            selected: _selectedCategoryId == category.id,
            onSelected: (sel) {
              setState(() => _selectedCategoryId = sel ? category.id : null);
              _applyFilters();
            },
          ),
        ),
      );
    }
    return Row(children: chips);
  }

  Widget _buildProductsGrid() {
    if (_isLoading && _allProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading products',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategoryId != null
                  ? 'Try adjusting your search or filters'
                  : 'No products available',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedCategoryId != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategoryId = null;
                    _selectedBrand = null;
                    _minPrice = null;
                    _maxPrice = null;
                  });
                  _searchController.clear();
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear all filters'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'product' : 'products'} found',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (_searchQuery.isNotEmpty || _selectedCategoryId != null || _selectedBrand != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedCategoryId = null;
                      _selectedBrand = null;
                      _minPrice = null;
                      _maxPrice = null;
                    });
                    _searchController.clear();
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text(
                    'Clear filters',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        // Products grid
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_filteredProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (product.brand != null && product.brand!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.brand!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Price
                    Row(
                      children: [
                        Text(
                          '₱${product.srp.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                        if (product.unit != null && product.unit!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '/${product.unit}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Price Status
                    if (product.monitoredPrice != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            product.isCompliant ? Icons.check_circle : Icons.warning,
                            size: 12,
                            color: product.priceStatusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.priceStatusText,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: product.priceStatusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.image,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Product Image
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey[400],
                                );
                              },
                            )
                          : Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Product Name
                Text(
                  product.productName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Brand and Manufacturer
                if (product.brand != null && product.brand!.isNotEmpty) ...[
                  Text(
                    'Brand: ${product.brand}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                if (product.manufacturer != null && product.manufacturer!.isNotEmpty) ...[
                  Text(
                    'Manufacturer: ${product.manufacturer}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Price Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official Suggested Retail Price (SRP)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${product.srp.toStringAsFixed(2)}${product.unit != null ? ' / ${product.unit}' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      
                      if (product.monitoredPrice != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Current Market Price',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${product.monitoredPrice!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: product.priceStatusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              product.isCompliant ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: product.priceStatusColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.priceStatusText,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: product.priceStatusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Category and Folder Info
                if (product.categoryName != null) ...[
                  _buildInfoRow('Category', product.categoryName!),
                ],
                
                if (product.folderName != null) ...[
                  _buildInfoRow('Category Folder', product.folderName!),
                ],
                
                const SizedBox(height: 24),
                
                // Call to Action
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[700]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Want to see more products?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to access the full product catalog and connect with local retailers',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/user-type-selection');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    final minPriceController = TextEditingController(
      text: _minPrice?.toStringAsFixed(2) ?? '',
    );
    final maxPriceController = TextEditingController(
      text: _maxPrice?.toStringAsFixed(2) ?? '',
    );
    
    // Get unique brands from all products
    final brands = _allProducts
        .where((p) => p.brand != null && p.brand!.isNotEmpty)
        .map((p) => p.brand!)
        .toSet()
        .toList()
      ..sort();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Text(
                  'Advanced Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Brand Filter
                if (brands.isNotEmpty) ...[
                  Text(
                    'Brand',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedBrand,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'All Brands',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Brands'),
                      ),
                      ...brands.map((brand) => DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBrand = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Price Range Filter
                Text(
                  'Price Range',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Min Price (₱)',
                          border: OutlineInputBorder(),
                          prefixText: '₱',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _minPrice = double.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Max Price (₱)',
                          border: OutlineInputBorder(),
                          prefixText: '₱',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _maxPrice = double.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _minPrice = double.tryParse(minPriceController.text);
                            _maxPrice = double.tryParse(maxPriceController.text);
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedBrand = null;
                      _minPrice = null;
                      _maxPrice = null;
                    });
                    minPriceController.clear();
                    maxPriceController.clear();
                    _applyFilters();
                  },
                  child: const Text('Clear All Filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
