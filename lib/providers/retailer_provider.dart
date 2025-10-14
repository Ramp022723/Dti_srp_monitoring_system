import 'package:flutter/material.dart';
import '../models/retailer_model.dart';
import '../services/retailer_api_service.dart';

class RetailerProvider with ChangeNotifier {
  final RetailerApiService _apiService = RetailerApiService();
  
  // State variables
  List<RetailerProduct> _retailerProducts = [];
  List<Retailer> _retailers = [];
  List<ViolationAlert> _violationAlerts = [];
  RetailerStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  RetailerFilters _filters = RetailerFilters();

  // Getters
  List<RetailerProduct> get retailerProducts => _retailerProducts;
  List<Retailer> get retailers => _retailers;
  List<ViolationAlert> get violationAlerts => _violationAlerts;
  RetailerStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  RetailerFilters get filters => _filters;

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update filters
  void updateFilters(RetailerFilters newFilters) {
    _filters = newFilters;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filters.clear();
    fetchRetailerProducts(refresh: true);
  }

  // Fetch retailer products
  Future<void> fetchRetailerProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _retailerProducts.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final products = await _apiService.getRetailerProducts(
        retailerSearch: _filters.retailerSearch,
        productSearch: _filters.productSearch,
        anomalyFilter: _filters.anomalyFilter,
        retailerId: _filters.retailerId,
        mainFolderId: _filters.mainFolderId,
        subFolderId: _filters.subFolderId,
        sortBy: _filters.sortBy,
        sortOrder: _filters.sortOrder,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _retailerProducts = products;
      } else {
        _retailerProducts.addAll(products);
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
    await fetchRetailerProducts(refresh: false);
  }

  // Fetch retailers
  Future<void> fetchRetailers({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _retailers = await _apiService.getRetailers(
        search: search,
        page: 1,
        limit: 100,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update retail price
  Future<bool> updateRetailPrice({
    required int retailPriceId,
    required double newPrice,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateRetailPrice(
        retailPriceId: retailPriceId,
        newPrice: newPrice,
      );

      if (result['success']) {
        // Update the product in the list
        final index = _retailerProducts.indexWhere(
          (p) => p.retailPriceId == retailPriceId,
        );
        if (index != -1) {
          // Refresh the data
          await fetchRetailerProducts(refresh: true);
        }
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update price';
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

  // Fetch violation alerts
  Future<void> fetchViolationAlerts({
    String? status,
    String? severity,
    int? retailerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _violationAlerts = await _apiService.getViolationAlerts(
        status: status,
        severity: severity,
        retailerId: retailerId,
        page: 1,
        limit: 100,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update violation alert status
  Future<bool> updateViolationAlertStatus({
    required int alertId,
    required String status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateViolationAlertStatus(
        alertId: alertId,
        status: status,
      );

      if (result['success']) {
        // Update the alert in the list
        final index = _violationAlerts.indexWhere((a) => a.alertId == alertId);
        if (index != -1) {
          // Refresh alerts
          await fetchViolationAlerts();
        }
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update alert status';
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

  // Fetch retailer statistics
  Future<void> fetchRetailerStats({
    int? retailerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _apiService.getRetailerStats(
        retailerId: retailerId,
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

  // Send violation notification
  Future<bool> sendViolationNotification({
    required int retailerId,
    required int productId,
    required String violationType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.sendViolationNotification(
        retailerId: retailerId,
        productId: productId,
        violationType: violationType,
      );

      if (result['success']) {
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to send notification';
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

  // Get compliance report
  Future<Map<String, dynamic>?> getComplianceReport({
    int? retailerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.getComplianceReport(
        retailerId: retailerId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Export retailer data
  Future<String?> exportRetailerData({String format = 'csv'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.exportRetailerData(
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

  // Calculate local statistics from current products
  Map<String, dynamic> calculateLocalStats() {
    if (_retailerProducts.isEmpty) {
      return {
        'total': 0,
        'compliant': 0,
        'minor_violations': 0,
        'critical_violations': 0,
        'compliance_rate': 0.0,
      };
    }

    final compliant = _retailerProducts.where((p) => p.isCompliant).length;
    final minor = _retailerProducts.where((p) => p.isMinorViolation).length;
    final critical = _retailerProducts.where((p) => p.isCriticalViolation).length;
    final complianceRate = (compliant / _retailerProducts.length) * 100;

    return {
      'total': _retailerProducts.length,
      'compliant': compliant,
      'minor_violations': minor,
      'critical_violations': critical,
      'compliance_rate': complianceRate,
      'violation_rate': ((minor + critical) / _retailerProducts.length) * 100,
    };
  }

  // Reset all state
  void reset() {
    _retailerProducts.clear();
    _retailers.clear();
    _violationAlerts.clear();
    _stats = null;
    _errorMessage = null;
    _currentPage = 1;
    _hasMoreData = true;
    _filters = RetailerFilters();
    notifyListeners();
  }
}
