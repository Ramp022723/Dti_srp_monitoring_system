import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_user.dart';

/// Admin Management Service
/// 
/// This service provides CRUD operations for admin users using the admin_management.php API.
/// It matches the PHP API structure exactly for seamless integration.
/// 
/// PHP API: admin_management.php
/// - GET: Fetch admin users (all or specific by ID)
/// - POST: Create new admin user
/// - PUT: Update existing admin user
/// - DELETE: Delete admin user
class AdminManagementService {
  // Update this URL to match your PHP backend server
  static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";
  
  // Admin Management API endpoint
  static const String adminManagementEndpoint = "admin_management.php";

  // ================= FETCH ALL ADMIN USERS =================
  /// Fetches all admin users from the server
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - users: List of AdminUser objects (if successful)
  /// - count: Total number of users
  /// - code: API response code
  static Future<Map<String, dynamic>> getAllAdminUsers() async {
    try {
      print('🔍 AdminManagementService: Fetching all admin users...');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 AdminManagementService: Response Status: ${response.statusCode}');
      print('📊 AdminManagementService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          // admin_management.php returns data as an array directly
          final List<dynamic> usersData = data['data'] ?? [];
          final List<AdminUser> users = usersData
              .map((userData) => AdminUser.fromJson(userData))
              .toList();

          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin users fetched successfully',
            'users': users,
            'count': data['count'] ?? users.length,
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
      print('❌ AdminManagementService: Error fetching users: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_ERROR'
      };
    }
  }

  // ================= GET SINGLE ADMIN USER =================
  /// Fetches a specific admin user by ID
  /// 
  /// [adminId] - The ID of the admin user to fetch
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - user: AdminUser object (if successful)
  /// - code: API response code
  static Future<Map<String, dynamic>> getAdminUser({required int adminId}) async {
    try {
      print('🔍 AdminManagementService: Fetching admin user: $adminId');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint?id=$adminId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 AdminManagementService: GET Response Status: ${response.statusCode}');
      print('📊 AdminManagementService: GET Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && data['data'] != null) {
          final user = AdminUser.fromJson(data['data']);
          
          return {
            'status': 'success',
            'message': data['message'] ?? 'Admin user fetched successfully',
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
      print('❌ AdminManagementService: Error fetching user: $e');
      return {
        'status': 'error',
        'message': 'Failed to fetch user: $e',
        'code': 'FETCH_ERROR'
      };
    }
  }

  // ================= CREATE ADMIN USER =================
  /// Creates a new admin user
  /// 
  /// Required parameters:
  /// - [adminType] - Type of admin ('admin' or 'barangay_admin')
  /// - [firstName] - First name
  /// - [lastName] - Last name
  /// - [middleName] - Middle name (can be empty)
  /// - [username] - Unique username
  /// - [password] - Password for the user
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - user: Created AdminUser object (if successful)
  /// - code: API response code
  static Future<Map<String, dynamic>> createAdminUser({
    required String adminType,
    required String firstName,
    required String lastName,
    required String middleName,
    required String username,
    required String password,
  }) async {
    try {
      print('📝 AdminManagementService: Creating admin user: $username');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint');
      
      final requestBody = {
        'admin_type': adminType,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'username': username,
        'password': password,
      };

      print('📤 AdminManagementService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AdminManagementService: CREATE Response Status: ${response.statusCode}');
      print('📊 AdminManagementService: CREATE Response Body: ${response.body}');

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
      print('❌ AdminManagementService: Error creating user: $e');
      return {
        'status': 'error',
        'message': 'Failed to create user: $e',
        'code': 'CREATE_ERROR'
      };
    }
  }

  // ================= UPDATE ADMIN USER =================
  /// Updates an existing admin user
  /// 
  /// Required parameters:
  /// - [adminId] - ID of the admin user to update
  /// - [adminType] - Type of admin ('admin' or 'barangay_admin')
  /// - [firstName] - First name
  /// - [lastName] - Last name
  /// - [middleName] - Middle name (can be empty)
  /// - [username] - Username
  /// 
  /// Note: Password updates are not supported in this method for security reasons
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - user: Updated AdminUser object (if successful)
  /// - code: API response code
  static Future<Map<String, dynamic>> updateAdminUser({
    required int adminId,
    required String adminType,
    required String firstName,
    required String lastName,
    required String middleName,
    required String username,
  }) async {
    try {
      print('✏️ AdminManagementService: Updating admin user: $adminId');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint');
      
      final requestBody = {
        'admin_id': adminId,
        'admin_type': adminType,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'username': username,
      };

      print('📤 AdminManagementService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AdminManagementService: UPDATE Response Status: ${response.statusCode}');
      print('📊 AdminManagementService: UPDATE Response Body: ${response.body}');

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
      print('❌ AdminManagementService: Error updating user: $e');
      return {
        'status': 'error',
        'message': 'Failed to update user: $e',
        'code': 'UPDATE_ERROR'
      };
    }
  }

  // ================= DELETE ADMIN USER =================
  /// Deletes an admin user
  /// 
  /// [adminId] - ID of the admin user to delete
  /// 
  /// Note: The PHP API prevents deletion of super_admin users
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - code: API response code
  static Future<Map<String, dynamic>> deleteAdminUser({
    required int adminId,
  }) async {
    try {
      print('🗑️ AdminManagementService: Deleting admin user: $adminId');
      
      final url = Uri.parse('$baseUrl/$adminManagementEndpoint?id=$adminId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 AdminManagementService: DELETE Response Status: ${response.statusCode}');
      print('📊 AdminManagementService: DELETE Response Body: ${response.body}');

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
      } else if (response.statusCode == 403) {
        return {
          'status': 'error',
          'message': 'Cannot delete Super Admin',
          'code': 'SUPER_ADMIN_NOT_ALLOWED',
          'http_status': 403
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
      print('❌ AdminManagementService: Error deleting user: $e');
      return {
        'status': 'error',
        'message': 'Failed to delete user: $e',
        'code': 'DELETE_ERROR'
      };
    }
  }

  // ================= UTILITY METHODS =================
  
  /// Validates admin type
  /// 
  /// [adminType] - The admin type to validate
  /// 
  /// Returns true if valid, false otherwise
  static bool isValidAdminType(String adminType) {
    return ['admin', 'barangay_admin'].contains(adminType.toLowerCase());
  }

  /// Gets the display name for an admin type
  /// 
  /// [adminType] - The admin type
  /// 
  /// Returns formatted display name
  static String getAdminTypeDisplay(String adminType) {
    switch (adminType.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'barangay_admin':
        return 'Barangay Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return adminType;
    }
  }

  /// Validates required fields for creating/updating admin users
  /// 
  /// Returns a map with validation result and message
  static Map<String, dynamic> validateAdminUserData({
    required String adminType,
    required String firstName,
    required String lastName,
    required String username,
    String? password, // Only required for creation
    bool isUpdate = false,
  }) {
    // Check required fields
    if (adminType.trim().isEmpty) {
      return {
        'valid': false,
        'message': 'Admin type is required',
        'field': 'admin_type'
      };
    }

    if (firstName.trim().isEmpty) {
      return {
        'valid': false,
        'message': 'First name is required',
        'field': 'first_name'
      };
    }

    if (lastName.trim().isEmpty) {
      return {
        'valid': false,
        'message': 'Last name is required',
        'field': 'last_name'
      };
    }

    if (username.trim().isEmpty) {
      return {
        'valid': false,
        'message': 'Username is required',
        'field': 'username'
      };
    }

    // Password is only required for creation
    if (!isUpdate && (password == null || password.trim().isEmpty)) {
      return {
        'valid': false,
        'message': 'Password is required',
        'field': 'password'
      };
    }

    // Validate admin type
    if (!isValidAdminType(adminType)) {
      return {
        'valid': false,
        'message': 'Invalid admin type. Must be admin or barangay_admin',
        'field': 'admin_type'
      };
    }

    // Prevent super admin creation
    if (adminType.toLowerCase() == 'super_admin') {
      return {
        'valid': false,
        'message': 'Cannot create Super Admin users',
        'field': 'admin_type'
      };
    }

    return {
      'valid': true,
      'message': 'Validation passed'
    };
  }
}
