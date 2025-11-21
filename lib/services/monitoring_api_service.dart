import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monitoring_model.dart';

class MonitoringApiService {
  static const String _baseUrl = 'https://dtisrpmonitoring.bccbsis.com/api/admin/price_monitoring_management.php';

  // Headers for all requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Create a new monitoring form
  Future<Map<String, dynamic>> createMonitoringForm(MonitoringForm form) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'create_form',
          'data': form.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create monitoring form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating monitoring form: $e');
    }
  }

  // Get all monitoring forms
  Future<List<MonitoringForm>> getMonitoringForms({
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_forms',
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (storeName != null && storeName.isNotEmpty) {
        queryParams['store_name'] = storeName;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['forms'] as List)
              .map((form) => MonitoringForm.fromJson(form))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch monitoring forms');
        }
      } else {
        throw Exception('Failed to fetch monitoring forms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching monitoring forms: $e');
    }
  }

  // Get a specific monitoring form by ID
  Future<MonitoringForm> getMonitoringForm(int formId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_form&id=$formId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return MonitoringForm.fromJson(data['form']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch monitoring form');
        }
      } else {
        throw Exception('Failed to fetch monitoring form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching monitoring form: $e');
    }
  }

  // Update a monitoring form
  Future<Map<String, dynamic>> updateMonitoringForm(int formId, MonitoringForm form) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'update_form',
          'id': formId,
          'data': form.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update monitoring form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating monitoring form: $e');
    }
  }

  // Delete a monitoring form
  Future<Map<String, dynamic>> deleteMonitoringForm(int formId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl?action=delete_form&id=$formId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete monitoring form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting monitoring form: $e');
    }
  }

  // Get monitoring statistics
  Future<MonitoringStats> getMonitoringStats({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
  }) async {
    try {
      Map<String, String> queryParams = {'action': 'get_stats'};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (storeName != null && storeName.isNotEmpty) {
        queryParams['store_name'] = storeName;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return MonitoringStats.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch monitoring stats');
        }
      } else {
        throw Exception('Failed to fetch monitoring stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching monitoring stats: $e');
    }
  }

  // Get store statistics
  Future<List<Store>> getStoreStats({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_store_stats',
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
          return (data['stores'] as List)
              .map((store) => Store.fromJson(store))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch store stats');
        }
      } else {
        throw Exception('Failed to fetch store stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching store stats: $e');
    }
  }

  // Get product monitoring history
  Future<List<Map<String, dynamic>>> getProductMonitoringHistory({
    String? productName,
    String? storeName,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'get_product_history',
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (productName != null && productName.isNotEmpty) {
        queryParams['product_name'] = productName;
      }
      if (storeName != null && storeName.isNotEmpty) {
        queryParams['store_name'] = storeName;
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
          return List<Map<String, dynamic>>.from(data['history']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch product history');
        }
      } else {
        throw Exception('Failed to fetch product history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product history: $e');
    }
  }

  // Export monitoring data
  Future<String> exportMonitoringData({
    String format = 'json', // json, csv, xlsx
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'export_data',
        'format': format,
      };

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (storeName != null && storeName.isNotEmpty) {
        queryParams['store_name'] = storeName;
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

  // Get monitoring form templates
  Future<List<Map<String, dynamic>>> getMonitoringTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_templates'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['templates']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch templates');
        }
      } else {
        throw Exception('Failed to fetch templates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching templates: $e');
    }
  }

  // Save monitoring form as template
  Future<Map<String, dynamic>> saveMonitoringTemplate({
    required String templateName,
    required String description,
    required List<MonitoringProduct> products,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'save_template',
          'template_name': templateName,
          'description': description,
          'products': products.map((p) => p.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save template: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving template: $e');
    }
  }
}
