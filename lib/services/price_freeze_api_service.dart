import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_freeze_model.dart';

class PriceFreezeApiService {
  static const String _baseUrl = 'http://localhost/api/price_freeze_management.php';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get all alerts
  Future<List<PriceFreezeAlert>> getAlerts({
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_alerts',
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
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
          return (data['alerts'] as List)
              .map((alert) => PriceFreezeAlert.fromJson(alert))
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

  // Get single alert
  Future<PriceFreezeAlert> getAlert(int alertId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_alert&id=$alertId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return PriceFreezeAlert.fromJson(data['alert']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch alert');
        }
      } else {
        throw Exception('Failed to fetch alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching alert: $e');
    }
  }

  // Create new alert
  Future<Map<String, dynamic>> createAlert(CreateAlertRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'create_alert',
          'data': request.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating alert: $e');
    }
  }

  // Update alert status
  Future<Map<String, dynamic>> updateAlertStatus({
    required int alertId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'update_status',
          'alert_id': alertId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  // Delete alert
  Future<Map<String, dynamic>> deleteAlert(int alertId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl?action=delete_alert&id=$alertId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete alert: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting alert: $e');
    }
  }

  // Get statistics
  Future<PriceFreezeStats> getStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      Map<String, String> queryParams = {'action': 'get_stats'};

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
          return PriceFreezeStats.fromJson(data);
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

  // Get products for selection
  Future<List<Product>> getProducts({String? search}) async {
    try {
      Map<String, String> queryParams = {'action': 'get_products'};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['products'] as List)
              .map((product) => Product.fromJson(product))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch products');
        }
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get categories for selection
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_categories'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['categories'] as List)
              .map((category) => Category.fromJson(category))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get locations for selection
  Future<List<Location>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_locations'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['locations'] as List)
              .map((location) => Location.fromJson(location))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch locations');
        }
      } else {
        throw Exception('Failed to fetch locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching locations: $e');
    }
  }

  // Get notifications for an alert
  Future<List<PriceFreezeNotification>> getAlertNotifications(int alertId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_alert_notifications&alert_id=$alertId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['notifications'] as List)
              .map((notif) => PriceFreezeNotification.fromJson(notif))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch notifications');
        }
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Resend notifications for an alert
  Future<Map<String, dynamic>> resendNotifications(int alertId) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'resend_notifications',
          'alert_id': alertId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to resend notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resending notifications: $e');
    }
  }

  // Export alerts data
  Future<String> exportAlerts({
    String format = 'csv',
    AlertFilters? filters,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'export_alerts',
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
