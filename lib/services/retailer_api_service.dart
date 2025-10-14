import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/retailer_model.dart';

class RetailerApiService {
  static const String _baseUrl = 'http://localhost/api/retailer_management.php';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get all retailer products with filters
  Future<List<RetailerProduct>> getRetailerProducts({
    String? retailerSearch,
    String? productSearch,
    String? anomalyFilter,
    int? retailerId,
    int? mainFolderId,
    int? subFolderId,
    String sortBy = 'retailer_username',
    String sortOrder = 'ASC',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_retailer_products',
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (retailerSearch != null && retailerSearch.isNotEmpty) {
        queryParams['retailer_filter'] = retailerSearch;
      }
      if (productSearch != null && productSearch.isNotEmpty) {
        queryParams['product_filter'] = productSearch;
      }
      if (anomalyFilter != null && anomalyFilter.isNotEmpty) {
        queryParams['anomaly_filter'] = anomalyFilter;
      }
      if (retailerId != null) queryParams['retailer_id'] = retailerId.toString();
      if (mainFolderId != null) queryParams['main_folder_id'] = mainFolderId.toString();
      if (subFolderId != null) queryParams['sub_folder_id'] = subFolderId.toString();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['products'] as List)
              .map((product) => RetailerProduct.fromJson(product))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailer products');
        }
      } else {
        throw Exception('Failed to fetch retailer products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching retailer products: $e');
    }
  }

  // Get all retailers
  Future<List<Retailer>> getRetailers({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_retailers',
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['retailers'] as List)
              .map((retailer) => Retailer.fromJson(retailer))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailers');
        }
      } else {
        throw Exception('Failed to fetch retailers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching retailers: $e');
    }
  }

  // Update retail price
  Future<Map<String, dynamic>> updateRetailPrice({
    required int retailPriceId,
    required double newPrice,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'update_price',
          'retail_price_id': retailPriceId,
          'new_price': newPrice,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update price: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating price: $e');
    }
  }

  // Get violation alerts
  Future<List<ViolationAlert>> getViolationAlerts({
    String? status,
    String? severity,
    int? retailerId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_violation_alerts',
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (severity != null && severity.isNotEmpty) {
        queryParams['severity'] = severity;
      }
      if (retailerId != null) {
        queryParams['retailer_id'] = retailerId.toString();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['alerts'] as List)
              .map((alert) => ViolationAlert.fromJson(alert))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch alerts');
        }
      } else {
        throw Exception('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  // Update violation alert status
  Future<Map<String, dynamic>> updateViolationAlertStatus({
    required int alertId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'update_alert_status',
          'alert_id': alertId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update alert status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating alert status: $e');
    }
  }

  // Get retailer statistics
  Future<RetailerStats> getRetailerStats({
    int? retailerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      Map<String, String> queryParams = {'action': 'get_stats'};

      if (retailerId != null) {
        queryParams['retailer_id'] = retailerId.toString();
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return RetailerStats.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch stats');
        }
      } else {
        throw Exception('Failed to fetch stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  // Send violation notification
  Future<Map<String, dynamic>> sendViolationNotification({
    required int retailerId,
    required int productId,
    required String violationType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'send_violation_notification',
          'retailer_id': retailerId,
          'product_id': productId,
          'violation_type': violationType,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  // Get retailer compliance report
  Future<Map<String, dynamic>> getComplianceReport({
    int? retailerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      Map<String, String> queryParams = {'action': 'get_compliance_report'};

      if (retailerId != null) {
        queryParams['retailer_id'] = retailerId.toString();
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch compliance report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching compliance report: $e');
    }
  }

  // Export retailer data
  Future<String> exportRetailerData({
    String format = 'csv',
    RetailerFilters? filters,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'export_data',
        'format': format,
      };

      if (filters != null) {
        queryParams.addAll(filters.toQueryParameters());
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['download_url'] ?? '';
        } else {
          throw Exception(data['message'] ?? 'Failed to export data');
        }
      } else {
        throw Exception('Failed to export data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting data: $e');
    }
  }
}
