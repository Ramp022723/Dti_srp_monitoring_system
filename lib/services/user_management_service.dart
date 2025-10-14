import 'dart:convert';
import 'package:http/http.dart' as http;
import '../admin/admin_user.dart';

class UserManagementService {
  // Update this URL to match your PHP backend server
  static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";

  // Admin Management API endpoint
  static const String adminManagementEndpoint = "admin/admin_users.php";

  // ================= FETCH ALL ADMIN USERS =================
  static Future<Map<String, dynamic>> getAllAdminUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      print('🔍 UserManagementService: Fetching admin users...');
      
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/$adminManagementEndpoint').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 UserManagementService: Response Status: ${response.statusCode}');
      print('📊 UserManagementService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          // admin_users.php returns data as an array directly
          final List<dynamic> usersData = data['data'] ?? [];
          final List<AdminUser> users = usersData
              .map((userData) => AdminUser.fromJson(userData))
              .toList();

          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin users retrieved successfully',
            'users': users,
            'total': data['count'] ?? users.length,
            'page': page,
            'limit': limit,
            'code': data['code'] ?? 'ADMINS_FETCHED',
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to fetch admin users',
            'code': data['code'] ?? 'FETCH_FAILED'
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'SERVER_ERROR'
        };
      }
    } catch (e) {
      print('❌ UserManagementService: Error fetching users: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_ERROR'
      };
    }
  }

  // ================= CREATE ADMIN USER =================
  static Future<Map<String, dynamic>> createAdminUser({
    required String adminType,
    required String firstName,
    required String lastName,
    required String middleName,
    required String username,
    required String password,
  }) async {
    try {
      print('📝 UserManagementService: Creating admin user: $username');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint');
      
      final requestBody = {
        'admin_type': adminType,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'username': username,
        'password': password,
      };

      print('📤 UserManagementService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 UserManagementService: CREATE Response Status: ${response.statusCode}');
      print('📊 UserManagementService: CREATE Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          AdminUser? user;
          if (data['data'] != null) {
            user = AdminUser.fromJson(data['data']);
          }
          
          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin user created successfully',
            'user': user,
            'code': data['code'] ?? 'ADMIN_CREATED'
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to create admin user',
            'code': data['code'] ?? 'CREATE_FAILED'
          };
        }
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Server error occurred',
          'code': data['code'] ?? 'SERVER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ UserManagementService: Error creating user: $e');
      return {
        'status': 'error',
        'message': 'Failed to create user: $e',
        'code': 'CREATE_ERROR'
      };
    }
  }

  // ================= UPDATE ADMIN USER =================
  static Future<Map<String, dynamic>> updateAdminUser({
    required int adminId,
    required String adminType,
    required String firstName,
    required String lastName,
    required String middleName,
    required String username,
  }) async {
    try {
      print('✏️ UserManagementService: Updating admin user: $adminId');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint');
      
      final requestBody = {
        'admin_id': adminId,
        'admin_type': adminType,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'username': username,
      };

      print('📤 UserManagementService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 UserManagementService: UPDATE Response Status: ${response.statusCode}');
      print('📊 UserManagementService: UPDATE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          AdminUser? user;
          if (data['data'] != null) {
            user = AdminUser.fromJson(data['data']);
          }
          
          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin user updated successfully',
            'user': user,
            'code': data['code'] ?? 'ADMIN_UPDATED'
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to update admin user',
            'code': data['code'] ?? 'UPDATE_FAILED'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Admin user not found',
          'code': 'ADMIN_NOT_FOUND',
          'http_status': 404
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Server error occurred',
          'code': data['code'] ?? 'SERVER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ UserManagementService: Error updating user: $e');
      return {
        'status': 'error',
        'message': 'Failed to update user: $e',
        'code': 'UPDATE_ERROR'
      };
    }
  }

  // ================= DELETE ADMIN USER =================
  static Future<Map<String, dynamic>> deleteAdminUser({
    required int adminId,
    bool softDelete = true,
  }) async {
    try {
      print('🗑️ UserManagementService: Deleting admin user: $adminId (Soft: $softDelete)');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint?admin_id=$adminId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 UserManagementService: DELETE Response Status: ${response.statusCode}');
      print('📊 UserManagementService: DELETE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin user deleted successfully',
            'code': data['code'] ?? 'ADMIN_DELETED'
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to delete admin user',
            'code': data['code'] ?? 'DELETE_FAILED'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Admin user not found',
          'code': 'ADMIN_NOT_FOUND',
          'http_status': 404
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Server error occurred',
          'code': data['code'] ?? 'SERVER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ UserManagementService: Error deleting user: $e');
      return {
        'status': 'error',
        'message': 'Failed to delete user: $e',
        'code': 'DELETE_ERROR'
      };
    }
  }

  // ================= GET SINGLE ADMIN USER =================
  static Future<Map<String, dynamic>> getAdminUser({required int adminId}) async {
    try {
      print('🔍 UserManagementService: Fetching admin user: $adminId');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint?admin_id=$adminId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 UserManagementService: GET Response Status: ${response.statusCode}');
      print('📊 UserManagementService: GET Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && data['data'] != null) {
          final user = AdminUser.fromJson(data['data']);
          
          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin user retrieved successfully',
            'user': user,
            'code': data['code'] ?? 'ADMIN_FETCHED'
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Admin user not found',
            'code': data['code'] ?? 'ADMIN_NOT_FOUND'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Admin user not found',
          'code': 'ADMIN_NOT_FOUND',
          'http_status': 404
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Server error occurred',
          'code': data['code'] ?? 'SERVER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ UserManagementService: Error fetching user: $e');
      return {
        'status': 'error',
        'message': 'Failed to fetch user: $e',
        'code': 'FETCH_ERROR'
      };
    }
  }
}
