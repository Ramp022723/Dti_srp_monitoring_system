import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductApiService {
  static const String _baseUrl = 'https://dtisrpmonitoring.bccbsis.com/api/admin/product_price_management.php';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get all products with filters from DATABASE
  // This method fetches real product data from the database via API - no mock/sample data
  Future<List<Product>> getProducts({
    String? search,
    int? categoryId,
    double? priceMin,
    double? priceMax,
    int? folderId,
    int? mainFolderId,
    int? subFolderId,
    String sortBy = 'product_name',
    String sortOrder = 'ASC',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📊 ProductApiService: Fetching products from DATABASE...');
      print('📊 API Endpoint: admin/product_price_management.php');
      print('📊 Parameters: page=$page, limit=$limit, search=$search, categoryId=$categoryId');
      
      // Align query parameters with live API
      final Map<String, String> queryParams = {
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'page': page.toString(),
        // PHP expects `limit` (not per_page)
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (priceMin != null) queryParams['price_min'] = priceMin.toString();
      if (priceMax != null) queryParams['price_max'] = priceMax.toString();
      if (folderId != null) queryParams['folder_id'] = folderId.toString();
      if (mainFolderId != null) queryParams['main_folder_id'] = mainFolderId.toString();
      if (subFolderId != null) queryParams['sub_folder_id'] = subFolderId.toString();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print('📊 Database API URL: $uri');
      
      // Use Accept only for GET; omit JSON Content-Type to avoid 405s on some servers
      final response = await http.get(uri, headers: const {'Accept': 'application/json'});

      print('📊 Database API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dynamic successFlag = data['success'];
        final bool isSuccess = successFlag == true || successFlag == 'true' || successFlag == 1;
        
        if (isSuccess) {
          print('✅ Successfully retrieved products from DATABASE');
          
          // PHP returns products under data.products
          final List<dynamic> productsList =
              (data['data'] != null && data['data']['products'] is List)
                  ? (data['data']['products'] as List)
                  : <dynamic>[];
          
          final products = productsList
              .map((product) => Product.fromJson(product as Map<String, dynamic>))
              .toList();
          
          print('✅ Successfully parsed ${products.length} products from DATABASE');
          print('📊 All product data is from the database - no mock/sample data used');
          return products;
        } else {
          print('❌ Database API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to fetch products');
        }
      } else {
        final body = response.body.isNotEmpty ? response.body : '';
        print('❌ Database API returned status code: ${response.statusCode}');
        throw Exception('Failed to fetch products from database: ${response.statusCode} ${body}');
      }
    } catch (e) {
      print('❌ ProductApiService: Error fetching products from DATABASE: $e');
      print('❌ No mock data will be used - only real database data');
      throw Exception('Error fetching products from database: $e');
    }
  }

  // Get single product by ID
  Future<Product> getProduct(int productId) async {
    try {
      // PHP expects GET with ?id={product_id}
      final response = await http.get(
        Uri.parse('$_baseUrl?id=$productId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dynamic successFlag = data['success'];
        final bool isSuccess = successFlag == true || successFlag == 'true' || successFlag == 1;
        if (isSuccess) {
          // PHP returns the product in data (not product field)
          final dynamic payload = data['data'] ?? data['product'];
          return Product.fromJson((payload as Map<String, dynamic>));
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch product');
        }
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Create new product
  Future<Map<String, dynamic>> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'create_product',
          'data': product.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct(int productId, Product product) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'update_product',
          'id': productId,
          'data': product.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Update only SRP (with history tracking)
  Future<Map<String, dynamic>> updateSRP({
    required int productId,
    required double newSRP,
    required DateTime effectiveDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'update_srp',
          'product_id': productId,
          'srp': newSRP,
          'effective_date': effectiveDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update SRP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating SRP: $e');
    }
  }

  // Bulk update SRP
  Future<Map<String, dynamic>> bulkUpdateSRP({
    required List<int> productIds,
    required double newSRP,
    required DateTime effectiveDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'bulk_update_srp',
          'product_ids': productIds,
          'srp': newSRP,
          'effective_date': effectiveDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to bulk update SRP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error bulk updating SRP: $e');
    }
  }

  // Delete product
  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl?action=delete_product&id=$productId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  // Get SRP history for a product
  Future<List<SRPHistory>> getSRPHistory(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_srp_history&product_id=$productId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['history'] as List)
              .map((history) => SRPHistory.fromJson(history))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch SRP history');
        }
      } else {
        throw Exception('Failed to fetch SRP history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching SRP history: $e');
    }
  }

  // Get price analytics
  Future<PriceAnalytics> getPriceAnalytics({
    int? categoryId,
    int? folderId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      Map<String, String> queryParams = {'action': 'get_price_analytics'};

      if (categoryId != null) queryParams['category'] = categoryId.toString();
      if (folderId != null) queryParams['folder'] = folderId.toString();
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
          return PriceAnalytics.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch analytics');
        }
      } else {
        throw Exception('Failed to fetch analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Get categories from DATABASE
  // This method fetches real category data from the database via API - no mock/sample data
  Future<List<Category>> getCategories() async {
    try {
      print('📊 ProductApiService: Fetching categories from DATABASE...');
      print('📊 API Endpoint: admin/product_price_management.php?action=categories');
      
      // PHP endpoint uses action=categories
      final response = await http.get(
        Uri.parse('$_baseUrl?action=categories'),
        headers: _headers,
      );

      print('📊 Database Categories API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dynamic successFlag = data['success'];
        final bool isSuccess = successFlag == true || successFlag == 'true' || successFlag == 1;
        
        if (isSuccess) {
          print('✅ Successfully retrieved categories from DATABASE');
          
          final List categoriesRaw = (data['data'] != null && data['data']['categories'] is List)
              ? (data['data']['categories'] as List)
              : (data['categories'] as List? ?? <dynamic>[]);
          
          final categories = categoriesRaw.map((category) => Category.fromJson(category)).toList();
          
          print('✅ Successfully parsed ${categories.length} categories from DATABASE');
          print('📊 All category data is from the database - no mock/sample data used');
          return categories;
        } else {
          print('❌ Database Categories API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to fetch categories');
        }
      } else {
        print('❌ Database Categories API returned status code: ${response.statusCode}');
        throw Exception('Failed to fetch categories from database: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ProductApiService: Error fetching categories from DATABASE: $e');
      print('❌ No mock data will be used - only real database data');
      throw Exception('Error fetching categories from database: $e');
    }
  }

  // Get all folders (hierarchical or legacy)
  Future<List<Folder>> getFolders({bool hierarchical = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_folders&hierarchical=${hierarchical ? '1' : '0'}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (hierarchical) {
            return (data['folders'] as List)
                .map((folder) => Folder.fromJson(folder))
                .toList();
          } else {
            // Return both main and sub folders for legacy system
            final List<Folder> allFolders = [];
            if (data['main_folders'] != null) {
              allFolders.addAll((data['main_folders'] as List)
                  .map((folder) => Folder.fromJson(folder)));
            }
            if (data['sub_folders'] != null) {
              allFolders.addAll((data['sub_folders'] as List)
                  .map((folder) => Folder.fromJson(folder)));
            }
            return allFolders;
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch folders');
        }
      } else {
        throw Exception('Failed to fetch folders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching folders: $e');
    }
  }

  // Move products to folder
  Future<Map<String, dynamic>> moveProductsToFolder({
    required List<int> productIds,
    required int folderId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode({
          'action': 'move_to_folder',
          'product_ids': productIds,
          'folder_id': folderId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to move products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error moving products: $e');
    }
  }

  // Export products data
  Future<String> exportProducts({
    String format = 'csv',
    ProductFilters? filters,
  }) async {
    try {
      Map<String, String> queryParams = {
        'action': 'export_products',
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

  // Search products by barcode
  Future<Product?> searchByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=search_barcode&barcode=$barcode'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['product'] != null) {
          return Product.fromJson(data['product']);
        }
        return null;
      } else {
        throw Exception('Failed to search barcode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching barcode: $e');
    }
  }
}
