import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_api_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductApiService _apiService = ProductApiService();
  
  // State variables
  List<Product> _products = [];
  Product? _currentProduct;
  List<Category> _categories = [];
  List<Folder> _folders = [];
  List<SRPHistory> _srpHistory = [];
  PriceAnalytics? _priceAnalytics;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  ProductFilters _filters = ProductFilters();
  
  // Selected products for bulk operations
  Set<int> _selectedProductIds = {};

  // Getters
  List<Product> get products => _products;
  Product? get currentProduct => _currentProduct;
  List<Category> get categories => _categories;
  List<Folder> get folders => _folders;
  List<SRPHistory> get srpHistory => _srpHistory;
  PriceAnalytics? get priceAnalytics => _priceAnalytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  ProductFilters get filters => _filters;
  Set<int> get selectedProductIds => _selectedProductIds;
  bool get hasSelectedProducts => _selectedProductIds.isNotEmpty;
  int get selectedCount => _selectedProductIds.length;

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Toggle product selection
  void toggleProductSelection(int productId) {
    if (_selectedProductIds.contains(productId)) {
      _selectedProductIds.remove(productId);
    } else {
      _selectedProductIds.add(productId);
    }
    notifyListeners();
  }

  // Select all products
  void selectAllProducts() {
    _selectedProductIds = _products.map((p) => p.productId).toSet();
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedProductIds.clear();
    notifyListeners();
  }

  // Update filters
  void updateFilters(ProductFilters newFilters) {
    _filters = newFilters;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filters.clear();
    fetchProducts(refresh: true);
  }

  // Fetch products
  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final products = await _apiService.getProducts(
        search: _filters.search,
        categoryId: _filters.categoryId,
        priceMin: _filters.priceMin,
        priceMax: _filters.priceMax,
        folderId: _filters.folderId,
        mainFolderId: _filters.mainFolderId,
        subFolderId: _filters.subFolderId,
        sortBy: _filters.sortBy,
        sortOrder: _filters.sortOrder,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _products = products;
      } else {
        _products.addAll(products);
      }

      _hasMoreData = products.length >= 20;
      _currentPage++;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    await fetchProducts(refresh: false);
  }

  // Fetch single product
  Future<void> fetchProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentProduct = await _apiService.getProduct(productId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create product
  Future<bool> createProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.createProduct(product);
      if (result['success']) {
        await fetchProducts(refresh: true);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to create product';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update product
  Future<bool> updateProduct(int productId, Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateProduct(productId, product);
      if (result['success']) {
        // Update in list
        final index = _products.indexWhere((p) => p.productId == productId);
        if (index != -1) {
          _products[index] = product;
        }
        
        // Update current product
        if (_currentProduct?.productId == productId) {
          _currentProduct = product;
        }
        
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update product';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update SRP
  Future<bool> updateSRP({
    required int productId,
    required double newSRP,
    required DateTime effectiveDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateSRP(
        productId: productId,
        newSRP: newSRP,
        effectiveDate: effectiveDate,
      );
      
      if (result['success']) {
        // Refresh product data
        await fetchProduct(productId);
        await fetchProducts(refresh: true);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update SRP';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bulk update SRP
  Future<bool> bulkUpdateSRP({
    required List<int> productIds,
    required double newSRP,
    required DateTime effectiveDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.bulkUpdateSRP(
        productIds: productIds,
        newSRP: newSRP,
        effectiveDate: effectiveDate,
      );
      
      if (result['success']) {
        await fetchProducts(refresh: true);
        clearSelection();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to bulk update SRP';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete product
  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.deleteProduct(productId);
      if (result['success']) {
        _products.removeWhere((p) => p.productId == productId);
        
        if (_currentProduct?.productId == productId) {
          _currentProduct = null;
        }
        
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to delete product';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch SRP history
  Future<void> fetchSRPHistory(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _srpHistory = await _apiService.getSRPHistory(productId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch price analytics
  Future<void> fetchPriceAnalytics({
    int? categoryId,
    int? folderId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _priceAnalytics = await _apiService.getPriceAnalytics(
        categoryId: categoryId,
        folderId: folderId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Fetch folders
  Future<void> fetchFolders({bool hierarchical = true}) async {
    try {
      _folders = await _apiService.getFolders(hierarchical: hierarchical);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Move products to folder
  Future<bool> moveProductsToFolder({
    required List<int> productIds,
    required int folderId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.moveProductsToFolder(
        productIds: productIds,
        folderId: folderId,
      );
      
      if (result['success']) {
        await fetchProducts(refresh: true);
        clearSelection();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to move products';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Export products
  Future<String?> exportProducts({String format = 'csv'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.exportProducts(
        format: format,
        filters: _filters,
      );
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search by barcode
  Future<Product?> searchByBarcode(String barcode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.searchByBarcode(barcode);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate statistics from current products
  Map<String, dynamic> calculateLocalStats() {
    if (_products.isEmpty) {
      return {
        'total': 0,
        'compliant': 0,
        'overpriced': 0,
        'underpriced': 0,
        'compliance_rate': 0.0,
      };
    }

    final compliant = _products.where((p) => p.isCompliant).length;
    final overpriced = _products.where((p) => p.isOverpriced).length;
    final underpriced = _products.where((p) => p.isUnderpriced).length;
    final complianceRate = (compliant / _products.length) * 100;

    return {
      'total': _products.length,
      'compliant': compliant,
      'overpriced': overpriced,
      'underpriced': underpriced,
      'compliance_rate': complianceRate,
    };
  }

  // Clear current product
  void clearCurrentProduct() {
    _currentProduct = null;
    notifyListeners();
  }

  // Reset all state
  void reset() {
    _products.clear();
    _currentProduct = null;
    _categories.clear();
    _folders.clear();
    _srpHistory.clear();
    _priceAnalytics = null;
    _selectedProductIds.clear();
    _errorMessage = null;
    _currentPage = 1;
    _hasMoreData = true;
    _filters = ProductFilters();
    notifyListeners();
  }
}
