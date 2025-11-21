import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/retailer_model.dart';

class RetailerApiService {
  static const String _baseUrl = 'https://dtisrpmonitoring.bccbsis.com/api/admin/store_prices.php';

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> get _browserLikeGetHeaders => {
    'Accept': 'application/json, text/plain, */*',
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'no-cache',
  };

  // Test API connectivity
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse(_baseUrl);
      
      // Try with browser-like headers first
      var response = await http.get(uri, headers: _browserLikeGetHeaders);
      
      // If 401/403, try without any headers as fallback
      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http.get(uri);
      }
      
      print('Connection test - Status: ${response.statusCode}');
      print('Connection test - Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Get all retailer products with filters from store_prices.php API
  // This method fetches real product data from the database via store_prices.php - no mock/sample data
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
      print('📊 RetailerApiService: Fetching retailer products from DATABASE...');
      print('📊 API Endpoint: admin/store_prices.php?action=get_retailer_products');
      
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
      print('📊 Database API URL: $uri');
      
      final response = await http.get(uri, headers: _browserLikeGetHeaders);
      
      print('📊 Database API Response Status: ${response.statusCode}');
      print('📊 Database API Response Body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          final success = data['success'] ?? false;
          
          if (success == true) {
            print('✅ Successfully retrieved products from DATABASE via store_prices.php');
            
            // Handle different response structures from store_prices.php
            final productsData = data['products'] ?? 
                                data['data'] ?? 
                                (data['data'] is Map ? data['data']['products'] : null) ?? 
                                [];
            
            if (productsData is List) {
              try {
                final products = productsData
                    .map((product) {
                      return RetailerProduct.fromJson(product as Map<String, dynamic>);
                    })
                    .toList();
                
                print('✅ Successfully parsed ${products.length} products from DATABASE');
                print('📊 All product data is from store_prices.php API - no mock/sample data used');
                return products;
              } catch (e) {
                print('❌ Error processing products: $e');
                throw Exception('Error parsing product data from store_prices.php: $e');
              }
            } else {
              print('⚠️ Products data is not a list, returning empty list');
              return [];
            }
          } else {
            final message = data['message'] ?? 'Failed to fetch retailer products from store_prices.php';
            print('❌ Database API returned success=false: $message');
            throw Exception(message);
          }
        } catch (e) {
          print('❌ Error parsing JSON response from store_prices.php: $e');
          throw Exception('Error parsing API response from store_prices.php: $e');
        }
      } else {
        print('❌ Database API returned status code: ${response.statusCode}');
        throw Exception('Failed to fetch retailer products from store_prices.php: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ RetailerApiService: Error fetching retailer products from store_prices.php: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ No mock data will be used - only real database data from store_prices.php');
      throw Exception('Error fetching retailer products from store_prices.php: $e');
    }
  }

  // Get store prices from the public store_prices.php endpoint (no action param, returns `prices`)
  // This method fetches real product prices from the database via store_prices.php - no mock/sample data
  Future<List<RetailerProduct>> getStorePrices() async {
    try {
      print('📊 RetailerApiService: Fetching store prices from DATABASE...');
      print('📊 API Endpoint: admin/store_prices.php (public endpoint)');
      
      final uri = Uri.parse(_baseUrl);
      print('📊 Database API URL: $uri');
      
      // Try with browser-like headers first
      var response = await http.get(uri, headers: _browserLikeGetHeaders);
      
      // If 401/403, try without any headers as fallback
      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http.get(uri);
      }

      print('📊 Database API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Successfully retrieved store prices from DATABASE via store_prices.php');
        
        final data = json.decode(response.body);
        
        // Handle different response structures from store_prices.php
        final prices = data['prices'] ?? 
                      data['data'] ?? 
                      (data['data'] is Map ? data['data']['prices'] : null) ?? 
                      [];
        
        if (prices is List) {
          final products = prices
              .map((item) => RetailerProduct.fromJson(item as Map<String, dynamic>))
              .toList();
          
          print('✅ Successfully parsed ${products.length} store prices from DATABASE');
          print('📊 All store prices are from store_prices.php API - no mock/sample data used');
          return products;
        }
        
        print('⚠️ Prices data is not a list, returning empty list');
        return [];
      } else {
        print('❌ Database API returned status code: ${response.statusCode}');
        throw Exception('Failed to fetch store prices from store_prices.php: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ RetailerApiService: Error fetching store prices from store_prices.php: $e');
      print('❌ No mock data will be used - only real database data from store_prices.php');
      throw Exception('Error fetching store prices from store_prices.php: $e');
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
      final response = await http.get(uri, headers: _browserLikeGetHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final success = data['success'] ?? false;
        if (success == true) {
          final retailersData = data['retailers'] ?? data['data'] ?? [];
          if (retailersData is List) {
            return retailersData
                .map((retailer) => Retailer.fromJson(retailer))
                .toList();
          } else {
            return [];
          }
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
        headers: _jsonHeaders,
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
      final response = await http.get(uri, headers: _browserLikeGetHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final success = data['success'] ?? false;
        if (success == true) {
          final alertsData = data['alerts'] ?? data['data'] ?? [];
          if (alertsData is List) {
            return alertsData
                .map((alert) => ViolationAlert.fromJson(alert))
                .toList();
          } else {
            return [];
          }
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
        headers: _jsonHeaders,
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
      final response = await http.get(uri, headers: _browserLikeGetHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final success = data['success'] ?? false;
        if (success == true) {
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
        headers: _jsonHeaders,
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
      final response = await http.get(uri, headers: _browserLikeGetHeaders);

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
      final response = await http.get(uri, headers: _browserLikeGetHeaders);

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
