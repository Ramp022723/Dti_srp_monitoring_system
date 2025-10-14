import 'package:flutter/material.dart';
import '../models/price_freeze_model.dart';
import '../services/price_freeze_api_service.dart';

class PriceFreezeProvider with ChangeNotifier {
  final PriceFreezeApiService _apiService = PriceFreezeApiService();
  
  // State variables
  List<PriceFreezeAlert> _alerts = [];
  PriceFreezeAlert? _currentAlert;
  PriceFreezeStats? _stats;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;
  AlertFilters _filters = AlertFilters();

  // Getters
  List<PriceFreezeAlert> get alerts => _alerts;
  PriceFreezeAlert? get currentAlert => _currentAlert;
  PriceFreezeStats? get stats => _stats;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  AlertFilters get filters => _filters;

  // Calculated getters
  List<PriceFreezeAlert> get activeAlerts =>
      _alerts.where((a) => a.isCurrentlyActive).toList();
  
  List<PriceFreezeAlert> get scheduledAlerts =>
      _alerts.where((a) => DateTime.now().isBefore(a.freezeStartDate)).toList();
  
  List<PriceFreezeAlert> get expiredAlerts =>
      _alerts.where((a) => a.isExpired).toList();

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update filters
  void updateFilters(AlertFilters newFilters) {
    _filters = newFilters;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filters.clear();
    fetchAlerts(refresh: true);
  }

  // Fetch alerts
  Future<void> fetchAlerts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _alerts.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final alerts = await _apiService.getAlerts(
        status: _filters.status,
        dateFrom: _filters.dateFrom,
        dateTo: _filters.dateTo,
        search: _filters.search,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _alerts = alerts;
      } else {
        _alerts.addAll(alerts);
      }

      _hasMoreData = alerts.length >= 20;
      _currentPage++;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more alerts (pagination)
  Future<void> loadMoreAlerts() async {
    await fetchAlerts(refresh: false);
  }

  // Fetch single alert
  Future<void> fetchAlert(int alertId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentAlert = await _apiService.getAlert(alertId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create alert
  Future<bool> createAlert(CreateAlertRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.createAlert(request);
      if (result['success']) {
        await fetchAlerts(refresh: true);
        await fetchStats();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to create alert';
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

  // Update alert status
  Future<bool> updateAlertStatus({
    required int alertId,
    required String status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateAlertStatus(
        alertId: alertId,
        status: status,
      );

      if (result['success']) {
        // Update the alert in the list
        final index = _alerts.indexWhere((a) => a.alertId == alertId);
        if (index != -1) {
          await fetchAlerts(refresh: true);
        }
        
        // Update current alert if it's the same
        if (_currentAlert?.alertId == alertId) {
          await fetchAlert(alertId);
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

  // Delete alert
  Future<bool> deleteAlert(int alertId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.deleteAlert(alertId);
      if (result['success']) {
        _alerts.removeWhere((a) => a.alertId == alertId);
        
        if (_currentAlert?.alertId == alertId) {
          _currentAlert = null;
        }
        
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to delete alert';
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

  // Fetch statistics
  Future<void> fetchStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _apiService.getStats(
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

  // Fetch products
  Future<void> fetchProducts({String? search}) async {
    try {
      _products = await _apiService.getProducts(search: search);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
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

  // Fetch locations
  Future<void> fetchLocations() async {
    try {
      _locations = await _apiService.getLocations();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get alert notifications
  Future<List<PriceFreezeNotification>> getAlertNotifications(int alertId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.getAlertNotifications(alertId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend notifications
  Future<bool> resendNotifications(int alertId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.resendNotifications(alertId);
      if (result['success']) {
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to resend notifications';
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

  // Export alerts
  Future<String?> exportAlerts({String format = 'csv'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.exportAlerts(
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

  // Calculate local statistics from current alerts
  Map<String, dynamic> calculateLocalStats() {
    if (_alerts.isEmpty) {
      return {
        'total': 0,
        'active': 0,
        'scheduled': 0,
        'expired': 0,
      };
    }

    final active = _alerts.where((a) => a.isCurrentlyActive).length;
    final scheduled = _alerts.where((a) => DateTime.now().isBefore(a.freezeStartDate)).length;
    final expired = _alerts.where((a) => a.isExpired).length;

    return {
      'total': _alerts.length,
      'active': active,
      'scheduled': scheduled,
      'expired': expired,
    };
  }

  // Clear current alert
  void clearCurrentAlert() {
    _currentAlert = null;
    notifyListeners();
  }

  // Reset all state
  void reset() {
    _alerts.clear();
    _currentAlert = null;
    _stats = null;
    _products.clear();
    _categories.clear();
    _locations.clear();
    _errorMessage = null;
    _currentPage = 1;
    _hasMoreData = true;
    _filters = AlertFilters();
    notifyListeners();
  }
}
