import 'package:flutter/material.dart';
import '../models/monitoring_model.dart';
import '../services/monitoring_api_service.dart';

class MonitoringProvider with ChangeNotifier {
  final MonitoringApiService _apiService = MonitoringApiService();
  
  // State variables
  List<MonitoringForm> _monitoringForms = [];
  MonitoringForm? _currentForm;
  MonitoringStats? _stats;
  List<Store> _stores = [];
  List<Map<String, dynamic>> _productHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<MonitoringForm> get monitoringForms => _monitoringForms;
  MonitoringForm? get currentForm => _currentForm;
  MonitoringStats? get stats => _stats;
  List<Store> get stores => _stores;
  List<Map<String, dynamic>> get productHistory => _productHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create a new monitoring form
  Future<bool> createMonitoringForm(MonitoringForm form) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.createMonitoringForm(form);
      if (result['success']) {
        // Refresh forms list
        await fetchMonitoringForms();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to create monitoring form';
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

  // Fetch monitoring forms
  Future<void> fetchMonitoringForms({
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _monitoringForms.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final forms = await _apiService.getMonitoringForms(
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
        storeName: storeName,
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _monitoringForms = forms;
      } else {
        _monitoringForms.addAll(forms);
      }

      _hasMoreData = forms.length >= 20;
      _currentPage++;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more forms (for pagination)
  Future<void> loadMoreForms({
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
  }) async {
    await fetchMonitoringForms(
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
      storeName: storeName,
      refresh: false,
    );
  }

  // Get a specific monitoring form
  Future<void> fetchMonitoringForm(int formId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentForm = await _apiService.getMonitoringForm(formId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a monitoring form
  Future<bool> updateMonitoringForm(int formId, MonitoringForm form) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.updateMonitoringForm(formId, form);
      if (result['success']) {
        // Update the form in the list
        final index = _monitoringForms.indexWhere((f) => f.id == formId);
        if (index != -1) {
          _monitoringForms[index] = form.copyWith(id: formId);
        }
        
        // Update current form if it's the same
        if (_currentForm?.id == formId) {
          _currentForm = form.copyWith(id: formId);
        }
        
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update monitoring form';
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

  // Delete a monitoring form
  Future<bool> deleteMonitoringForm(int formId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.deleteMonitoringForm(formId);
      if (result['success']) {
        // Remove from list
        _monitoringForms.removeWhere((f) => f.id == formId);
        
        // Clear current form if it's the same
        if (_currentForm?.id == formId) {
          _currentForm = null;
        }
        
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to delete monitoring form';
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

  // Fetch monitoring statistics
  Future<void> fetchMonitoringStats({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _apiService.getMonitoringStats(
        dateFrom: dateFrom,
        dateTo: dateTo,
        storeName: storeName,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch store statistics
  Future<void> fetchStoreStats({
    String? search,
    bool refresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stores = await _apiService.getStoreStats(
        search: search,
        page: 1,
        limit: 100,
      );

      if (refresh) {
        _stores = stores;
      } else {
        _stores.addAll(stores);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch product monitoring history
  Future<void> fetchProductHistory({
    String? productName,
    String? storeName,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productHistory = await _apiService.getProductMonitoringHistory(
        productName: productName,
        storeName: storeName,
        dateFrom: dateFrom,
        dateTo: dateTo,
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

  // Export monitoring data
  Future<String?> exportMonitoringData({
    String format = 'json',
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final downloadUrl = await _apiService.exportMonitoringData(
        format: format,
        dateFrom: dateFrom,
        dateTo: dateTo,
        storeName: storeName,
      );
      return downloadUrl;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get monitoring templates
  Future<List<Map<String, dynamic>>> fetchMonitoringTemplates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _apiService.getMonitoringTemplates();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save monitoring template
  Future<bool> saveMonitoringTemplate({
    required String templateName,
    required String description,
    required List<MonitoringProduct> products,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.saveMonitoringTemplate(
        templateName: templateName,
        description: description,
        products: products,
      );
      
      if (result['success']) {
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to save template';
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

  // Create a new form from template
  MonitoringForm createFormFromTemplate({
    required Map<String, dynamic> template,
    required String storeName,
    required String storeAddress,
    required String storeRep,
    required String dtiMonitor,
    required DateTime monitoringDate,
    required MonitoringMode monitoringMode,
  }) {
    final products = (template['products'] as List?)
        ?.map((p) => MonitoringProduct.fromJson(p))
        .toList() ?? [];

    return MonitoringForm(
      storeName: storeName,
      storeAddress: storeAddress,
      monitoringDate: monitoringDate,
      monitoringMode: monitoringMode.displayName,
      storeRep: storeRep,
      dtiMonitor: dtiMonitor,
      products: products,
    );
  }

  // Calculate form statistics
  Map<String, dynamic> calculateFormStats(MonitoringForm form) {
    final products = form.products;
    final totalProducts = products.length;
    final compliantProducts = products.where((p) => p.isCompliant).length;
    final overpricedProducts = products.where((p) => p.isOverpriced).length;
    final averageDeviation = totalProducts > 0 
        ? products.map((p) => p.priceDeviationPercentage).reduce((a, b) => a + b) / totalProducts 
        : 0.0;

    return {
      'total_products': totalProducts,
      'compliant_products': compliantProducts,
      'overpriced_products': overpricedProducts,
      'compliance_rate': totalProducts > 0 ? (compliantProducts / totalProducts) * 100 : 0,
      'average_deviation': averageDeviation,
    };
  }

  // Clear current form
  void clearCurrentForm() {
    _currentForm = null;
    notifyListeners();
  }

  // Reset state
  void reset() {
    _monitoringForms.clear();
    _currentForm = null;
    _stats = null;
    _stores.clear();
    _productHistory.clear();
    _errorMessage = null;
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();
  }
}
