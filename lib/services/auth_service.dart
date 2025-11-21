import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Update this URL to match your PHP backend server
  static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";
  
  // Session cookie for maintaining login state
  static String? _sessionCookie;
  static String? _cachedRetailerId; // cached user id fallback

  // ================= SESSION MANAGEMENT =================
  
  // Set session cookie from login response
  static Future<void> _setSessionCookie(http.Response response) async {
    print('🔐 AuthService: Checking for session cookie in response...');
    print('🔐 AuthService: Response headers: ${response.headers}');
    
    final setCookieHeader = response.headers['set-cookie'];
    print('🔐 AuthService: Set-Cookie header: $setCookieHeader');
    
    if (setCookieHeader != null) {
      // Extract PHPSESSID from the set-cookie header
      final regex = RegExp(r'PHPSESSID=([^;]+)');
      final match = regex.firstMatch(setCookieHeader);
      if (match != null) {
        _sessionCookie = 'PHPSESSID=${match.group(1)}';
        print('🔐 AuthService: Session cookie set: $_sessionCookie');
        
        // Persist the session cookie
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('PHPSESSID', _sessionCookie!);
          print('🔐 AuthService: Session cookie persisted to SharedPreferences.');
        } catch (e) {
          print('❌ AuthService: Error persisting session cookie: $e');
        }
      } else {
        print('🔐 AuthService: No PHPSESSID found in set-cookie header');
      }
    } else {
      print('🔐 AuthService: No set-cookie header found in response');
    }
  }
  
  // Get session cookie for requests
  static String? getSessionCookie() {
    print('🔍 AuthService: getSessionCookie() called. Current cookie: $_sessionCookie');
    return _sessionCookie;
  }

  // Initialize AuthService and load persisted session
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Using fixed API base URL
      print('🌐 AuthService: Using API base URL: $baseUrl');
      _sessionCookie = prefs.getString('PHPSESSID');
      _cachedRetailerId = prefs.getString('last_retailer_id');
      print('🔐 AuthService: Initialized. Loaded session cookie: $_sessionCookie');
      print('🗃️ AuthService: Loaded cached retailer id: $_cachedRetailerId');
      
      if (_sessionCookie != null) {
        // Attempt to get current user if a session cookie exists
        await getCurrentUser();
      }
    } catch (e) {
      print('❌ AuthService: Error during initialization: $e');
    }
  }
  
  // Clear session cookie on logout
  static Future<void> _clearSessionCookie() async {
    _sessionCookie = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('PHPSESSID');
      print('🔐 AuthService: Session cookie cleared from memory and SharedPreferences.');
    } catch (e) {
      print('❌ AuthService: Error clearing session cookie: $e');
    }
  }

  // ================= LOGIN TESTING =================
  static Future<Map<String, dynamic>> testLogin(String username, String password) async {
    try {
      print('🧪 AuthService: Testing login for user: $username');
      
      final result = await login(username, password, userType: 'retailer');
      
      print('🧪 AuthService: Login test result: $result');
      print('🧪 AuthService: Result status: ${result['status']}');
      print('🧪 AuthService: Result type: ${result.runtimeType}');
      print('🧪 AuthService: Result keys: ${result.keys.toList()}');
      
      return {
        'status': 'success',
        'test_result': result,
        'session_cookie': getSessionCookie(),
      };
    } catch (e) {
      print('❌ AuthService: Login test failed: $e');
      return {
        'status': 'error',
        'message': 'Login test failed: $e',
      };
    }
  }

  // ================= SESSION TESTING =================
  static Future<Map<String, dynamic>> testSessionEndpoints() async {
    try {
      print('🔍 AuthService: Testing session endpoints...');
      
      // Test check-session endpoint
      final sessionUrl = Uri.parse('$baseUrl/check-session.php');
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'login_app/1.0',
      };
      
      final sessionCookie = getSessionCookie();
      if (sessionCookie != null) {
        headers['Cookie'] = sessionCookie;
        print('🔍 AuthService: Testing with cookie: $sessionCookie');
      } else {
        print('🔍 AuthService: No session cookie available');
      }
      
      final sessionResponse = await http.get(sessionUrl, headers: headers);
      print('🔍 AuthService: check-session response: ${sessionResponse.statusCode} - ${sessionResponse.body}');
      
      // Test get-current-user endpoint
      final userUrl = Uri.parse('$baseUrl/get-current-user.php');
      final userResponse = await http.get(userUrl, headers: headers);
      print('🔍 AuthService: get-current-user response: ${userResponse.statusCode} - ${userResponse.body}');
      
      return {
        'status': 'success',
        'session_check': {
          'status_code': sessionResponse.statusCode,
          'body': sessionResponse.body,
          'headers': sessionResponse.headers,
        },
        'user_check': {
          'status_code': userResponse.statusCode,
          'body': userResponse.body,
          'headers': userResponse.headers,
        }
      };
    } catch (e) {
      print('❌ AuthService: Session endpoint test failed: $e');
      return {
        'status': 'error',
        'message': 'Session endpoint test failed: $e',
      };
    }
  }

  // ================= API CONNECTIVITY TEST =================
  static Future<Map<String, dynamic>> testApiConnectivity() async {
    try {
      print('🔍 AuthService: Testing API connectivity...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/test-connection.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 Test API Response Status: ${response.statusCode}');
      print('📊 Test API Response Body: ${response.body}');

      return {
        'status': response.statusCode == 200 ? 'success' : 'error',
        'message': response.statusCode == 200 ? 'API is reachable' : 'API returned ${response.statusCode}',
        'http_status': response.statusCode,
        'response_body': response.body,
      };
    } catch (e) {
      print('❌ AuthService: API connectivity test failed: $e');
      return {
        'status': 'error',
        'message': 'Cannot reach API server: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= ENHANCED LOGIN WITH ROLE-BASED FLOW =================
  static Future<Map<String, dynamic>> login(
      String username, String password, {String? userType}) async {
    
    print('🔐 AuthService: Starting login process for user: $username');
    
    try {
      // Step 1: Validate input data
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return {
          'status': 'error',
          'message': 'Username and password are required',
          'code': 'VALIDATION_ERROR'
        };
      }

      print('✅ AuthService: Input validation passed');

      // Step 2: Use separate login endpoints for each user type
      String endpoint;
      switch (userType?.toLowerCase()) {
        case 'admin':
          endpoint = 'admin_login.php';
          break;
        case 'consumer':
          endpoint = 'consumer_login.php';
          break;
        case 'retailer':
          endpoint = 'retailer_login.php';
          break;
        default:
          endpoint = 'login.php'; // Fallback to generic login
          break;
      }
      
      final url = Uri.parse('$baseUrl/$endpoint');
      print('📡 AuthService: Sending request to: $url (User Type: $userType, Endpoint: $endpoint)');

      final requestBody = {
        'username': username.trim(),
        'password': password,
      };

      print('📤 AuthService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: API Response Status: ${response.statusCode}');
      print('📊 AuthService: API Response Headers: ${response.headers}');
      print('📊 AuthService: API Response Body (first 1000 chars): ${response.body.length > 1000 ? response.body.substring(0, 1000) + '...' : response.body}');

      // Step 3: Handle HTTP error status codes
      if (response.statusCode == 500) {
        print('❌ AuthService: Internal server error (500)');
        return {
          'status': 'error',
          'message': 'Internal server error. Please check your PHP server logs for details.',
          'code': 'INTERNAL_SERVER_ERROR',
          'http_status': 500,
          'server_response': response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body
        };
      }

      if (response.statusCode == 404) {
        print('❌ AuthService: API endpoint not found (404)');
        return {
          'status': 'error',
          'message': 'API endpoint not found. Please verify your server URL: $baseUrl/$endpoint',
          'code': 'ENDPOINT_NOT_FOUND',
          'http_status': 404
        };
      }

      if (response.statusCode >= 400) {
        print('❌ AuthService: HTTP error ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'HTTP error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
          'server_response': response.body.length > 300 ? response.body.substring(0, 300) + '...' : response.body
        };
      }

      // Step 4: Validate response format
      if (response.body.trim().startsWith('<') || 
          response.body.contains('<!DOCTYPE') || 
          response.body.contains('<html>')) {
        print('❌ AuthService: Server returned HTML instead of JSON');
        return {
          'status': 'error',
          'message': 'Server returned HTML instead of JSON. Please check your API endpoint.',
          'code': 'INVALID_RESPONSE_FORMAT'
        };
      }

      if (response.body.trim().isEmpty) {
        print('❌ AuthService: Server returned empty response');
        return {
          'status': 'error',
          'message': 'Server returned empty response. Status: ${response.statusCode}',
          'code': 'EMPTY_RESPONSE'
        };
      }

      // Step 4: Parse JSON response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
        print('📋 AuthService: Successfully parsed JSON response');
        print('📋 AuthService: Response status: ${data['status']}');
        print('📋 AuthService: Response message: ${data['message']}');
        print('📋 AuthService: Response keys: ${data.keys.toList()}');
        if (data['data'] != null) {
          print('📋 AuthService: Data object keys: ${(data['data'] as Map).keys.toList()}');
        }
      } catch (e) {
        print('❌ AuthService: Failed to parse JSON response: $e');
        print('❌ AuthService: Raw response: ${response.body}');
        return {
          'status': 'error',
          'message': 'Invalid JSON response from server. Please contact support.',
          'code': 'INVALID_JSON_RESPONSE',
          'raw_response': response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)
        };
      }

      // Step 5: Validate response structure
      if (data['status'] == null) {
        print('❌ AuthService: Response missing status field');
        return {
          'status': 'error',
          'message': 'Invalid API response format. Missing status field.',
          'code': 'INVALID_RESPONSE_STRUCTURE'
        };
      }

      // Step 6: Handle successful login
      if (response.statusCode == 200 && data['status'] == 'success') {
        print('✅ AuthService: Login successful');
        
        // Capture session cookie for future API calls
        await _setSessionCookie(response);
        
        // Handle retailer_login.php API response format:
        // Expected: {"status": "success", "data": {"user": {...}, "navigation": {...}}, "query_result": {...}}
        Map<String, dynamic> user;
        
        if (data['data'] != null && data['data']['user'] != null) {
          // Primary: Your retailer_login.php API format - data.user contains the processed user information
          user = Map<String, dynamic>.from(data['data']['user'] as Map<String, dynamic>);
          print('✅ AuthService: Using retailer API data.user format');
          print('📋 AuthService: User data: $user');
          
          // Ensure retailer-specific fields are properly handled
          if (user['id'] != null) {
            user['id'] = int.tryParse(user['id'].toString()) ?? user['id'];
          }
          if (user['location_id'] != null && user['location_id'].toString().isNotEmpty) {
            user['location_id'] = int.tryParse(user['location_id'].toString()) ?? user['location_id'];
          }
          
        } else if (data['query_result'] != null) {
          // Fallback: Use query_result as base user data (raw from database)
          user = Map<String, dynamic>.from(data['query_result'] as Map<String, dynamic>);
          
          // Transform query_result to match expected user format for retailer
          if (userType?.toLowerCase() == 'retailer') {
            user = {
              'id': int.tryParse(user['id']?.toString() ?? '0') ?? 0,
              'username': user['username'] ?? '',
              'first_name': user['first_name'] ?? '',
              'last_name': user['last_name'] ?? '',
              'name': user['name'] ?? user['first_name'] ?? user['username'],
              'email': user['email'] ?? '',
              'location_id': user['location_id'] != null ? int.tryParse(user['location_id'].toString()) : null,
              'store_name': user['store_name'] ?? '',
              'profile_pic': user['profile_pic'] ?? '',
              'role': 'retailer'
            };
          }
          
          // Ensure role is set correctly if missing
          if (user['role'] == null) {
            user['role'] = (userType?.toLowerCase() ?? 'user');
          }
          print('✅ AuthService: Using query_result as user data (transformed for retailer)');
          print('📋 AuthService: User data: $user');
        } else if (data['user'] != null) {
          // Fallback: Direct user object
          user = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
          print('✅ AuthService: Using direct user data format');
          print('📋 AuthService: User data: $user');
        } else if (data['username'] != null) {
          // Fallback: Build user object from direct response fields
          user = {
            'id': data['id'],
            'username': data['username'],
            'name': data['name'] ?? data['username'],
            'role': data['role'] ?? (userType?.toLowerCase() ?? 'user'),
            'admin_type': data['admin_type'],
            'admin_level': data['admin_level'],
            'permissions': data['permissions'],
          };
          print('✅ AuthService: Using direct response fields as user data');
          print('📋 AuthService: Built user data: $user');
        } else {
          print('❌ AuthService: Response missing user data in all expected formats');
          print('📋 AuthService: Available keys: ${data.keys.toList()}');
          print('📋 AuthService: Full response data: $data');
          return {
            'status': 'error',
            'message': 'Invalid API response. User data not found in expected format.',
            'code': 'MISSING_USER_DATA',
            'debug_data': data.keys.toList(),
            'full_response': data
          };
        }

        // Validate required user fields
        if (user['username'] == null || user['role'] == null) {
          print('❌ AuthService: User data missing required fields');
          return {
            'status': 'error',
            'message': 'Invalid user data. Missing required fields (username or role).',
            'code': 'INVALID_USER_DATA',
            'debug_user': user
          };
        }
        
        // Cache retailer id for future requests
        try {
          if (user['id'] != null) {
            _cachedRetailerId = user['id'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_retailer_id', _cachedRetailerId!);
            print('🗃️ AuthService: Cached retailer id: $_cachedRetailerId');
          }
        } catch (e) {
          print('⚠️ AuthService: Failed to cache retailer id: $e');
        }
        
        // Add role information for navigation
        final userRole = (user['role'] ?? (userType?.toLowerCase() ?? 'user')) as String;
        print('👤 AuthService: User role identified: $userRole');
        
        // Prefer server-provided navigation links when available
        final Map<String, dynamic>? navigationLinks =
            (data['data'] != null && data['data']['navigation'] is Map<String, dynamic>)
                ? (data['data']['navigation'] as Map<String, dynamic>)
                : null;
        
        return {
          'status': 'success',
          'message': data['message'] ?? 'Login successful',
          'code': data['code'] ?? 'LOGIN_SUCCESS',
          'user': user,
          'role': userRole,
          // App route to navigate within Flutter app
          'navigation': _getDashboardRoute(userRole),
          // Raw URLs provided by PHP API (dashboard/profile/settings), if present
          if (navigationLinks != null) 'navigation_links': navigationLinks,
          // Include additional retailer API response data
          if (data['count'] != null) 'count': data['count'],
          if (data['query_result'] != null) 'query_result': data['query_result'],
          'api_response_time': DateTime.now().millisecondsSinceEpoch,
          'http_status': 200
        };
      }

      // Step 7: Handle login failure
      print('❌ AuthService: Login failed - ${data['message']}');
      return {
        'status': 'error',
        'message': data['message'] ?? 'Login failed',
        'code': data['code'] ?? 'LOGIN_FAILED',
        'http_status': response.statusCode,
        'api_response': data
      };

    } catch (e) {
      print('💥 AuthService: Exception occurred: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e. Please check your internet connection and try again.',
        'code': 'CONNECTION_ERROR'
      };
    }
  }


  // ================= ROLE-BASED DASHBOARD ROUTING =================
  static String _getDashboardRoute(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '/admin_dashboard';
      case 'consumer':
        return '/consumer_dashboard';
      case 'retailer':
        return '/retailer_dashboard';
      default:
        return '/user-dashboard';
    }
  }

  // ================= GET DASHBOARD ROUTE FOR CURRENT USER =================
  static Future<String?> getDashboardRoute() async {
    final user = await getCurrentUser();
    if (user != null && user['role'] != null) {
      return _getDashboardRoute(user['role']);
    }
    return null;
  }

  // ================= CRUD OPERATIONS =================
  
  // CREATE - Register new user (POST)
  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String name,
    required String userType,
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📝 AuthService: Creating new user - $username ($userType)');
      
      // Use the appropriate register.php endpoint based on user type
      String endpoint;
      switch (userType.toLowerCase()) {
        case 'consumer':
          endpoint = 'register.php';
          break;
        case 'retailer':
          endpoint = 'register.php';
          break;
        default:
          endpoint = 'register.php'; // Default to consumer
          break;
      }
      final url = Uri.parse('$baseUrl/$endpoint');
      
      // Prepare request body based on user type
      Map<String, dynamic> requestBody = {
        'username': username.trim(),
        'password': password,
        'user_type': userType.toLowerCase(),
      };

      // Add fields based on user type
      if (userType.toLowerCase() == 'consumer') {
        // Consumer requires additional fields
        requestBody.addAll({
          'confirm_password': password, // Use same password for confirmation
          'email': email?.trim() ?? '',
          'first_name': name.split(' ').first,
          'last_name': name.split(' ').length > 1 ? name.split(' ').last : '',
          'middle_name': name.split(' ').length > 2 ? name.split(' ').sublist(1, name.split(' ').length - 1).join(' ') : '',
          'gender': 'other', // Default gender
          'birthdate': '1990-01-01', // Default birthdate
          'age': '25', // Default age
          'location_id': '1', // Default location
        });
        
        // Add additional data if provided
        if (additionalData != null) {
          requestBody.addAll(additionalData);
        }
      } else if (userType.toLowerCase() == 'retailer') {
        // Retailer requires registration code
        requestBody.addAll({
          'confirm_password': password,
          'registration_code': additionalData?['registration_code'] ?? '000000', // Default code
        });
      } else {
        // Admin or other types - use basic fields
        requestBody.addAll({
          'email': email?.trim() ?? '',
          'first_name': name.split(' ').first,
          'last_name': name.split(' ').length > 1 ? name.split(' ').last : '',
        });
        
        if (additionalData != null) {
          requestBody.addAll(additionalData);
        }
      }

      print('📤 AuthService: POST request to: $url');
      print('📤 AuthService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: CREATE Response Status: ${response.statusCode}');
      print('📊 AuthService: CREATE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          return {
            'status': 'success',
            'message': data['message'] ?? 'User created successfully',
            'user': data['data']?['user'],
            'data': data['data'],
            'code': data['code'] ?? 'USER_CREATED'
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to create user',
            'code': data['code'] ?? 'CREATE_FAILED'
          };
        }
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Failed to create user',
          'code': data['code'] ?? 'CREATE_FAILED',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Error creating user: $e');
      return {
        'status': 'error',
        'message': 'Failed to create user: $e',
        'code': 'CREATE_ERROR'
      };
    }
  }

  // READ - Get user data (GET)
  static Future<Map<String, dynamic>> getUser({
    required String userId,
    String? userType,
  }) async {
    try {
      print('🔍 AuthService: Getting user data - ID: $userId');
      
      String endpoint;
      switch (userType?.toLowerCase()) {
        case 'admin':
          // Admin can access both consumers and retailers
          endpoint = 'admin/admin_users.php'; // Default to consumers, can be changed based on context
          break;
        case 'consumer':
          endpoint = 'consumer/consumer_users.php';
          break;
        case 'retailer':
          endpoint = 'retailer/retailer_users.php';
          break;
        default:
          endpoint = 'users.php';
          break;
      }

      final url = Uri.parse('$baseUrl/$endpoint?id=$userId');

      print('📤 AuthService: GET request to: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'login_app/1.0',
      };
      
      // Add session cookie if available
      final sessionCookie = getSessionCookie();
      if (sessionCookie != null) {
        headers['Cookie'] = sessionCookie;
      }
      
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));

      print('📊 AuthService: READ Response Status: ${response.statusCode}');
      print('📊 AuthService: READ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'User data retrieved successfully',
          'user': data['user'],
          'code': 'USER_FOUND'
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'User not found',
          'code': 'USER_NOT_FOUND',
          'http_status': 404
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Failed to get user data',
          'code': 'READ_FAILED',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Error getting user: $e');
      return {
        'status': 'error',
        'message': 'Failed to get user data: $e',
        'code': 'READ_ERROR'
      };
    }
  }

  // READ - Get all users (GET with pagination)
  static Future<Map<String, dynamic>> getAllUsers({
    String? userType,
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      print('🔍 AuthService: Getting all users - Type: $userType, Page: $page');
      
      String endpoint;
      switch (userType?.toLowerCase()) {
        case 'admin':
          endpoint = 'admin_users.php';
          break;
        case 'consumer':
          endpoint = 'consumer_users.php';
          break;
        case 'retailer':
          endpoint = 'retailer_users.php';
          break;
        default:
          endpoint = 'users.php';
          break;
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);

      print('📤 AuthService: GET request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: READ ALL Response Status: ${response.statusCode}');
      print('📊 AuthService: READ ALL Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Users retrieved successfully',
          'users': data['users'],
          'pagination': data['pagination'],
          'code': 'USERS_FOUND'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Failed to get users',
          'code': 'READ_ALL_FAILED',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Error getting all users: $e');
      return {
        'status': 'error',
        'message': 'Failed to get users: $e',
        'code': 'READ_ALL_ERROR'
      };
    }
  }

  // UPDATE - Update user data (PUT)
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? username,
    String? name,
    String? email,
    String? password,
    String? userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('✏️ AuthService: Updating user - ID: $userId');
      
      String endpoint;
      switch (userType?.toLowerCase()) {
        case 'admin':
          endpoint = 'admin_users.php';
          break;
        case 'consumer':
          endpoint = 'consumer_users.php';
          break;
        case 'retailer':
          endpoint = 'retailer_users.php';
          break;
        default:
          endpoint = 'users.php';
          break;
      }

      final url = Uri.parse('$baseUrl/$endpoint?id=$userId');
      
      final requestBody = <String, dynamic>{
        'id': userId,
        if (username != null && username.isNotEmpty) 'username': username.trim(),
        if (name != null && name.isNotEmpty) 'name': name.trim(),
        if (email != null && email.isNotEmpty) 'email': email.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
        if (userType != null && userType.isNotEmpty) 'user_type': userType.toLowerCase(),
        if (additionalData != null) ...additionalData,
      };

      print('📤 AuthService: PUT request to: $url');
      print('📤 AuthService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: UPDATE Response Status: ${response.statusCode}');
      print('📊 AuthService: UPDATE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'User updated successfully',
          'user': data['user'],
          'code': 'USER_UPDATED'
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'User not found',
          'code': 'USER_NOT_FOUND',
          'http_status': 404
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Failed to update user',
          'code': 'UPDATE_FAILED',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Error updating user: $e');
      return {
        'status': 'error',
        'message': 'Failed to update user: $e',
        'code': 'UPDATE_ERROR'
      };
    }
  }

  // DELETE - Delete user (DELETE)
  static Future<Map<String, dynamic>> deleteUser({
    required String userId,
    String? userType,
    bool softDelete = true,
  }) async {
    try {
      print('🗑️ AuthService: Deleting user - ID: $userId (Soft: $softDelete)');
      
      String endpoint;
      switch (userType?.toLowerCase()) {
        case 'admin':
          endpoint = 'admin_users.php';
          break;
        case 'consumer':
          endpoint = 'consumer_users.php';
          break;
        case 'retailer':
          endpoint = 'retailer_users.php';
          break;
        default:
          endpoint = 'users.php';
          break;
      }

      final url = Uri.parse('$baseUrl/$endpoint?id=$userId&soft_delete=$softDelete');

      print('📤 AuthService: DELETE request to: $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: DELETE Response Status: ${response.statusCode}');
      print('📊 AuthService: DELETE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? (softDelete ? 'User deactivated successfully' : 'User deleted successfully'),
          'code': softDelete ? 'USER_DEACTIVATED' : 'USER_DELETED'
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'User not found',
          'code': 'USER_NOT_FOUND',
          'http_status': 404
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': data['message'] ?? 'Failed to delete user',
          'code': 'DELETE_FAILED',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Error deleting user: $e');
      return {
        'status': 'error',
        'message': 'Failed to delete user: $e',
        'code': 'DELETE_ERROR'
      };
    }
  }

  // Legacy register method (for backward compatibility)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String name,
    String userType = 'user',
  }) async {
    return await createUser(
      username: username,
      password: password,
      name: name,
      userType: userType,
    );
  }

  // ================= ENHANCED REGISTRATION METHODS =================
  
  /// Register a consumer user
  /// 
  /// Required fields for consumer:
  /// - username, password, confirmPassword, email, firstName, lastName, gender, birthdate, age, locationId
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - data: User data and profile info (if successful)
  /// - code: API response code
  static Future<Map<String, dynamic>> registerConsumer({
    required String username,
    required String password,
    required String confirmPassword,
    required String email,
    required String firstName,
    required String lastName,
    required String middleName,
    required String gender,
    required String birthdate,
    required int age,
    required int locationId,
    String? phone,
    String? bio,
    String? profilePicture,
  }) async {
    try {
      print('📝 AuthService: Registering consumer - $username');
      
      // Validate input data
      final validation = _validateConsumerData(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      email: email,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      birthdate: birthdate,
      age: age,
      locationId: locationId,
      );
      
      if (!validation['valid']) {
        return {
          'status': 'error',
          'message': validation['message'],
          'code': validation['code'] ?? 'VALIDATION_ERROR'
        };
      }
      
      final url = Uri.parse('$baseUrl/register.php');
      
      final requestBody = {
        'user_type': 'consumer',
        'username': username.trim(),
        'password': password,
        'confirm_password': confirmPassword,
        'email': email.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'middle_name': middleName.trim(),
        'gender': gender.toLowerCase(),
        'birthdate': birthdate,
        'age': age.toString(),
        'location_id': locationId.toString(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (bio != null && bio.isNotEmpty) 'bio': bio.trim(),
        if (profilePicture != null && profilePicture.isNotEmpty) 'profile_picture': profilePicture.trim(),
      };

      print('📤 AuthService: Request body: ${jsonEncode(requestBody)}');
      print('📤 AuthService: Request URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: CONSUMER Response Status: ${response.statusCode}');
      print('📊 AuthService: CONSUMER Response Body: ${response.body}');
      print('📊 AuthService: CONSUMER Response Headers: ${response.headers}');

      return _handleRegistrationResponse(response, 'consumer');
    } catch (e) {
      print('❌ AuthService: Error registering consumer: $e');
      return {
        'status': 'error',
        'message': 'Failed to register consumer: $e',
        'code': 'CONSUMER_REGISTRATION_ERROR'
      };
    }
  }

  /// Register a retailer user
  /// 
  /// Required fields for retailer:
  /// - username, password, confirmPassword, registrationCode
  /// 
  /// Note: Retailer data (name, email, store, location) comes from the registration code
  /// 
  /// Returns a map with:
  /// - status: 'success' or 'error'
  /// - message: Response message
  /// - data: User data and profile info (if successful)
  /// - code: API response code
  static Future<Map<String, dynamic>> registerRetailer({
    required String username,
    required String password,
    required String confirmPassword,
    required String registrationCode,
  }) async {
    try {
      print('📝 AuthService: Registering retailer - $username');
      
      // Validate input data
      final validation = _validateRetailerData(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      registrationCode: registrationCode,
    );
      
      if (!validation['valid']) {
        return {
          'status': 'error',
          'message': validation['message'],
          'code': validation['code'] ?? 'VALIDATION_ERROR'
        };
      }
      
      final url = Uri.parse('$baseUrl/register.php');
      
      final requestBody = {
        'user_type': 'retailer',
        'username': username.trim(),
        'password': password,
        'confirm_password': confirmPassword,
        'registration_code': registrationCode.trim(),
      };

      print('📤 AuthService: Request body: ${jsonEncode(requestBody)}');
      print('📤 AuthService: Request URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: RETAILER Response Status: ${response.statusCode}');
      print('📊 AuthService: RETAILER Response Body: ${response.body}');
      print('📊 AuthService: RETAILER Response Headers: ${response.headers}');

      return _handleRegistrationResponse(response, 'retailer');
    } catch (e) {
      print('❌ AuthService: Error registering retailer: $e');
      return {
        'status': 'error',
        'message': 'Failed to register retailer: $e',
        'code': 'RETAILER_REGISTRATION_ERROR'
      };
    }
  }

  /// Unified registration method that handles both consumer and retailer
  /// 
  /// [userType] - 'consumer' or 'retailer'
  /// [registrationData] - Map containing all registration data
  /// 
  /// Returns a map with registration result
  static Future<Map<String, dynamic>> registerUser({
    required String userType,
    required Map<String, dynamic> registrationData,
  }) async {
    try {
      print('📝 AuthService: Registering $userType user');
      
      if (userType.toLowerCase() == 'consumer') {
        return await registerConsumer(
          username: registrationData['username'] ?? '',
          password: registrationData['password'] ?? '',
          confirmPassword: registrationData['confirm_password'] ?? '',
          email: registrationData['email'] ?? '',
          firstName: registrationData['first_name'] ?? '',
          lastName: registrationData['last_name'] ?? '',
          middleName: registrationData['middle_name'] ?? '',
          gender: registrationData['gender'] ?? '',
          birthdate: registrationData['birthdate'] ?? '',
          age: int.tryParse(registrationData['age']?.toString() ?? '0') ?? 0,
          locationId: int.tryParse(registrationData['location_id']?.toString() ?? '0') ?? 0,
          phone: registrationData['phone'],
          bio: registrationData['bio'],
          profilePicture: registrationData['profile_picture'],
        );
      } else if (userType.toLowerCase() == 'retailer') {
        return await registerRetailer(
          username: registrationData['username'] ?? '',
          password: registrationData['password'] ?? '',
          confirmPassword: registrationData['confirm_password'] ?? '',
          registrationCode: registrationData['registration_code'] ?? '',
        );
      } else {
        return {
          'status': 'error',
          'message': 'Invalid user type. Must be consumer or retailer',
          'code': 'INVALID_USER_TYPE'
        };
      }
    } catch (e) {
      print('❌ AuthService: Error in unified registration: $e');
      return {
        'status': 'error',
        'message': 'Registration failed: $e',
        'code': 'REGISTRATION_ERROR'
      };
    }
  }

  // ================= DEBUG AND TESTING =================
  
  /// Test registration with detailed logging
  static Future<Map<String, dynamic>> testRegistration({
    required String userType,
    required Map<String, dynamic> testData,
  }) async {
    try {
      print('🧪 AuthService: Testing registration for $userType');
      print('🧪 AuthService: Test data: ${jsonEncode(testData)}');
      
      final url = Uri.parse('$baseUrl/consumer/register.php');
      print('🧪 AuthService: Test URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 30));
      
      print('🧪 AuthService: Test Response Status: ${response.statusCode}');
      print('🧪 AuthService: Test Response Body: ${response.body}');
      print('🧪 AuthService: Test Response Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Test completed successfully',
          'response_data': data,
          'debug_info': {
            'url': url.toString(),
            'request_data': testData,
            'response_status': response.statusCode,
            'response_body': response.body,
            'response_headers': response.headers,
          }
        };
      } else {
        return {
          'status': 'error',
          'message': 'Test failed with status ${response.statusCode}',
          'response_data': response.body,
          'debug_info': {
            'url': url.toString(),
            'request_data': testData,
            'response_status': response.statusCode,
            'response_body': response.body,
          }
        };
      }
    } catch (e) {
      print('❌ AuthService: Test error: $e');
      return {
        'status': 'error',
        'message': 'Test failed with exception: $e',
        'debug_info': {
          'error': e.toString(),
          'test_data': testData,
        }
      };
    }
  }

  // ================= LOGOUT =================
  static Future<Map<String, dynamic>> logout() async {
    try {
      final url = Uri.parse('$baseUrl/logout.php');

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'});

      await _clearUserData();
      await _clearSessionCookie(); // Clear session cookie on logout

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Logout failed'};
      }
    } catch (e) {
      await _clearUserData();
      return {
        'status': 'error',
        'message': 'Failed to connect to server: $e',
      };
    }
  }

  // ================= SESSION HANDLING =================
  
  // Check if user is logged in by calling API
  static Future<bool> isLoggedIn() async {
    try {
      // Call your API to check session status
      final url = Uri.parse('$baseUrl/check-session.php');
      
      // Prepare headers
      final headers = {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
      };
      
      // Add session cookie if available
      final sessionCookie = getSessionCookie();
      if (sessionCookie != null) {
        headers['Cookie'] = sessionCookie;
      }
      
      final response = await http.get(url, headers: headers);
      
      print('🔍 AuthService: Session check response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success' && data['logged_in'] == true;
      }
      return false;
    } catch (e) {
      print('❌ AuthService: Error checking login status: $e');
      return false;
    }
  }

  // Check if consumer is logged in and has valid session
  static Future<bool> isConsumerLoggedIn() async {
    try {
      final isLoggedInStatus = await isLoggedIn();
      if (!isLoggedInStatus) return false;
      
      final currentUser = await getCurrentUser();
      return currentUser != null && currentUser['role'] == 'consumer';
    } catch (e) {
      print('❌ AuthService: Error checking consumer login status: $e');
      return false;
    }
  }

  // Get current user data from API
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // Call your API to get current user data
      final url = Uri.parse('$baseUrl/get-current-user.php');
      
      // Prepare headers
      final headers = {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
      };
      
      // Add session cookie if available
      final sessionCookie = getSessionCookie();
      if (sessionCookie != null) {
        headers['Cookie'] = sessionCookie;
      }
      
      final response = await http.get(url, headers: headers);
      
      print('🔍 AuthService: Get current user response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('❌ AuthService: Error getting current user: $e');
      return null;
    }
  }

  // Get user role from API
  static Future<String?> getUserRole() async {
    try {
      final user = await getCurrentUser();
      return user?['role'];
    } catch (e) {
      print('❌ AuthService: Error getting user role: $e');
      return null;
    }
  }

  // Validate retailer session and get retailer ID
  static Future<Map<String, dynamic>> validateRetailerSession() async {
    try {
      print('🔍 AuthService: Validating retailer session...');
      print('🔍 AuthService: Current session cookie: ${getSessionCookie()}');
      
      final isLoggedInStatus = await isLoggedIn();
      print('🔍 AuthService: isLoggedIn result: $isLoggedInStatus');
      
      if (!isLoggedInStatus) {
        print('❌ AuthService: User is not logged in according to isLoggedIn()');
        return {
          'status': 'error',
          'message': 'User is not logged in',
          'code': 'NOT_LOGGED_IN'
        };
      }

      final currentUser = await getCurrentUser();
      print('🔍 AuthService: getCurrentUser result: $currentUser');
      
      if (currentUser == null) {
        print('❌ AuthService: getCurrentUser returned null');
        return {
          'status': 'error',
          'message': 'Unable to get current user data',
          'code': 'USER_DATA_ERROR'
        };
      }

      if (currentUser['role'] != 'retailer') {
        return {
          'status': 'error',
          'message': 'User is not a retailer',
          'code': 'INVALID_USER_ROLE'
        };
      }

      final retailerId = currentUser['id']?.toString();
      if (retailerId == null) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found',
          'code': 'MISSING_RETAILER_ID'
        };
      }

      return {
        'status': 'success',
        'message': 'Retailer session is valid',
        'retailer_id': retailerId,
        'user': currentUser
      };
    } catch (e) {
      print('❌ AuthService: Error validating retailer session: $e');
      return {
        'status': 'error',
        'message': 'Session validation failed: $e',
        'code': 'SESSION_VALIDATION_ERROR'
      };
    }
  }

  // Validate consumer session and get consumer ID
  static Future<Map<String, dynamic>> validateConsumerSession() async {
    try {
      print('🔍 AuthService: Validating consumer session...');
      
      // Check if user is logged in
      final isLoggedInStatus = await isLoggedIn();
      if (!isLoggedInStatus) {
        return {
          'status': 'error',
          'message': 'User is not logged in',
          'code': 'NOT_LOGGED_IN'
        };
      }
      
      // Get current user data
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {
          'status': 'error',
          'message': 'Unable to get current user data',
          'code': 'USER_DATA_ERROR'
        };
      }
      
      // Check if user is a consumer
      if (currentUser['role'] != 'consumer') {
        return {
          'status': 'error',
          'message': 'User is not a consumer',
          'code': 'INVALID_USER_ROLE'
        };
      }
      
      // Get consumer ID
      final consumerId = currentUser['id']?.toString();
      if (consumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID not found',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      return {
        'status': 'success',
        'message': 'Consumer session is valid',
        'consumer_id': consumerId,
        'user': currentUser
      };
    } catch (e) {
      print('❌ AuthService: Error validating consumer session: $e');
      return {
        'status': 'error',
        'message': 'Session validation failed: $e',
        'code': 'SESSION_VALIDATION_ERROR'
      };
    }
  }

  // Clear session on server (no local data to clear)
  static Future<void> _clearUserData() async {
    try {
      // Call your API to clear server-side session
      final url = Uri.parse('$baseUrl/clear-session.php');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      );
      print('✅ AuthService: Server session cleared');
    } catch (e) {
      print('❌ AuthService: Error clearing server session: $e');
    }
  }

  // ================= DASHBOARD API INTEGRATION =================

  // Load admin dashboard data

  // Load consumer dashboard data
  static Future<Map<String, dynamic>> loadConsumerDashboard({String? consumerId}) async {
    try {
      print('🔄 AuthService: Loading consumer dashboard data...');
      
      // Validate consumer session first
      final sessionValidation = await validateConsumerSession();
      if (sessionValidation['status'] != 'success') {
        return sessionValidation;
      }
      
      // Get consumer ID from parameter or validated session
      String? finalConsumerId = consumerId ?? sessionValidation['consumer_id'];
      
      if (finalConsumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID is required. Please login first.',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      print('📋 AuthService: Using consumer ID: $finalConsumerId');
      
      // Use POST method with consumer_id in JSON body as per PHP API
      final url = Uri.parse('$baseUrl/consumer/consumer_dashboard.php');
      final requestBody = {
        'consumer_id': finalConsumerId,
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 AuthService: Consumer API Response Status: ${response.statusCode}');
      print('📊 AuthService: Consumer API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ AuthService: Consumer dashboard data loaded successfully');
          
          // Handle API response structure
          if (data['status'] == 'success') {
            return {
              'status': 'success',
              'message': data['message'] ?? 'Consumer dashboard data loaded successfully',
              'data': data['data'],
              'code': data['code'] ?? 'CONSUMER_DASHBOARD_SUCCESS'
            };
          } else {
            return {
              'status': 'error',
              'message': data['message'] ?? 'Failed to load consumer dashboard',
              'code': data['code'] ?? 'CONSUMER_DASHBOARD_ERROR'
            };
          }
        } catch (e) {
          print('❌ AuthService: Failed to parse consumer dashboard JSON: $e');
          return {
            'status': 'error',
            'message': 'Invalid JSON response from consumer dashboard API',
            'code': 'INVALID_JSON_RESPONSE'
          };
        }
      } else {
        print('❌ AuthService: Consumer dashboard API returned status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'Consumer dashboard API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('💥 AuthService: Error loading consumer dashboard: $e');
      return {
        'status': 'error',
        'message': 'Failed to load consumer dashboard: $e',
        'code': 'CONNECTION_ERROR'
      };
    }
  }

  // Load retailer dashboard data
  static Future<Map<String, dynamic>> loadRetailerDashboard({String? retailerId}) async {
    try {
      print('🔄 AuthService: Loading retailer dashboard data...');

      // Prefer provided retailerId; otherwise, use current user or cached id
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }

      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
          'http_status': 400,
        };
      }

      // Build URL with retailer_id parameter as expected by the cloud API
      final url = Uri.parse('$baseUrl/retailer/retailer_dashboard.php?retailer_id=$finalRetailerId');
      final sessionCookie = getSessionCookie();

      print('🔗 AuthService: Dashboard URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      print('🍪 AuthService: Session cookie: $sessionCookie');

      final headers = <String, String>{
        'Accept': 'application/json',
        'User-Agent': 'login_app/1.0',
      };
      if (sessionCookie != null) headers['Cookie'] = sessionCookie;

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📊 AuthService: Retailer API Response Status: ${response.statusCode}');
      print('📊 AuthService: Retailer API Response Body: ${response.body}');
      print('📊 AuthService: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ AuthService: Retailer dashboard data loaded successfully');
          final bool ok = (data['success'] == true) || (data['status'] == 'success');
          if (ok) {
            return {
              'status': 'success',
              'message': data['message'] ?? 'Retailer dashboard data loaded successfully',
              'data': data['data'],
              'code': 'HTTP_200',
              'http_status': 200,
            };
          } else {
            final String msg = (data['message'] ?? '').toString().toLowerCase();
            final bool unauthorized = msg.contains('unauthorized') || msg.contains('not logged in');
            final bool forbidden = msg.contains('deactivated') || msg.contains('forbidden');
            final int mapped = unauthorized ? 401 : (forbidden ? 403 : 200);
            final String code = unauthorized ? 'UNAUTHORIZED' : (forbidden ? 'FORBIDDEN' : 'HTTP_200_PAYLOAD_ERROR');
            return {
              'status': 'error',
              'message': data['message'] ?? 'Failed to load retailer dashboard',
              'code': code,
              'http_status': mapped,
            };
          }
        } catch (e) {
          print('❌ AuthService: Failed to parse retailer dashboard JSON: $e');
          return {
            'status': 'error',
            'message': 'Invalid JSON from retailer dashboard',
            'code': 'JSON_PARSE_ERROR',
            'http_status': 200,
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Retailer dashboard API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Exception while loading retailer dashboard: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_ERROR'
      };
    }
  }

  // ================= RETAILER COMPLAINTS API =================
  static Future<Map<String, dynamic>> loadRetailerComplaints({String? retailerId, int page = 1, int limit = 10}) async {
    try {
      print('🔄 AuthService: Loading retailer complaints...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      final url = Uri.parse('$baseUrl/retailer/complaints.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'retailer_id': finalRetailerId, 'action': 'list', 'page': page, 'limit': limit}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to load retailer complaints: $e');
      return {'status': 'error', 'message': 'Failed to load complaints: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerComplaint({String? retailerId, required int complaintId}) async {
    try {
      print('🔄 AuthService: Getting retailer complaint...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      final url = Uri.parse('$baseUrl/retailer/complaints.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'retailer_id': finalRetailerId, 'action': 'get', 'complaint_id': complaintId}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer complaint: $e');
      return {'status': 'error', 'message': 'Failed to get complaint: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerComplaintStatus({
    String? retailerId,
    required int complaintId,
    required String status,
    String? resolutionNotes,
  }) async {
    try {
      print('🔄 AuthService: Updating complaint status...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      final url = Uri.parse('$baseUrl/retailer/complaints.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({
          'retailer_id': finalRetailerId,
          'action': 'update_status',
          'complaint_id': complaintId,
          'status': status,
          'resolution_notes': resolutionNotes,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to update complaint status: $e');
      return {'status': 'error', 'message': 'Failed to update status: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= RETAILER NOTIFICATIONS API =================
  static Future<Map<String, dynamic>> loadRetailerNotifications({String? retailerId}) async {
    try {
      print('🔄 AuthService: Loading retailer notifications...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      // notifications.php uses GET to list
      final url = Uri.parse('$baseUrl/retailer/notifications.php?retailer_id=$finalRetailerId');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Notifications URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      final response = await http
          .get(
            url, 
            headers: {
              'Accept': 'application/json', 
              'User-Agent': 'login_app/1.0',
              if (sessionCookie != null) 'Cookie': sessionCookie,
            }
          )
          .timeout(const Duration(seconds: 15));

      print('📊 AuthService: Notifications API Response Status: ${response.statusCode}');
      print('📊 AuthService: Notifications API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Notifications loaded successfully',
          'data': data,
          'code': 'HTTP_200',
          'http_status': 200,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Notifications API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to load retailer notifications: $e');
      return {'status': 'error', 'message': 'Failed to load notifications: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> markRetailerNotificationRead({String? retailerId, required int notificationId}) async {
    try {
      print('🔄 AuthService: Marking notification as read...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      final url = Uri.parse('$baseUrl/retailer/notifications.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'retailer_id': finalRetailerId, 'action': 'mark_read', 'notification_id': notificationId}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to mark notification as read: $e');
      return {'status': 'error', 'message': 'Failed to mark as read: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> markAllRetailerNotificationsRead({String? retailerId}) async {
    try {
      print('🔄 AuthService: Marking all notifications as read...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      final url = Uri.parse('$baseUrl/retailer/notifications.php');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Mark All Notifications Read URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      // notifications.php uses PATCH for mark_all_read
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (sessionCookie != null) 'Cookie': sessionCookie,
        },
        body: jsonEncode({
          'action': 'mark_all_read',
        }),
      ).timeout(const Duration(seconds: 15));

      print('📊 AuthService: Mark All Notifications Read Response Status: ${response.statusCode}');
      print('📊 AuthService: Mark All Notifications Read Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'status': 'success',
            'message': 'All notifications marked as read',
            'data': data,
            'code': 'HTTP_200',
            'http_status': 200,
          };
      } else {
          return {
            'status': 'error',
            'message': data['error'] ?? 'Failed to mark all notifications as read',
            'code': 'API_ERROR',
            'http_status': 200,
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Mark All Notifications API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to mark all notifications as read: $e');
      return {'status': 'error', 'message': 'Failed to mark all as read: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= RETAILER PRODUCTS API =================
  static Future<Map<String, dynamic>> loadRetailerProducts({
    String? retailerId,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      print('🔄 AuthService: Loading retailer products...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      // store_products.php uses GET for listing
      final qp = <String, String>{
        'retailer_id': finalRetailerId.toString(),
          if (search != null && search.isNotEmpty) 'search': search,
      };  
      final url = Uri.parse('$baseUrl/retailer/store_products.php').replace(queryParameters: qp);
      final response = await http
          .get(url, headers: {'Accept': 'application/json', 'User-Agent': 'login_app/1.0'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to load retailer products: $e');
      return {'status': 'error', 'message': 'Failed to load products: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerProduct({String? retailerId, required int productId}) async {
    try {
      print('🔄 AuthService: Getting retailer product...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      // Product details come from product_catalog.php (POST action=get)
      final url = Uri.parse('$baseUrl/retailer/product_catalog.php');
      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
            body: jsonEncode({'action': 'get', 'product_id': productId}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer product: $e');
      return {'status': 'error', 'message': 'Failed to get product: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerProductPrice({
    String? retailerId,
    required int productId,
    required double price,
    String? notes,
  }) async {
    try {
      print('🔄 AuthService: Updating product price...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      // store_products.php expects PATCH with retail_price_id and new_price
      final url = Uri.parse('$baseUrl/retailer/store_products.php');
      final request = http.Request('PATCH', url);
      request.headers.addAll({'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'});
      // Note: productId here should be the retail_price_id from your list
      request.body = jsonEncode({
        'retail_price_id': productId,
        'new_price': price,
      });
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to update product price: $e');
      return {'status': 'error', 'message': 'Failed to update price: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= RETAILER STORE API =================
  static Future<Map<String, dynamic>> getRetailerStore({String? retailerId}) async {
    try {
      print('🔄 AuthService: Getting retailer store...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      // profile.php GET returns profile and monitoring_form
      final url = Uri.parse('$baseUrl/retailer/profile.php?retailer_id=$finalRetailerId');
      final response = await http
          .get(url, headers: {'Accept': 'application/json', 'User-Agent': 'login_app/1.0'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer store: $e');
      return {'status': 'error', 'message': 'Failed to get store: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerStore({
    String? retailerId,
    String? firstName,
    String? lastName,
    String? middleName,
    String? email,
    String? storeName,
  }) async {
    try {
      print('🔄 AuthService: Updating retailer store...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      // profile.php PATCH updates profile fields
      final url = Uri.parse('$baseUrl/retailer/profile.php');
      final request = http.Request('PATCH', url);
      request.headers.addAll({'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'});
      request.body = jsonEncode({
          'retailer_id': finalRetailerId,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (middleName != null) 'middle_name': middleName,
          if (email != null) 'email': email,
          if (storeName != null) 'store_name': storeName,
      });
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to update retailer store: $e');
      return {'status': 'error', 'message': 'Failed to update store: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerMonitoringHistory({
    String? retailerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🔄 AuthService: Getting monitoring history...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      // profile.php GET returns latest monitoring_form; no paging server-side
      final url = Uri.parse('$baseUrl/retailer/profile.php?retailer_id=$finalRetailerId');
      final response = await http
          .get(url, headers: {'Accept': 'application/json', 'User-Agent': 'login_app/1.0'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to get monitoring history: $e');
      return {'status': 'error', 'message': 'Failed to get history: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= RETAILER AGREEMENTS API =================
  static Future<Map<String, dynamic>> loadRetailerAgreements({String? retailerId}) async {
    try {
      print('🔄 AuthService: Loading retailer agreements...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      // agreements.php uses GET to list
      final url = Uri.parse('$baseUrl/retailer/agreements.php?retailer_id=$finalRetailerId');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Agreements URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      final response = await http
          .get(
        url,
        headers: {
              'Accept': 'application/json', 
          'User-Agent': 'login_app/1.0',
              if (sessionCookie != null) 'Cookie': sessionCookie,
            }
          )
          .timeout(const Duration(seconds: 15));

      print('📊 AuthService: Agreements API Response Status: ${response.statusCode}');
      print('📊 AuthService: Agreements API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['success'] == true;
        return ok
            ? {
                'status': 'success',
                'message': data['message'] ?? 'Agreements retrieved successfully',
                'data': data['data'] ?? {},
                'code': 'HTTP_200',
                'http_status': 200,
              }
            : {
                'status': 'error',
                'message': data['message'] ?? 'Failed to load agreements',
                'code': 'HTTP_200_PAYLOAD_ERROR',
                'http_status': 200,
              };
      } else {
        return {
          'status': 'error',
          'message': 'Agreements API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to load retailer agreements: $e');
      return {'status': 'error', 'message': 'Failed to load agreements: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerAgreement({String? retailerId, required int agreementId}) async {
    try {
      print('🔄 AuthService: Getting retailer agreement...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      final url = Uri.parse('$baseUrl/retailer/agreements.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode({
          'retailer_id': finalRetailerId,
          'action': 'get',
          'agreement_id': agreementId
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'status': 'error',
          'message': 'Agreement API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer agreement: $e');
      return {'status': 'error', 'message': 'Failed to get agreement: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerAgreementStatus({
    String? retailerId,
    required int agreementId,
    required String acceptanceStatus,
  }) async {
    try {
      print('🔄 AuthService: Updating retailer agreement status...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      final url = Uri.parse('$baseUrl/retailer/agreements.php');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Update Agreement Status URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      print('📝 AuthService: Agreement ID: $agreementId');
      print('📝 AuthService: Acceptance Status: $acceptanceStatus');
      
      // Use PATCH method as per agreements.php
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (sessionCookie != null) 'Cookie': sessionCookie,
        },
        body: jsonEncode({
          'agreement_id': agreementId,
          'acceptance_status': acceptanceStatus,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📊 AuthService: Agreement Status Update Response Status: ${response.statusCode}');
      print('📊 AuthService: Agreement Status Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['success'] == true;
        return ok
            ? {
                'status': 'success',
                'message': data['message'] ?? 'Agreement status updated successfully',
                'data': data['data'] ?? {},
                'code': 'HTTP_200',
                'http_status': 200,
              }
            : {
                'status': 'error',
                'message': data['message'] ?? 'Failed to update agreement status',
                'code': 'HTTP_200_PAYLOAD_ERROR',
                'http_status': 200,
              };
      } else {
        return {
          'status': 'error',
          'message': 'Agreement status update API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update retailer agreement status: $e');
      return {'status': 'error', 'message': 'Failed to update agreement status: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= RETAILER PROFILE API =================
  static Future<Map<String, dynamic>> getRetailerProfile({String? retailerId}) async {
    try {
      print('🔄 AuthService: Getting retailer profile...');
      
      // Prefer provided retailerId; otherwise, use current user or cached id
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
          'http_status': 400,
        };
      }

      final url = Uri.parse('$baseUrl/retailer/profile.php?retailer_id=$finalRetailerId');
      final sessionCookie = getSessionCookie();
      print('🔗 AuthService: Profile URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      print('🍪 AuthService: Session cookie: $sessionCookie');
      
      final headers = <String, String>{
        'Accept': 'application/json',
        'User-Agent': 'login_app/1.0',
      };
      if (sessionCookie != null) headers['Cookie'] = sessionCookie;

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('📊 AuthService: Profile API Response Status: ${response.statusCode}');
      print('📊 AuthService: Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['status'] == 'success' || data['success'] == true;
        if (ok) {
          return {
            'status': 'success',
            'message': data['message'] ?? 'Profile loaded',
            'data': data['data'] ?? {},
            'code': 'HTTP_200',
            'http_status': 200
          };
        } else {
          final String msg = (data['message'] ?? '').toString().toLowerCase();
          final bool unauthorized = msg.contains('unauthorized') || msg.contains('not logged in');
          final bool forbidden = msg.contains('deactivated') || msg.contains('forbidden');
          final int mapped = unauthorized ? 401 : (forbidden ? 403 : 200);
          final String code = unauthorized ? 'UNAUTHORIZED' : (forbidden ? 'FORBIDDEN' : 'HTTP_200_PAYLOAD_ERROR');
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to load profile',
            'code': code,
            'http_status': mapped
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Profile API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer profile: $e');
      return {'status': 'error', 'message': 'Failed to get profile: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerProfile({
    String? retailerId,
    String? firstName,
    String? lastName,
    String? middleName,
    String? email,
    String? phone,
    String? address,
    String? username,
    String? currentPassword,
    String? newPassword,
    File? profileImage,
  }) async {
    try {
      print('🔄 AuthService: Updating retailer profile...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      
      // Handle profile image upload separately
      if (profileImage != null) {
        return await _uploadProfileImage(profileImage, finalRetailerId);
      }
      
      // Handle username update
      if (username != null && currentPassword != null) {
        final url = Uri.parse('$baseUrl/retailer/profile.php');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'login_app/1.0',
          },
          body: jsonEncode({
            'retailer_id': finalRetailerId,
            'action': 'update_username',
            'username': username,
            'current_password': currentPassword,
          }),
        ).timeout(const Duration(seconds: 15));

        print('📊 AuthService: Username Update Response Status: ${response.statusCode}');
        print('📊 AuthService: Username Update Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data;
        } else {
          return {
            'status': 'error',
            'message': 'Username update API returned status: ${response.statusCode}',
            'code': 'HTTP_ERROR'
          };
        }
      }
      
      // Handle password update
      if (newPassword != null && currentPassword != null) {
        final url = Uri.parse('$baseUrl/retailer/profile.php');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'login_app/1.0',
          },
          body: jsonEncode({
            'retailer_id': finalRetailerId,
            'action': 'update_password',
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        ).timeout(const Duration(seconds: 15));

        print('📊 AuthService: Password Update Response Status: ${response.statusCode}');
        print('📊 AuthService: Password Update Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data;
        } else {
          return {
            'status': 'error',
            'message': 'Password update API returned status: ${response.statusCode}',
            'code': 'HTTP_ERROR'
          };
        }
      }
      
      // Handle general profile update
      final url = Uri.parse('$baseUrl/retailer/profile.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode({
          'retailer_id': finalRetailerId,
          'action': 'update',
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (middleName != null) 'middle_name': middleName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📊 AuthService: Profile Update Response Status: ${response.statusCode}');
      print('📊 AuthService: Profile Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'status': 'error',
          'message': 'Profile update API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update retailer profile: $e');
      return {'status': 'error', 'message': 'Failed to update profile: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> _uploadProfileImage(File imageFile, String retailerId) async {
    try {
      print('🔄 AuthService: Uploading profile image...');
      print('📁 AuthService: Image file path: ${imageFile.path}');
      print('📁 AuthService: Image file exists: ${await imageFile.exists()}');
      print('📁 AuthService: Image file size: ${await imageFile.length()} bytes');
      print('🆔 AuthService: Retailer ID: $retailerId');
      
      final url = Uri.parse('$baseUrl/retailer/profile.php?retailer_id=$retailerId');
      print('🔗 AuthService: Upload URL: $url');
      
      final request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll({
        'User-Agent': 'login_app/1.0',
      });
      
      // Add image file (profile.php expects 'profile_pic' field)
      final imageBytes = await imageFile.readAsBytes();
      print('📦 AuthService: Image bytes length: ${imageBytes.length}');
      
      final filename = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('📝 AuthService: Generated filename: $filename');
      
      final multipartFile = http.MultipartFile.fromBytes(
        'profile_pic',
        imageBytes,
        filename: filename,
      );
      request.files.add(multipartFile);
      
      print('🚀 AuthService: Sending multipart request...');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📊 AuthService: Image Upload Response Status: ${response.statusCode}');
      print('📊 AuthService: Image Upload Response Headers: ${response.headers}');
      print('📊 AuthService: Image Upload Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 AuthService: Parsed response data: $data');
        
        if (data['success'] == true) {
          print('✅ AuthService: Upload successful!');
          print('📁 AuthService: New filename: ${data['data']?['profile_pic']}');
          print('🔗 AuthService: Profile URL: ${data['data']?['profile_pic_url']}');
          
          return {
            'status': 'success',
            'message': data['message'] ?? 'Profile picture uploaded successfully',
            'data': data['data']
          };
      } else {
          print('❌ AuthService: Upload failed - API returned success: false');
          print('❌ AuthService: Error message: ${data['message']}');
          return {
            'status': 'error',
            'message': data['message'] ?? 'Upload failed',
            'code': 'API_ERROR'
          };
        }
      } else {
        print('❌ AuthService: HTTP error - Status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'Image upload API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to upload profile image: $e');
      return {'status': 'error', 'message': 'Failed to upload image: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // Public method for uploading profile picture
  static Future<Map<String, dynamic>> uploadProfilePicture(File imageFile, {String? retailerId}) async {
    try {
      print('🔄 AuthService: Uploading profile picture...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      return await _uploadProfileImage(imageFile, finalRetailerId);
    } catch (e) {
      print('❌ AuthService: Failed to upload profile picture: $e');
      return {'status': 'error', 'message': 'Failed to upload picture: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // Delete profile picture
  static Future<Map<String, dynamic>> deleteProfilePicture({String? retailerId}) async {
    try {
      print('🔄 AuthService: Deleting profile picture...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      final url = Uri.parse('$baseUrl/retailer/profile.php?retailer_id=$finalRetailerId');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('📊 AuthService: Delete Profile Picture Response Status: ${response.statusCode}');
      print('📊 AuthService: Delete Profile Picture Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'status': 'success',
            'message': data['message'] ?? 'Profile picture deleted successfully',
            'data': data['data']
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Delete failed',
            'code': 'API_ERROR'
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Delete API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to delete profile picture: $e');
      return {'status': 'error', 'message': 'Failed to delete picture: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // Helper method to build profile picture URL
  static String buildProfilePictureUrl(String? profilePicFilename) {
    if (profilePicFilename == null || profilePicFilename.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as is
    if (profilePicFilename.startsWith('http')) {
      return profilePicFilename;
    }
    
    // Build URL from server base URL
    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    return '$baseUrlWithoutApi/uploads/profile_pics/$profilePicFilename';
  }

  // Test method to demonstrate photo upload usage
  static Future<void> testPhotoUpload() async {
    print('🧪 AuthService: Testing photo upload integration...');
    
    // Example usage:
    // 1. Upload profile picture
    // final result = await uploadProfilePicture(imageFile);
    // if (result['status'] == 'success') {
    //   print('✅ Upload successful: ${result['message']}');
    //   print('📁 New filename: ${result['data']?['profile_pic']}');
    //   print('🔗 Profile URL: ${result['data']?['profile_pic_url']}');
    // }
    
    // 2. Delete profile picture
    // final deleteResult = await deleteProfilePicture();
    // if (deleteResult['status'] == 'success') {
    //   print('✅ Delete successful: ${deleteResult['message']}');
    // }
    
    // 3. Build profile picture URL
    // final profileUrl = buildProfilePictureUrl('profile_abc123.jpg');
    // print('🔗 Profile URL: $profileUrl');
    
    print('🧪 AuthService: Photo upload test completed. Check comments for usage examples.');
  }

  // Debug method to test profile picture URL construction
  static void debugProfilePictureUrl(String? filename) {
    print('🔍 AuthService: Debugging profile picture URL...');
    print('📁 Filename: $filename');
    print('🌐 Base URL: $baseUrl');
    
    final url = buildProfilePictureUrl(filename);
    print('🔗 Built URL: $url');
    
    // Test with different scenarios
    print('🧪 Testing different scenarios:');
    print('  - null filename: ${buildProfilePictureUrl(null)}');
    print('  - empty filename: ${buildProfilePictureUrl('')}');
    print('  - relative path: ${buildProfilePictureUrl('profile_123.jpg')}');
    print('  - full URL: ${buildProfilePictureUrl('https://example.com/image.jpg')}');
  }

  // ================= RETAILER STORE PRODUCTS API =================
  static Future<Map<String, dynamic>> loadRetailerStoreProducts({
    String? retailerId,
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    bool includeAllProducts = true,
  }) async {
    try {
      print('🔄 AuthService: Loading retailer store products...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      final qp = <String, String>{
        'retailer_id': finalRetailerId,
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
        if (includeAllProducts) 'include_all_products': 'true',
      };
      final url = Uri.parse('$baseUrl/retailer/store_products.php').replace(queryParameters: qp);
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Store Products URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'login_app/1.0',
              if (sessionCookie != null) 'Cookie': sessionCookie,
            },
          )
          .timeout(const Duration(seconds: 20));

      print('📊 AuthService: Store Products API Response Status: ${response.statusCode}');
      print('📊 AuthService: Store Products API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['status'] == 'success' || data['success'] == true;
        return ok
            ? {
                'status': 'success',
                'message': data['message'] ?? 'Store products retrieved successfully',
                'data': data['data'] ?? {},
                'code': 'HTTP_200',
                'http_status': 200,
              }
            : {
                'status': 'error',
                'message': data['message'] ?? 'Failed to load store products',
                'code': 'HTTP_200_PAYLOAD_ERROR',
                'http_status': 200,
              };
      } else {
        return {
          'status': 'error',
          'message': 'Store Products API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to load retailer store products: $e');
      return {'status': 'error', 'message': 'Failed to load store products: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> addRetailerStoreProduct({
    String? retailerId,
    required int productId,
    required double price,
    String? notes,
    int? stockQuantity,
  }) async {
    try {
      print('🔄 AuthService: Adding retailer store product...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      final url = Uri.parse('$baseUrl/retailer/store_products.php');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Add Store Product URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      print('📦 AuthService: Product ID: $productId');
      print('💰 AuthService: Price: $price');
      
      final requestBody = {
        'action': 'add',
        'retailer_id': finalRetailerId,
        'product_id': productId,
        'price': price,
        if (notes != null) 'notes': notes,
        if (stockQuantity != null) 'stock_quantity': stockQuantity,
      };
      
      print('📤 AuthService: Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (sessionCookie != null) 'Cookie': sessionCookie,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      print('📊 AuthService: Add Store Product Response Status: ${response.statusCode}');
      print('📊 AuthService: Add Store Product Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['status'] == 'success' || data['success'] == true;
        return ok
            ? {'status': 'success', 'message': data['message'] ?? 'Product added', 'data': data['data'] ?? {}, 'code': 'HTTP_200', 'http_status': 200}
            : {'status': 'error', 'message': data['message'] ?? 'Failed to add product', 'code': 'HTTP_200_PAYLOAD_ERROR', 'http_status': 200};
      } else {
        return {
          'status': 'error',
          'message': 'Add Store Product API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to add retailer store product: $e');
      return {'status': 'error', 'message': 'Failed to add store product: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateRetailerStoreProduct({
    String? retailerId,
    required int storeProductId,
    double? price,
    String? notes,
    int? stockQuantity,
    bool? isActive,
  }) async {
    try {
      print('🔄 AuthService: Updating retailer store product...');
      final session = await validateRetailerSession();
      if (session['status'] != 'success') return session;
      
      final finalRetailerId = retailerId ?? session['data']['retailer_id'];
      final url = Uri.parse('$baseUrl/retailer/store_products.php');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode({
          'retailer_id': finalRetailerId,
          'action': 'update',
          'store_product_id': storeProductId,
          if (price != null) 'price': price,
          if (notes != null) 'notes': notes,
          if (stockQuantity != null) 'stock_quantity': stockQuantity,
          if (isActive != null) 'is_active': isActive,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'status': 'error',
          'message': 'Update Store Product API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update retailer store product: $e');
      return {'status': 'error', 'message': 'Failed to update store product: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> removeRetailerStoreProduct({
    String? retailerId,
    required int productId,
  }) async {
    try {
      print('🔄 AuthService: Removing retailer store product...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      final url = Uri.parse('$baseUrl/retailer/store_products.php');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Remove Store Product URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (sessionCookie != null) 'Cookie': sessionCookie,
        },
        body: jsonEncode({
          'action': 'remove',
          'retailer_id': finalRetailerId,
          'product_id': productId,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📊 AuthService: Remove Store Product API Response Status: ${response.statusCode}');
      print('📊 AuthService: Remove Store Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['status'] == 'success' || data['success'] == true;
        return ok
            ? {'status': 'success', 'message': data['message'] ?? 'Product removed', 'data': data['data'] ?? {}, 'code': 'HTTP_200', 'http_status': 200}
            : {'status': 'error', 'message': data['message'] ?? 'Failed to remove product', 'code': 'HTTP_200_PAYLOAD_ERROR', 'http_status': 200};
      } else {
        return {
          'status': 'error',
          'message': 'Remove Store Product API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to remove retailer store product: $e');
      return {'status': 'error', 'message': 'Failed to remove store product: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= RETAILER PRODUCT CATALOG API =================
  static Future<Map<String, dynamic>> loadRetailerProductCatalog({
    String? retailerId,
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('🔄 AuthService: Loading retailer product catalog...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      // product_catalog.php uses GET for listing with query params
      final qp = <String, String>{
        'retailer_id': finalRetailerId.toString(),
        'limit': limit.toString(),
        'offset': ((page - 1) * limit).toString(),
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
          if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
          if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
      };
      final url = Uri.parse('$baseUrl/retailer/product_catalog.php').replace(queryParameters: qp);
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Product Catalog URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'login_app/1.0',
              if (sessionCookie != null) 'Cookie': sessionCookie,
            },
          )
          .timeout(const Duration(seconds: 15));

      print('📊 AuthService: Product Catalog API Response Status: ${response.statusCode}');
      print('📊 AuthService: Product Catalog API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['success'] == true;
        return ok
            ? {
                'status': 'success',
                'message': data['message'] ?? 'Product catalog retrieved successfully',
                'data': data['data'] ?? {},
                'code': 'HTTP_200',
                'http_status': 200,
              }
            : {
                'status': 'error',
                'message': data['message'] ?? 'Failed to load product catalog',
                'code': 'HTTP_200_PAYLOAD_ERROR',
                'http_status': 200,
              };
      } else {
        return {
          'status': 'error',
          'message': 'Product Catalog API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to load retailer product catalog: $e');
      return {'status': 'error', 'message': 'Failed to load product catalog: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerProductCatalogItem({
    String? retailerId,
    required int productId,
  }) async {
    try {
      print('🔄 AuthService: Getting retailer product catalog item...');
      
      // POST action=get (no retailer_id needed for product detail)
      final url = Uri.parse('$baseUrl/retailer/product_catalog.php');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Product Catalog Item URL: $url');
      print('📦 AuthService: Product ID: $productId');
      
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'login_app/1.0',
              if (sessionCookie != null) 'Cookie': sessionCookie,
        },
        body: jsonEncode({
          'product_id': productId,
        }),
          )
          .timeout(const Duration(seconds: 15));

      print('📊 AuthService: Product Catalog Item Response Status: ${response.statusCode}');
      print('📊 AuthService: Product Catalog Item Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['success'] == true;
        return ok
            ? {
                'status': 'success',
                'message': data['message'] ?? 'Product details retrieved successfully',
                'data': data['data'] ?? {},
                'code': 'HTTP_200',
                'http_status': 200,
              }
            : {
                'status': 'error',
                'message': data['message'] ?? 'Failed to get product details',
                'code': 'HTTP_200_PAYLOAD_ERROR',
                'http_status': 200,
              };
      } else {
        return {
          'status': 'error',
          'message': 'Product Catalog Item API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer product catalog item: $e');
      return {'status': 'error', 'message': 'Failed to get product catalog item: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getRetailerProductCategories({String? retailerId}) async {
    try {
      print('🔄 AuthService: Getting retailer product categories...');
      
      // Get retailer ID from session or parameter
      String? finalRetailerId = retailerId;
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        final currentUser = await getCurrentUser();
        finalRetailerId = currentUser?['id']?.toString();
      }
      if ((finalRetailerId == null || finalRetailerId.isEmpty) && _cachedRetailerId != null) {
        finalRetailerId = _cachedRetailerId;
        print('🗂️ AuthService: Using cached retailer id: $_cachedRetailerId');
      }
      
      if (finalRetailerId == null || finalRetailerId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Retailer ID not found. Please login again.',
          'code': 'NO_RETAILER_ID',
        };
      }
      
      // Categories can be derived via GET request (same as product catalog)
      final url = Uri.parse('$baseUrl/retailer/product_catalog.php?retailer_id=$finalRetailerId&limit=1');
      final sessionCookie = getSessionCookie();
      
      print('🔗 AuthService: Product Categories URL: $url');
      print('🆔 AuthService: Using retailer ID: $finalRetailerId');
      
      final response = await http
          .get(
        url,
        headers: {
              'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
              if (sessionCookie != null) 'Cookie': sessionCookie,
            },
          )
          .timeout(const Duration(seconds: 15));

      print('📊 AuthService: Product Categories Response Status: ${response.statusCode}');
      print('📊 AuthService: Product Categories Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['success'] == true;
        return ok
            ? {
                'status': 'success',
                'message': data['message'] ?? 'Product categories retrieved successfully',
                'data': data['data'] ?? {},
                'code': 'HTTP_200',
                'http_status': 200,
              }
            : {
                'status': 'error',
                'message': data['message'] ?? 'Failed to get product categories',
                'code': 'HTTP_200_PAYLOAD_ERROR',
                'http_status': 200,
              };
      } else {
        return {
          'status': 'error',
          'message': 'Product Categories API returned status: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer product categories: $e');
      return {'status': 'error', 'message': 'Failed to get product categories: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= CONSUMER COMPLAINTS API =================
  static Future<Map<String, dynamic>> loadConsumerComplaints({String? consumerId, int page = 1, int limit = 10}) async {
    try {
      print('🔄 AuthService: Loading consumer complaints...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/complaints.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'consumer_id': finalConsumerId, 'action': 'list', 'page': page, 'limit': limit}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to load consumer complaints: $e');
      return {'status': 'error', 'message': 'Failed to load complaints: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> submitConsumerComplaint({
    String? consumerId,
    required String issueDescription,
    required String retailerName,
    String? additionalDetails,
  }) async {
    try {
      print('🔄 AuthService: Submitting consumer complaint...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/complaints.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({
          'consumer_id': finalConsumerId,
          'action': 'submit',
          'issue_description': issueDescription,
          'retailer_name': retailerName,
          'additional_details': additionalDetails,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to submit consumer complaint: $e');
      return {'status': 'error', 'message': 'Failed to submit complaint: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= CONSUMER NOTIFICATIONS API =================
  static Future<Map<String, dynamic>> loadConsumerNotifications({String? consumerId}) async {
    try {
      print('🔄 AuthService: Loading consumer notifications...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/notifications.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'consumer_id': finalConsumerId, 'action': 'list'}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to load consumer notifications: $e');
      return {'status': 'error', 'message': 'Failed to load notifications: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> markConsumerNotificationRead({String? consumerId, required int notificationId}) async {
    try {
      print('🔄 AuthService: Marking consumer notification as read...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/notifications.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'consumer_id': finalConsumerId, 'action': 'mark_read', 'notification_id': notificationId}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to mark consumer notification as read: $e');
      return {'status': 'error', 'message': 'Failed to mark as read: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= CONSUMER PRODUCTS API =================
  static Future<Map<String, dynamic>> loadConsumerProducts({
    String? consumerId,
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    try {
      print('🔄 AuthService: Loading consumer products...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/products.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({
          'consumer_id': finalConsumerId,
          'action': 'list',
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to load consumer products: $e');
      return {'status': 'error', 'message': 'Failed to load products: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> getConsumerProduct({String? consumerId, required int productId}) async {
    try {
      print('🔄 AuthService: Getting consumer product...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/products.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'consumer_id': finalConsumerId, 'action': 'get', 'product_id': productId}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to get consumer product: $e');
      return {'status': 'error', 'message': 'Failed to get product: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> addProductToWatchlist({
    String? consumerId,
    required int productId,
  }) async {
    try {
      print('🔄 AuthService: Adding product to watchlist...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/products.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({
          'consumer_id': finalConsumerId,
          'action': 'add_to_watchlist',
          'product_id': productId,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to add product to watchlist: $e');
      return {'status': 'error', 'message': 'Failed to add to watchlist: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // ================= CONSUMER PROFILE API =================
  static Future<Map<String, dynamic>> getConsumerProfile({String? consumerId}) async {
    try {
      print('🔄 AuthService: Getting consumer profile...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/profile.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({'consumer_id': finalConsumerId, 'action': 'get'}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to get consumer profile: $e');
      return {'status': 'error', 'message': 'Failed to get profile: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateConsumerProfile({
    String? consumerId,
    String? firstName,
    String? lastName,
    String? middleName,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      print('🔄 AuthService: Updating consumer profile...');
      final session = await validateConsumerSession();
      if (session['status'] != 'success') return session;
      final finalConsumerId = consumerId ?? session['data']['consumer_id'];
      final url = Uri.parse('$baseUrl/consumer/profile.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'login_app/1.0'},
        body: jsonEncode({
          'consumer_id': finalConsumerId,
          'action': 'update',
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (middleName != null) 'middle_name': middleName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}', 'code': 'HTTP_ERROR'};
      }
    } catch (e) {
      print('❌ AuthService: Failed to update consumer profile: $e');
      return {'status': 'error', 'message': 'Failed to update profile: $e', 'code': 'NETWORK_ERROR'};
    }
  }

  // Load dashboard data by role
  static Future<Map<String, dynamic>> loadDashboardDataByRole(String role) async {
    print('🎯 AuthService: Loading dashboard data for role: $role');
    
    switch (role.toLowerCase()) {
      case 'admin':
        return await loadAdminDashboard();
      case 'consumer':
        return await loadConsumerDashboard();
      case 'retailer':
        return await loadRetailerDashboard();
      default:
        return {
          'status': 'error',
          'message': 'Unknown user role: $role',
          'code': 'UNKNOWN_ROLE'
        };
    }
  }

  // Refresh dashboard data for a specific role
  static Future<Map<String, dynamic>> refreshDashboardData(String role) async {
    print('🔄 AuthService: Refreshing dashboard data for role: $role');
    return await loadDashboardDataByRole(role);
  }

  // Check API health for all dashboard endpoints
  static Future<Map<String, dynamic>> checkDashboardApiHealth() async {
    try {
      print('🏥 AuthService: Checking dashboard API health...');
      
      final endpoints = [
        {'name': 'Admin Dashboard', 'url': '$baseUrl/admin/dashboard.php'},
        {'name': 'Consumer Dashboard', 'url': '$baseUrl/consumer/dashboard.php'},
        {'name': 'Retailer Dashboard', 'url': '$baseUrl/retailer/dashboard.php'},
      ];

      final results = <Map<String, dynamic>>[];

      for (final endpoint in endpoints) {
        try {
          final url = Uri.parse(endpoint['url']!);
          final response = await http.get(url);
          
          results.add({
            'endpoint': endpoint['name'],
            'status': response.statusCode,
            'healthy': response.statusCode == 200,
            'response_time': DateTime.now().millisecondsSinceEpoch
          });
        } catch (e) {
          results.add({
            'endpoint': endpoint['name'],
            'status': 'error',
            'healthy': false,
            'error': e.toString()
          });
        }
      }

      final healthyCount = results.where((r) => r['healthy'] == true).length;
      final totalCount = results.length;

      return {
        'status': 'success',
        'message': 'Dashboard API health check completed',
        'overall_health': (healthyCount / totalCount * 100).round(),
        'healthy_endpoints': healthyCount,
        'total_endpoints': totalCount,
        'endpoints': results,
        'timestamp': DateTime.now().toIso8601String()
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to check dashboard API health: $e',
        'timestamp': DateTime.now().toIso8601String()
      };
    }
  }

  // ================= REGISTRATION VALIDATION METHODS =================
  
  /// Validates consumer registration data
  static Map<String, dynamic> _validateConsumerData({
    required String username,
    required String password,
    required String confirmPassword,
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    required String birthdate,
    required int age,
    required int locationId,
  }) {
    // Check required fields
    if (username.trim().isEmpty) {
      return {'valid': false, 'message': 'Username is required', 'code': 'MISSING_USERNAME'};
    }
    if (password.trim().isEmpty) {
      return {'valid': false, 'message': 'Password is required', 'code': 'MISSING_PASSWORD'};
    }
    if (confirmPassword.trim().isEmpty) {
      return {'valid': false, 'message': 'Confirm password is required', 'code': 'MISSING_CONFIRM_PASSWORD'};
    }
    if (email.trim().isEmpty) {
      return {'valid': false, 'message': 'Email is required', 'code': 'MISSING_EMAIL'};
    }
    if (firstName.trim().isEmpty) {
      return {'valid': false, 'message': 'First name is required', 'code': 'MISSING_FIRST_NAME'};
    }
    if (lastName.trim().isEmpty) {
      return {'valid': false, 'message': 'Last name is required', 'code': 'MISSING_LAST_NAME'};
    }
    if (gender.trim().isEmpty) {
      return {'valid': false, 'message': 'Gender is required', 'code': 'MISSING_GENDER'};
    }
    if (birthdate.trim().isEmpty) {
      return {'valid': false, 'message': 'Birthdate is required', 'code': 'MISSING_BIRTHDATE'};
    }
    if (age <= 0) {
      return {'valid': false, 'message': 'Age is required', 'code': 'MISSING_AGE'};
    }
    if (locationId <= 0) {
      return {'valid': false, 'message': 'Location ID is required', 'code': 'MISSING_LOCATION_ID'};
    }

    // Validate password strength (minimum 6 characters for consumer)
    if (password.length < 6) {
      return {'valid': false, 'message': 'Password must be at least 6 characters long', 'code': 'WEAK_PASSWORD'};
    }

    // Validate password confirmation
    if (password != confirmPassword) {
      return {'valid': false, 'message': 'Password and confirm password do not match', 'code': 'PASSWORD_MISMATCH'};
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      return {'valid': false, 'message': 'Invalid email format', 'code': 'INVALID_EMAIL'};
    }

    // Validate gender
    if (!['male', 'female', 'other'].contains(gender.toLowerCase())) {
      return {'valid': false, 'message': 'Gender must be male, female, or other', 'code': 'INVALID_GENDER'};
    }

    // Validate birthdate format (YYYY-MM-DD)
    if (!_isValidDate(birthdate)) {
      return {'valid': false, 'message': 'Birthdate must be in YYYY-MM-DD format', 'code': 'INVALID_BIRTHDATE'};
    }

    // Validate age range
    if (age < 18 || age > 120) {
      return {'valid': false, 'message': 'Age must be between 18 and 120', 'code': 'INVALID_AGE'};
    }

    return {'valid': true, 'message': 'Validation passed'};
  }

  /// Validates retailer registration data
  static Map<String, dynamic> _validateRetailerData({
    required String username,
    required String password,
    required String confirmPassword,
    required String registrationCode,
  }) {
    // Check required fields
    if (username.trim().isEmpty) {
      return {'valid': false, 'message': 'Username is required', 'code': 'MISSING_USERNAME'};
    }
    if (password.trim().isEmpty) {
      return {'valid': false, 'message': 'Password is required', 'code': 'MISSING_PASSWORD'};
    }
    if (confirmPassword.trim().isEmpty) {
      return {'valid': false, 'message': 'Confirm password is required', 'code': 'MISSING_CONFIRM_PASSWORD'};
    }
    if (registrationCode.trim().isEmpty) {
      return {'valid': false, 'message': 'Registration code is required', 'code': 'MISSING_REGISTRATION_CODE'};
    }

    // Validate password strength (retailer requires stronger password)
    if (!_isStrongPassword(password)) {
      return {'valid': false, 'message': 'Password must be at least 8 characters long, include 1 uppercase letter, 1 number, and 1 special character', 'code': 'WEAK_PASSWORD'};
    }

    // Validate password confirmation
    if (password != confirmPassword) {
      return {'valid': false, 'message': 'Password and confirm password do not match', 'code': 'PASSWORD_MISMATCH'};
    }

    // Validate registration code format (6 digits)
    if (!RegExp(r'^\d{6}$').hasMatch(registrationCode)) {
      return {'valid': false, 'message': 'Registration code must be exactly 6 digits', 'code': 'INVALID_REGISTRATION_CODE_FORMAT'};
    }

    return {'valid': true, 'message': 'Validation passed'};
  }

  // ================= REGISTRATION UTILITY METHODS =================
  
  /// Handles registration response from the API
  static Map<String, dynamic> _handleRegistrationResponse(http.Response response, String userType) {
    print('🔍 AuthService: Processing response for $userType');
    print('🔍 AuthService: Status Code: ${response.statusCode}');
    print('🔍 AuthService: Response Body: ${response.body}');
    print('🔍 AuthService: Response Headers: ${response.headers}');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print('🔍 AuthService: Parsed JSON: $data');
        
        if (data['status'] == 'success') {
          print('✅ AuthService: Registration successful for $userType');
          return {
            'status': 'success',
            'message': data['message'] ?? '${userType.capitalize()} registration successful',
            'data': data['data'],
            'code': data['code'] ?? '${userType.toUpperCase()}_REGISTRATION_SUCCESS',
            'debug_info': {
              'response_status': response.statusCode,
              'response_body': response.body,
              'parsed_data': data,
            }
          };
        } else {
          print('❌ AuthService: Registration failed for $userType: ${data['message']}');
          return {
            'status': 'error',
            'message': data['message'] ?? 'Registration failed',
            'code': data['code'] ?? 'REGISTRATION_FAILED',
            'debug_info': {
              'response_status': response.statusCode,
              'response_body': response.body,
              'parsed_data': data,
            }
          };
        }
      } catch (e) {
        print('❌ AuthService: Error parsing response: $e');
        print('❌ AuthService: Raw response: ${response.body}');
        return {
          'status': 'error',
          'message': 'Invalid response format from server',
          'code': 'INVALID_RESPONSE_FORMAT',
          'debug_info': {
            'response_status': response.statusCode,
            'response_body': response.body,
            'parse_error': e.toString(),
          }
        };
      }
    } else {
      print('❌ AuthService: HTTP error ${response.statusCode} for $userType');
      try {
        final data = jsonDecode(response.body);
        print('❌ AuthService: Error response data: $data');
        return {
          'status': 'error',
          'message': data['message'] ?? 'Server error occurred',
          'code': data['code'] ?? 'SERVER_ERROR',
          'http_status': response.statusCode,
          'debug_info': {
            'response_status': response.statusCode,
            'response_body': response.body,
            'parsed_data': data,
          }
        };
      } catch (e) {
        print('❌ AuthService: Error parsing error response: $e');
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'SERVER_ERROR',
          'http_status': response.statusCode,
          'debug_info': {
            'response_status': response.statusCode,
            'response_body': response.body,
            'parse_error': e.toString(),
          }
        };
      }
    }
  }

  /// Validates email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validates date format (YYYY-MM-DD)
  static bool _isValidDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return parsedDate.toString().substring(0, 10) == date;
    } catch (e) {
      return false;
    }
  }

  /// Validates strong password for retailers
  static bool _isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 number, 1 special character
    return RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*])[A-Za-z\d!@#$%^&*]{8,}$').hasMatch(password);
  }

  /// Gets user type display name
  static String getUserTypeDisplay(String userType) {
    switch (userType.toLowerCase()) {
      case 'consumer':
        return 'Consumer';
      case 'retailer':
        return 'Retailer';
      default:
        return userType;
    }
  }

  /// Gets gender display name
  static String getGenderDisplay(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return gender;
    }
  }

  // ================= ADMIN API ENDPOINTS =================
  
  // Admin Users Management
  static Future<Map<String, dynamic>> getAdminUsers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      print('🔍 AuthService: Getting admin users - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/admin_users.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Admin Users API Response Status: ${response.statusCode}');
      print('📊 Admin Users API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Admin users retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve admin users: ${response.statusCode}',
          'code': 'ADMIN_USERS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get admin users: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Complaints Management
  static Future<Map<String, dynamic>> getComplaints({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      print('🔍 AuthService: Getting complaints - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/complaints.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Complaints API Response Status: ${response.statusCode}');
      print('📊 Complaints API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Complaints retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve complaints: ${response.statusCode}',
          'code': 'COMPLAINTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get complaints: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Consumers Management
  static Future<Map<String, dynamic>> getConsumers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      print('🔍 AuthService: Getting consumers - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/consumers.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Consumers API Response Status: ${response.statusCode}');
      print('📊 Consumers API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Consumers retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve consumers: ${response.statusCode}',
          'code': 'CONSUMERS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get consumers: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Notifications Management
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
    String? type,
     String? status,
  }) async {
    try {
      print('🔍 AuthService: Getting notifications - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/notifications.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (type != null && type.isNotEmpty) 'type': type,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Notifications API Response Status: ${response.statusCode}');
      print('📊 Notifications API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Notifications retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve notifications: ${response.statusCode}',
          'code': 'NOTIFICATIONS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get notifications: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Mark a specific notification as read
  static Future<Map<String, dynamic>> markNotificationRead({required int notificationId}) async {
    try {
      print('🔄 AuthService: Marking notification as read - ID: $notificationId');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/notifications.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
        body: jsonEncode({
          'action': 'mark_read',
          'notification_id': notificationId,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Mark Notification Read Response Status: ${response.statusCode}');
      print('📊 Mark Notification Read Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Notification marked as read',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to mark notification as read: ${response.statusCode}',
          'code': 'MARK_READ_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to mark notification as read: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  /// Mark all notifications as read
  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      print('🔄 AuthService: Marking all notifications as read');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/notifications.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
        body: jsonEncode({
          'action': 'mark_all_read',
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Mark All Notifications Read Response Status: ${response.statusCode}');
      print('📊 Mark All Notifications Read Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'All notifications marked as read',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to mark all notifications as read: ${response.statusCode}',
          'code': 'MARK_ALL_READ_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to mark all notifications as read: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  // Price Freeze Management
  static Future<Map<String, dynamic>> getPriceFreeze({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      print('🔍 AuthService: Getting price freeze data - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Price Freeze API Response Status: ${response.statusCode}');
      print('📊 Price Freeze API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Price freeze data retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve price freeze data: ${response.statusCode}',
          'code': 'PRICE_FREEZE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze data: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Products Management
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
  }) async {
    try {
      print('🔍 AuthService: Getting products - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/products.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
            if (category != null && category.isNotEmpty) 'category': category,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Products API Response Status: ${response.statusCode}');
      print('📊 Products API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Products retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve products: ${response.statusCode}',
          'code': 'PRODUCTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Admin Profile Management
  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      print('🔍 AuthService: Getting admin profile');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Admin Profile API Response Status: ${response.statusCode}');
      print('📊 Admin Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Admin profile retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve admin profile: ${response.statusCode}',
          'code': 'ADMIN_PROFILE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get admin profile: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Update Admin Profile
  static Future<Map<String, dynamic>> updateAdminProfile(Map<String, dynamic> profileData) async {
    try {
      print('🔍 AuthService: Updating admin profile');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
        body: jsonEncode(profileData),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Admin Profile API Response Status: ${response.statusCode}');
      print('📊 Update Admin Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Admin profile updated successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update admin profile: ${response.statusCode}',
          'code': 'ADMIN_PROFILE_UPDATE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update admin profile: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Update Admin Password
  static Future<Map<String, dynamic>> updateAdminPassword(Map<String, dynamic> passwordData) async {
    try {
      print('🔍 AuthService: Updating admin password');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/change_password.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
        body: jsonEncode(passwordData),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Admin Password API Response Status: ${response.statusCode}');
      print('📊 Update Admin Password API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Admin password updated successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update admin password: ${response.statusCode}',
          'code': 'ADMIN_PASSWORD_UPDATE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update admin password: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Upload Admin Profile Picture
  static Future<Map<String, dynamic>> uploadAdminProfilePicture(File imageFile) async {
    try {
      print('🔍 AuthService: Uploading admin profile picture');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/upload_profile_picture.php'),
      );
      
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'login_app/1.0',
        if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
      });
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Upload Admin Profile Picture API Response Status: ${response.statusCode}');
      print('📊 Upload Admin Profile Picture API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Admin profile picture uploaded successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to upload admin profile picture: ${response.statusCode}',
          'code': 'ADMIN_PROFILE_PICTURE_UPLOAD_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to upload admin profile picture: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Retailer Codes Management
  static Future<Map<String, dynamic>> getRetailerCodes({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      print('🔍 AuthService: Getting retailer codes - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/retailer_codes.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Retailer Codes API Response Status: ${response.statusCode}');
      print('📊 Retailer Codes API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Retailer codes retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve retailer codes: ${response.statusCode}',
          'code': 'RETAILER_CODES_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailer codes: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Retailers Management
  static Future<Map<String, dynamic>> getRetailers({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      print('🔍 AuthService: Getting retailers - Page: $page, Limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/retailers.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Retailers API Response Status: ${response.statusCode}');
      print('📊 Retailers API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Retailers retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve retailers: ${response.statusCode}',
          'code': 'RETAILERS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get retailers: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Admin: Create a retailer account/store via server API
  /// Mirrors website capability at `https://dtisrpmonitoring.bccbsis.com/` admin module
  /// Required: store_name, owner_name, username, password, location_id
  /// Optional: email, phone, address, description
  static Future<Map<String, dynamic>> adminCreateRetailer({
    required String storeName,
    required String ownerName,
    required String username,
    required String password,
    required int locationId,
    String? email,
    String? phone,
    String? address,
    String? description,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/retailers.php');

      final Map<String, dynamic> body = {
        'action': 'create',
        'store_name': storeName,
        'owner_name': ownerName,
        'username': username,
        'password': password,
        'location_id': locationId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': (data['success'] == true) ? 'success' : 'error',
          'message': data['message'] ?? ((data['success'] == true) ? 'Retailer created' : 'Failed to create retailer'),
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create retailer: ${response.statusCode}',
          'code': 'RETAILER_CREATE_ERROR',
          'http_status': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED',
      };
    }
  }

  // Statistics Management
  static Future<Map<String, dynamic>> getStats({
    String? period,
    String? type,
  }) async {
    try {
      print('🔍 AuthService: Getting statistics - Period: $period, Type: $type');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats.php').replace(
          queryParameters: {
            if (period != null && period.isNotEmpty) 'period': period,
            if (type != null && type.isNotEmpty) 'type': type,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (AuthService.getSessionCookie() != null) 'Cookie': AuthService.getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Stats API Response Status: ${response.statusCode}');
      print('📊 Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Statistics retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve statistics: ${response.statusCode}',
          'code': 'STATS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get statistics: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Store Prices Management
  static Future<Map<String, dynamic>> getStorePrices({
    int page = 1,
    int limit = 10,
    String? search,
    String? storeId,
    String? productId,
  }) async {
    try {
      print('🔍 AuthService: Getting store prices - Page: $page, Limit: $limit');
      
      final uri = Uri.parse('$baseUrl/admin/store_prices.php').replace(
          queryParameters: {
            if (page > 1) 'page': page.toString(),
            if (limit != 10) 'limit': limit.toString(),
            if (search != null && search.isNotEmpty) 'search': search,
            if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
            if (productId != null && productId.isNotEmpty) 'product_id': productId,
          },
      );

      // Prefer browser-like headers for GET; avoid Content-Type and Cookie
      const browserHeaders = {
        'Accept': 'application/json, text/plain, */*',
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
      };

      var response = await http.get(uri, headers: browserHeaders).timeout(const Duration(seconds: 30));
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Retry without headers as some servers reject non-browser clients
        response = await http.get(uri).timeout(const Duration(seconds: 30));
      }

      print('📊 Store Prices API Response Status: ${response.statusCode}');
      print('📊 Store Prices API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': 'Store prices retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve store prices: ${response.statusCode}',
          'code': 'STORE_PRICES_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get store prices: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= PRODUCT FOLDER MANAGEMENT API =================
  
  /// Get all folders (main and sub folders with product counts)
  /// Get folders from database via db_conn.php
  /// 
  /// This method fetches folder data from the database using:
  /// - API Endpoint: admin/product_folder_management.php?action=folders
  /// - Database Connection: The PHP endpoint should use db_conn.php for database access
  /// - All data comes directly from the database - no sample/mock data
  static Future<Map<String, dynamic>> getFolders({
    String? search,
    String type = 'all', // all, main, sub
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      print('🔍 AuthService: Getting folders from DATABASE via db_conn.php');
      print('🔍 Type: $type, Limit: $limit, Offset: $offset');
      print('📊 API Endpoint: admin/product_folder_management.php?action=folders');
      print('📊 Ensure PHP endpoint uses db_conn.php for database connections');
      
      final apiUrl = Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
        queryParameters: {
          'action': 'folders',
          if (search != null && search.isNotEmpty) 'search': search,
          'type': type,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      print('📊 Full API URL: $apiUrl');
      
      final response = await http.get(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Get Folders API Response Status: ${response.statusCode}');
      print('📊 Get Folders API Response Body (first 1000 chars): ${response.body.length > 1000 ? response.body.substring(0, 1000) + '...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate response structure
        if (data['success'] == true) {
          print('✅ Successfully retrieved folders from DATABASE via db_conn.php');
          
          // Check if we have actual folder data
          final hasData = data['data'] != null || 
                         data['folders'] != null || 
                         (data['data'] is Map && (data['data']['folders'] != null || data['data']['data'] != null));
          
          if (!hasData) {
            print('⚠️ WARNING: API returned success=true but no folder data found');
            print('⚠️ Response structure: ${data.keys.toList()}');
          } else {
            print('✅ Folder data found in database response');
          }
          
          return {
            'status': 'success',
            'message': 'Folders retrieved successfully from database',
            'data': data,
          };
        } else {
          print('❌ API returned success=false: ${data['message'] ?? 'Unknown error'}');
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to retrieve folders from database',
            'data': data,
          };
        }
      } else {
        print('❌ API returned HTTP status ${response.statusCode}');
        print('❌ Response body: ${response.body.substring(0, 500)}');
        return {
          'status': 'error',
          'message': 'Failed to retrieve folders: ${response.statusCode}',
          'code': 'FOLDERS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folders: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get hierarchical folder tree structure
  static Future<Map<String, dynamic>> getFolderTree({int? parentId}) async {
    try {
      print('🔍 AuthService: Getting folder tree - Parent ID: $parentId');
      
      final queryParams = {
        'action': 'folder_tree',
        if (parentId != null) 'parent_id': parentId.toString(),
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Folder Tree API Response Status: ${response.statusCode}');
      print('📊 Folder Tree API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folder tree retrieved successfully' : 'Failed to retrieve folder tree',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folder tree: ${response.statusCode}',
          'code': 'FOLDER_TREE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folder tree: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get folder details by ID
  static Future<Map<String, dynamic>> getFolderDetails({
    required int folderId,
    String folderType = 'auto', // auto, main, sub, hierarchical
  }) async {
    try {
      print('🔍 AuthService: Getting folder details - ID: $folderId, Type: $folderType');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {
            'action': 'folder_details',
            'folder_id': folderId.toString(),
            'folder_type': folderType,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Folder Details API Response Status: ${response.statusCode}');
      print('📊 Folder Details API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folder details retrieved successfully' : 'Failed to retrieve folder details',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folder details: ${response.statusCode}',
          'code': 'FOLDER_DETAILS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folder details: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get folder children
  static Future<Map<String, dynamic>> getFolderChildren({
    required int parentId,
    String folderType = 'hierarchical',
  }) async {
    try {
      print('🔍 AuthService: Getting folder children - Parent ID: $parentId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {
            'action': 'folder_children',
            'parent_id': parentId.toString(),
            'folder_type': folderType,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Folder Children API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folder children retrieved successfully' : 'Failed to retrieve folder children',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folder children: ${response.statusCode}',
          'code': 'FOLDER_CHILDREN_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folder children: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get folder path (breadcrumb)
  static Future<Map<String, dynamic>> getFolderPath({
    required int folderId,
    String folderType = 'hierarchical',
  }) async {
    try {
      print('🔍 AuthService: Getting folder path - ID: $folderId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {
            'action': 'folder_path',
            'folder_id': folderId.toString(),
            'folder_type': folderType,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folder path retrieved successfully' : 'Failed to retrieve folder path',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folder path: ${response.statusCode}',
          'code': 'FOLDER_PATH_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folder path: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get products in a folder
  static Future<Map<String, dynamic>> getFolderProducts({
    required int folderId,
    String folderType = 'auto',
    String? search,
    String? categoryId,
    int? productId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('🔍 AuthService: Getting folder products - Folder ID: $folderId');
      
      final queryParams = {
        'action': 'folder_products',
        'folder_id': folderId.toString(),
        'folder_type': folderType,
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (productId != null) 'product_id': productId.toString(),
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Folder Products API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folder products retrieved successfully' : 'Failed to retrieve folder products',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folder products: ${response.statusCode}',
          'code': 'FOLDER_PRODUCTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folder products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Search folders
  static Future<Map<String, dynamic>> searchFolders({
    required String search,
    String type = 'all',
    int limit = 50,
  }) async {
    try {
      print('🔍 AuthService: Searching folders - Query: $search');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {
            'action': 'search_folders',
            'search': search,
            'type': type,
            'limit': limit.toString(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folders found successfully' : 'Failed to search folders',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to search folders: ${response.statusCode}',
          'code': 'SEARCH_FOLDERS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to search folders: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get folder statistics
  static Future<Map<String, dynamic>> getFolderStats() async {
    try {
      print('🔍 AuthService: Getting folder statistics');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'folder_stats'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['success'] == true ? 'Folder statistics retrieved successfully' : 'Failed to retrieve folder statistics',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folder statistics: ${response.statusCode}',
          'code': 'FOLDER_STATS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get folder stats: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Create main folder
  static Future<Map<String, dynamic>> createMainFolder({
    required String name,
    String? description,
    String color = 'primary',
  }) async {
    try {
      print('📝 AuthService: Creating main folder - Name: $name');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'create_main_folder'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'name': name,
          'description': description ?? '',
          'color': color,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Create Main Folder API Response Status: ${response.statusCode}');
      print('📊 Create Main Folder API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Main folder created successfully' : 'Failed to create main folder'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create main folder: ${response.statusCode}',
          'code': 'CREATE_FOLDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create main folder: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Create sub folder
  static Future<Map<String, dynamic>> createSubFolder({
    required String name,
    required int mainFolderId,
    String? description,
    String color = 'primary',
  }) async {
    try {
      print('📝 AuthService: Creating sub folder - Name: $name, Main Folder ID: $mainFolderId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'create_sub_folder'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'name': name,
          'main_folder_id': mainFolderId,
          'description': description ?? '',
          'color': color,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Create Sub Folder API Response Status: ${response.statusCode}');
      print('📊 Create Sub Folder API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Sub folder created successfully' : 'Failed to create sub folder'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create sub folder: ${response.statusCode}',
          'code': 'CREATE_SUBFOLDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create sub folder: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Create hierarchical folder
  static Future<Map<String, dynamic>> createFolder({
    required String name,
    int? parentId,
    String? description,
    String color = 'primary',
  }) async {
    try {
      print('📝 AuthService: Creating folder - Name: $name, Parent ID: $parentId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'create_folder'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'name': name,
          'parent_id': parentId,
          'description': description ?? '',
          'color': color,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Create Folder API Response Status: ${response.statusCode}');
      print('📊 Create Folder API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folder created successfully' : 'Failed to create folder'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create folder: ${response.statusCode}',
          'code': 'CREATE_FOLDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create folder: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update folder
  static Future<Map<String, dynamic>> updateFolder({
    required int folderId,
    required String name,
    String folderType = 'auto',
    String? description,
    String? color,
  }) async {
    try {
      print('✏️ AuthService: Updating folder - ID: $folderId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'update_folder'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'folder_id': folderId,
          'name': name,
          'folder_type': folderType,
          if (description != null) 'description': description,
          if (color != null) 'color': color,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Folder API Response Status: ${response.statusCode}');
      print('📊 Update Folder API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folder updated successfully' : 'Failed to update folder'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update folder: ${response.statusCode}',
          'code': 'UPDATE_FOLDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update folder: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update folder order/sort
  static Future<Map<String, dynamic>> updateFolderOrder({
    required int folderId,
    required int sortOrder,
    String folderType = 'hierarchical',
  }) async {
    try {
      print('✏️ AuthService: Updating folder order - ID: $folderId, Order: $sortOrder');
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'update_folder_order'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'folder_id': folderId,
          'sort_order': sortOrder,
          'folder_type': folderType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folder order updated successfully' : 'Failed to update folder order'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update folder order: ${response.statusCode}',
          'code': 'UPDATE_ORDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update folder order: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Delete folder
  static Future<Map<String, dynamic>> deleteFolder({
    required int folderId,
    String folderType = 'auto',
    bool forceDelete = false,
  }) async {
    try {
      print('🗑️ AuthService: Deleting folder - ID: $folderId, Force: $forceDelete');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'delete_folder'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'folder_id': folderId,
          'folder_type': folderType,
          'force_delete': forceDelete,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Delete Folder API Response Status: ${response.statusCode}');
      print('📊 Delete Folder API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folder deleted successfully' : 'Failed to delete folder'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to delete folder: ${response.statusCode}',
          'code': 'DELETE_FOLDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to delete folder: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Bulk delete folders
  static Future<Map<String, dynamic>> bulkDeleteFolders({
    required List<int> folderIds,
    String folderType = 'auto',
    bool forceDelete = false,
  }) async {
    try {
      print('🗑️ AuthService: Bulk deleting folders - Count: ${folderIds.length}');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'bulk_delete_folders'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'folder_ids': folderIds,
          'folder_type': folderType,
          'force_delete': forceDelete,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folders deleted successfully' : 'Failed to delete folders'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to bulk delete folders: ${response.statusCode}',
          'code': 'BULK_DELETE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to bulk delete folders: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Move product to folder
  static Future<Map<String, dynamic>> moveProductToFolder({
    required int productId,
    int? folderId,
    String folderType = 'auto',
    int? mainFolderId,
    int? subFolderId,
  }) async {
    try {
      print('📦 AuthService: Moving product - ID: $productId to Folder: $folderId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'move_product'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'product_id': productId,
          'folder_id': folderId,
          'folder_type': folderType,
          'main_folder_id': mainFolderId,
          'sub_folder_id': subFolderId,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Move Product API Response Status: ${response.statusCode}');
      print('📊 Move Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product moved successfully' : 'Failed to move product'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to move product: ${response.statusCode}',
          'code': 'MOVE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to move product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Move folder to new parent (hierarchical only)
  static Future<Map<String, dynamic>> moveFolder({
    required int folderId,
    int? newParentId,
  }) async {
    try {
      print('📁 AuthService: Moving folder - ID: $folderId to Parent: $newParentId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'move_folder'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'folder_id': folderId,
          'new_parent_id': newParentId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folder moved successfully' : 'Failed to move folder'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to move folder: ${response.statusCode}',
          'code': 'MOVE_FOLDER_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to move folder: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Bulk move products to folder
  static Future<Map<String, dynamic>> bulkMoveProducts({
    required List<int> productIds,
    int? folderId,
    String folderType = 'auto',
    int? mainFolderId,
    int? subFolderId,
  }) async {
    try {
      print('📦 AuthService: Bulk moving products - Count: ${productIds.length}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_folder_management.php').replace(
          queryParameters: {'action': 'bulk_move_products'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'product_ids': productIds,
          'folder_id': folderId,
          'folder_type': folderType,
          'main_folder_id': mainFolderId,
          'sub_folder_id': subFolderId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Products moved successfully' : 'Failed to move products'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to bulk move products: ${response.statusCode}',
          'code': 'BULK_MOVE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to bulk move products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= PRICE MONITORING MANAGEMENT API =================
  
  /// Get monitoring data/forms
  /// API Endpoint: admin/price_monitoring_management.php?action=get_forms
  static Future<Map<String, dynamic>> getMonitoringData({
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
    int? retailerId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 AuthService: Getting monitoring data from database...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=get_forms');
      
      final queryParams = <String, String>{
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
      if (retailerId != null) {
        queryParams['retailer_id'] = retailerId.toString();
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Get Monitoring Data API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring data retrieved successfully' : 'Failed to retrieve monitoring data'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve monitoring data: ${response.statusCode}',
          'code': 'GET_MONITORING_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get monitoring data: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Get specific monitoring form by ID
  /// API Endpoint: admin/price_monitoring_management.php?action=get_form&id={formId}
  static Future<Map<String, dynamic>> getMonitoringForm({
    required int formId,
  }) async {
    try {
      print('🔍 AuthService: Getting monitoring form - ID: $formId');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=get_form');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: {
            'action': 'get_form',
            'id': formId.toString(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Get Monitoring Form API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring form retrieved successfully' : 'Failed to retrieve monitoring form'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve monitoring form: ${response.statusCode}',
          'code': 'GET_FORM_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get monitoring form: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Create monitoring record/form
  /// API Endpoint: admin/price_monitoring_management.php?action=create_form
  static Future<Map<String, dynamic>> createMonitoringRecord({
    required String storeName,
    required String representativeName,
    required String dtiMonitorName,
    required DateTime monitoringDate,
    required List<Map<String, dynamic>> products,
    String? notes,
    String? location,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📝 AuthService: Creating monitoring record...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=create_form');
      
      final requestData = {
        'store_name': storeName,
        'representative_name': representativeName,
        'dti_monitor_name': dtiMonitorName,
        'monitoring_date': monitoringDate.toIso8601String().split('T')[0],
        'products': products,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (location != null && location.isNotEmpty) 'location': location,
        if (additionalData != null) ...additionalData,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: {'action': 'create_form'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Create Monitoring Record API Response Status: ${response.statusCode}');
      print('📊 Create Monitoring Record API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring record created successfully' : 'Failed to create monitoring record'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create monitoring record: ${response.statusCode}',
          'code': 'CREATE_MONITORING_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create monitoring record: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Update monitoring record/form
  /// API Endpoint: admin/price_monitoring_management.php?action=update_form
  static Future<Map<String, dynamic>> updateMonitoringRecord({
    required int formId,
    String? storeName,
    String? representativeName,
    String? dtiMonitorName,
    DateTime? monitoringDate,
    List<Map<String, dynamic>>? products,
    String? notes,
    String? location,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('✏️ AuthService: Updating monitoring record - ID: $formId');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=update_form');
      
      final requestData = <String, dynamic>{
        'id': formId,
      };
      
      if (storeName != null) requestData['store_name'] = storeName;
      if (representativeName != null) requestData['representative_name'] = representativeName;
      if (dtiMonitorName != null) requestData['dti_monitor_name'] = dtiMonitorName;
      if (monitoringDate != null) requestData['monitoring_date'] = monitoringDate.toIso8601String().split('T')[0];
      if (products != null) requestData['products'] = products;
      if (notes != null) requestData['notes'] = notes;
      if (location != null) requestData['location'] = location;
      if (additionalData != null) requestData.addAll(additionalData);
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: {'action': 'update_form'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Update Monitoring Record API Response Status: ${response.statusCode}');
      print('📊 Update Monitoring Record API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring record updated successfully' : 'Failed to update monitoring record'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update monitoring record: ${response.statusCode}',
          'code': 'UPDATE_MONITORING_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update monitoring record: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Delete monitoring record/form
  /// API Endpoint: admin/price_monitoring_management.php?action=delete_form
  static Future<Map<String, dynamic>> deleteMonitoringRecord({
    required int formId,
  }) async {
    try {
      print('🗑️ AuthService: Deleting monitoring record - ID: $formId');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=delete_form');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: {
            'action': 'delete_form',
            'id': formId.toString(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Delete Monitoring Record API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring record deleted successfully' : 'Failed to delete monitoring record'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to delete monitoring record: ${response.statusCode}',
          'code': 'DELETE_MONITORING_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to delete monitoring record: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Get monitoring statistics
  /// API Endpoint: admin/price_monitoring_management.php?action=get_stats
  static Future<Map<String, dynamic>> getMonitoringStatistics({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
    int? retailerId,
  }) async {
    try {
      print('📊 AuthService: Getting monitoring statistics...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=get_stats');
      
      final queryParams = <String, String>{
        'action': 'get_stats',
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
      if (retailerId != null) {
        queryParams['retailer_id'] = retailerId.toString();
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Get Monitoring Statistics API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring statistics retrieved successfully' : 'Failed to retrieve monitoring statistics'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve monitoring statistics: ${response.statusCode}',
          'code': 'GET_STATS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get monitoring statistics: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Get store statistics for monitoring
  /// API Endpoint: admin/price_monitoring_management.php?action=get_store_stats
  static Future<Map<String, dynamic>> getStoreMonitoringStats({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📊 AuthService: Getting store monitoring statistics...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=get_store_stats');
      
      final queryParams = <String, String>{
        'action': 'get_store_stats',
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Get Store Monitoring Stats API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Store statistics retrieved successfully' : 'Failed to retrieve store statistics'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve store statistics: ${response.statusCode}',
          'code': 'GET_STORE_STATS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get store monitoring statistics: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Get product monitoring history
  /// API Endpoint: admin/price_monitoring_management.php?action=get_product_history
  static Future<Map<String, dynamic>> getProductMonitoringHistory({
    String? productName,
    String? storeName,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📊 AuthService: Getting product monitoring history...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=get_product_history');
      
      final queryParams = <String, String>{
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Get Product Monitoring History API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product monitoring history retrieved successfully' : 'Failed to retrieve product monitoring history'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve product monitoring history: ${response.statusCode}',
          'code': 'GET_PRODUCT_HISTORY_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get product monitoring history: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Export monitoring data
  /// API Endpoint: admin/price_monitoring_management.php?action=export_data
  static Future<Map<String, dynamic>> exportMonitoringData({
    String format = 'json', // json, csv, xlsx
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeName,
    int? retailerId,
  }) async {
    try {
      print('📥 AuthService: Exporting monitoring data...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=export_data');
      
      final queryParams = <String, String>{
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
      if (retailerId != null) {
        queryParams['retailer_id'] = retailerId.toString();
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 60));
      
      print('📊 Export Monitoring Data API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring data exported successfully' : 'Failed to export monitoring data'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to export monitoring data: ${response.statusCode}',
          'code': 'EXPORT_MONITORING_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to export monitoring data: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Get monitoring form templates
  /// API Endpoint: admin/price_monitoring_management.php?action=get_templates
  static Future<Map<String, dynamic>> getMonitoringTemplates() async {
    try {
      print('📋 AuthService: Getting monitoring templates...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=get_templates');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: {'action': 'get_templates'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Get Monitoring Templates API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring templates retrieved successfully' : 'Failed to retrieve monitoring templates'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve monitoring templates: ${response.statusCode}',
          'code': 'GET_TEMPLATES_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get monitoring templates: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }
  
  /// Save monitoring form as template
  /// API Endpoint: admin/price_monitoring_management.php?action=save_template
  static Future<Map<String, dynamic>> saveMonitoringTemplate({
    required String templateName,
    required String description,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      print('💾 AuthService: Saving monitoring template...');
      print('📊 API Endpoint: admin/price_monitoring_management.php?action=save_template');
      
      final requestData = {
        'template_name': templateName,
        'description': description,
        'products': products,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/price_monitoring_management.php').replace(
          queryParameters: {'action': 'save_template'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));
      
      print('📊 Save Monitoring Template API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Monitoring template saved successfully' : 'Failed to save monitoring template'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to save monitoring template: ${response.statusCode}',
          'code': 'SAVE_TEMPLATE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to save monitoring template: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= PRICE FREEZE MANAGEMENT API =================
  
  /// Get all products for price freeze
  static Future<Map<String, dynamic>> getPriceFreezeProducts({int? productId}) async {
    try {
      print('🔍 AuthService: Getting price freeze products');
      
      final queryParams = {
        'action': 'products',
        if (productId != null) 'product_id': productId.toString(),
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Price Freeze Products API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Products retrieved successfully' : 'Failed to retrieve products'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve products: ${response.statusCode}',
          'code': 'PRODUCTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get categories for price freeze
  static Future<Map<String, dynamic>> getPriceFreezeCategories() async {
    try {
      print('🔍 AuthService: Getting price freeze categories');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'action': 'categories'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Categories retrieved successfully' : 'Failed to retrieve categories'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve categories: ${response.statusCode}',
          'code': 'CATEGORIES_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze categories: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get locations for price freeze
  static Future<Map<String, dynamic>> getPriceFreezeLocations() async {
    try {
      print('🔍 AuthService: Getting price freeze locations');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'action': 'locations'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Locations retrieved successfully' : 'Failed to retrieve locations'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve locations: ${response.statusCode}',
          'code': 'LOCATIONS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze locations: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get price freeze alert statistics
  static Future<Map<String, dynamic>> getPriceFreezeStatistics() async {
    try {
      print('🔍 AuthService: Getting price freeze statistics');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'action': 'statistics'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Statistics retrieved successfully' : 'Failed to retrieve statistics'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve statistics: ${response.statusCode}',
          'code': 'STATISTICS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze statistics: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get active price freeze alerts
  static Future<Map<String, dynamic>> getActivePriceFreezeAlerts() async {
    try {
      print('🔍 AuthService: Getting active price freeze alerts');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'action': 'active'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Active Alerts API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Active alerts retrieved successfully' : 'Failed to retrieve active alerts'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve active alerts: ${response.statusCode}',
          'code': 'ACTIVE_ALERTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get active price freeze alerts: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get user-specific price freeze alerts
  static Future<Map<String, dynamic>> getUserPriceFreezeAlerts({
    required int userId,
    required String userType, // consumer or retailer
  }) async {
    try {
      print('🔍 AuthService: Getting user price freeze alerts - User ID: $userId, Type: $userType');
      
      if (!['consumer', 'retailer'].contains(userType)) {
        return {
          'status': 'error',
          'message': 'Invalid user type. Must be consumer or retailer',
          'code': 'INVALID_USER_TYPE'
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {
            'action': 'user_alerts',
            'user_id': userId.toString(),
            'user_type': userType,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 User Alerts API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'User alerts retrieved successfully' : 'Failed to retrieve user alerts'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve user alerts: ${response.statusCode}',
          'code': 'USER_ALERTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get user price freeze alerts: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get all price freeze alerts with filters and pagination
  static Future<Map<String, dynamic>> getPriceFreezeAlerts({
    int? productId,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 AuthService: Getting price freeze alerts - Page: $page, Limit: $limit');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (productId != null) 'product_id': productId.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Price Freeze Alerts API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Alerts retrieved successfully' : 'Failed to retrieve alerts'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve alerts: ${response.statusCode}',
          'code': 'ALERTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze alerts: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get single price freeze alert by ID
  static Future<Map<String, dynamic>> getPriceFreezeAlert({required int alertId}) async {
    try {
      print('🔍 AuthService: Getting price freeze alert - ID: $alertId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'id': alertId.toString()},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Price Freeze Alert API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Alert retrieved successfully' : 'Failed to retrieve alert'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Alert not found',
          'code': 'ALERT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve alert: ${response.statusCode}',
          'code': 'ALERT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get price freeze alert: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Create new price freeze alert
  static Future<Map<String, dynamic>> createPriceFreezeAlert({
    required String title,
    required String message,
    required String freezeStartDate,
    String? freezeEndDate,
    dynamic affectedProducts = 'all', // 'all' or List<int>
    dynamic affectedCategories = 'all', // 'all' or List<int>
    dynamic affectedLocations = 'all', // 'all' or List<int>
    int? createdBy,
  }) async {
    try {
      print('📝 AuthService: Creating price freeze alert - Title: $title');
      
      final requestBody = {
        'title': title,
        'message': message,
        'freeze_start_date': freezeStartDate,
        'affected_products': affectedProducts,
        'affected_categories': affectedCategories,
        'affected_locations': affectedLocations,
        if (freezeEndDate != null) 'freeze_end_date': freezeEndDate,
        if (createdBy != null) 'created_by': createdBy,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/price_freeze_management.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Create Price Freeze Alert API Response Status: ${response.statusCode}');
      print('📊 Create Price Freeze Alert API Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Alert created successfully' : 'Failed to create alert'),
          'data': data['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create alert: ${response.statusCode}',
          'code': 'CREATE_ALERT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create price freeze alert: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update price freeze alert
  static Future<Map<String, dynamic>> updatePriceFreezeAlert({
    required int alertId,
    String? title,
    String? message,
    String? freezeStartDate,
    String? freezeEndDate,
    String? status,
    dynamic affectedProducts,
    dynamic affectedCategories,
    dynamic affectedLocations,
  }) async {
    try {
      print('✏️ AuthService: Updating price freeze alert - ID: $alertId');
      
      final requestBody = <String, dynamic>{
        'alert_id': alertId,
        if (title != null) 'title': title,
        if (message != null) 'message': message,
        if (freezeStartDate != null) 'freeze_start_date': freezeStartDate,
        if (freezeEndDate != null) 'freeze_end_date': freezeEndDate,
        if (status != null) 'status': status,
        if (affectedProducts != null) 'affected_products': affectedProducts,
        if (affectedCategories != null) 'affected_categories': affectedCategories,
        if (affectedLocations != null) 'affected_locations': affectedLocations,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/price_freeze_management.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Price Freeze Alert API Response Status: ${response.statusCode}');
      print('📊 Update Price Freeze Alert API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Alert updated successfully' : 'Failed to update alert'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Alert not found',
          'code': 'ALERT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update alert: ${response.statusCode}',
          'code': 'UPDATE_ALERT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update price freeze alert: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update price freeze alert status
  static Future<Map<String, dynamic>> updatePriceFreezeAlertStatus({
    required int alertId,
    required String status, // active, expired, cancelled
  }) async {
    try {
      print('✏️ AuthService: Updating price freeze alert status - ID: $alertId, Status: $status');
      
      if (!['active', 'expired', 'cancelled'].contains(status)) {
        return {
          'status': 'error',
          'message': 'Invalid status. Must be active, expired, or cancelled',
          'code': 'INVALID_STATUS'
        };
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'action': 'update_status'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'alert_id': alertId,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Status updated successfully' : 'Failed to update status'),
          'data': data['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update status: ${response.statusCode}',
          'code': 'UPDATE_STATUS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update price freeze alert status: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Mark price freeze alert as read by user
  static Future<Map<String, dynamic>> markPriceFreezeAlertRead({
    required int alertId,
    required int userId,
    required String userType, // consumer or retailer
  }) async {
    try {
      print('✓ AuthService: Marking price freeze alert as read - Alert ID: $alertId, User ID: $userId');
      
      if (!['consumer', 'retailer'].contains(userType)) {
        return {
          'status': 'error',
          'message': 'Invalid user type. Must be consumer or retailer',
          'code': 'INVALID_USER_TYPE'
        };
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'action': 'mark_read'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({
          'alert_id': alertId,
          'user_id': userId,
          'user_type': userType,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Alert marked as read' : 'Failed to mark as read'),
          'data': data['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to mark as read: ${response.statusCode}',
          'code': 'MARK_READ_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to mark price freeze alert as read: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Delete price freeze alert
  static Future<Map<String, dynamic>> deletePriceFreezeAlert({required int alertId}) async {
    try {
      print('🗑️ AuthService: Deleting price freeze alert - ID: $alertId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/price_freeze_management.php').replace(
          queryParameters: {'id': alertId.toString()},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Delete Price Freeze Alert API Response Status: ${response.statusCode}');
      print('📊 Delete Price Freeze Alert API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Alert deleted successfully' : 'Failed to delete alert'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Alert not found',
          'code': 'ALERT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to delete alert: ${response.statusCode}',
          'code': 'DELETE_ALERT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to delete price freeze alert: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= PRODUCT PRICE MANAGEMENT API =================
  
  /// Get categories for product management
  static Future<Map<String, dynamic>> getProductCategories() async {
    try {
      print('🔍 AuthService: Getting product categories');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: {'action': 'categories'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Categories retrieved successfully' : 'Failed to retrieve categories'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve categories: ${response.statusCode}',
          'code': 'CATEGORIES_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get product categories: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get folder structure for product management
  static Future<Map<String, dynamic>> getProductFolders() async {
    try {
      print('🔍 AuthService: Getting product folders');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: {'action': 'folders'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Folders retrieved successfully' : 'Failed to retrieve folders'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve folders: ${response.statusCode}',
          'code': 'FOLDERS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get product folders: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get all products with advanced filters and pagination
  static Future<Map<String, dynamic>> getProductsWithFilters({
    String? search,
    int? categoryId,
    double? priceMin,
    double? priceMax,
    int? folderId,
    String sortBy = 'product_name',
    String sortOrder = 'ASC',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 AuthService: Getting products with filters - Page: $page, Limit: $limit');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (priceMin != null) 'price_min': priceMin.toString(),
        if (priceMax != null) 'price_max': priceMax.toString(),
        if (folderId != null) 'folder_id': folderId.toString(),
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Products API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Products retrieved successfully' : 'Failed to retrieve products'),
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve products: ${response.statusCode}',
          'code': 'PRODUCTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get single product by ID with full details and SRP history
  static Future<Map<String, dynamic>> getProductById({required int productId}) async {
    try {
      print('🔍 AuthService: Getting product by ID: $productId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: {'id': productId.toString()},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Product Details API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product retrieved successfully' : 'Failed to retrieve product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve product: ${response.statusCode}',
          'code': 'PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Create new product
  static Future<Map<String, dynamic>> createProduct({
    required String productName,
    required String unit,
    required String brand,
    required String manufacturer,
    required double srp,
    int? categoryId,
    double? monitoredPrice,
    double? prevailingPrice,
    String? profilePic,
    int? folderId,
    int? mainFolderId,
    int? subFolderId,
  }) async {
    try {
      print('📝 AuthService: Creating product - Name: $productName');
      
      final requestBody = {
        'product_name': productName,
        'unit': unit,
        'brand': brand,
        'manufacturer': manufacturer,
        'srp': srp,
        if (categoryId != null) 'category_id': categoryId,
        if (monitoredPrice != null) 'monitored_price': monitoredPrice,
        if (prevailingPrice != null) 'prevailing_price': prevailingPrice,
        if (profilePic != null) 'profile_pic': profilePic,
        if (folderId != null) 'folder_id': folderId,
        if (mainFolderId != null) 'main_folder_id': mainFolderId,
        if (subFolderId != null) 'sub_folder_id': subFolderId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_price_management.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Create Product API Response Status: ${response.statusCode}');
      print('📊 Create Product API Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product created successfully' : 'Failed to create product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 409) {
        return {
          'status': 'error',
          'message': 'Product with same name and brand already exists',
          'code': 'DUPLICATE_PRODUCT',
          'http_status': 409
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create product: ${response.statusCode}',
          'code': 'CREATE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Bulk create products
  static Future<Map<String, dynamic>> bulkCreateProducts({
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      print('📝 AuthService: Bulk creating products - Count: ${products.length}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: {'action': 'bulk'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode({'products': products}),
      ).timeout(const Duration(seconds: 60));

      print('📊 Bulk Create Products API Response Status: ${response.statusCode}');
      print('📊 Bulk Create Products API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Bulk upload completed' : 'Failed to bulk create products'),
          'data': data['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to bulk create products: ${response.statusCode}',
          'code': 'BULK_CREATE_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to bulk create products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update product
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? productName,
    String? unit,
    String? brand,
    String? manufacturer,
    int? categoryId,
    double? srp,
    double? monitoredPrice,
    double? prevailingPrice,
    String? profilePic,
    int? folderId,
    int? mainFolderId,
    int? subFolderId,
  }) async {
    try {
      print('✏️ AuthService: Updating product - ID: $productId');
      
      final requestBody = <String, dynamic>{
        'product_id': productId,
        if (productName != null) 'product_name': productName,
        if (unit != null) 'unit': unit,
        if (brand != null) 'brand': brand,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (categoryId != null) 'category_id': categoryId,
        if (srp != null) 'srp': srp,
        if (monitoredPrice != null) 'monitored_price': monitoredPrice,
        if (prevailingPrice != null) 'prevailing_price': prevailingPrice,
        if (profilePic != null) 'profile_pic': profilePic,
        if (folderId != null) 'folder_id': folderId,
        if (mainFolderId != null) 'main_folder_id': mainFolderId,
        if (subFolderId != null) 'sub_folder_id': subFolderId,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/product_price_management.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Product API Response Status: ${response.statusCode}');
      print('📊 Update Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product updated successfully' : 'Failed to update product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update product: ${response.statusCode}',
          'code': 'UPDATE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update product prices only (SRP, monitored, prevailing)
  static Future<Map<String, dynamic>> updateProductPrices({
    required int productId,
    double? srp,
    double? monitoredPrice,
    double? prevailingPrice,
  }) async {
    try {
      print('💰 AuthService: Updating product prices - ID: $productId');
      
      final requestBody = <String, dynamic>{
        'product_id': productId,
        if (srp != null) 'srp': srp,
        if (monitoredPrice != null) 'monitored_price': monitoredPrice,
        if (prevailingPrice != null) 'prevailing_price': prevailingPrice,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: {'action': 'update_price'},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Prices API Response Status: ${response.statusCode}');
      print('📊 Update Prices API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Prices updated successfully' : 'Failed to update prices'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update prices: ${response.statusCode}',
          'code': 'UPDATE_PRICES_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update product prices: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Delete product
  static Future<Map<String, dynamic>> deleteProduct({required int productId}) async {
    try {
      print('🗑️ AuthService: Deleting product - ID: $productId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/product_price_management.php').replace(
          queryParameters: {'id': productId.toString()},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Delete Product API Response Status: ${response.statusCode}');
      print('📊 Delete Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product deleted successfully' : 'Failed to delete product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to delete product: ${response.statusCode}',
          'code': 'DELETE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to delete product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= PRODUCTS API (PDO-BASED) =================
  
  /// Get all products with pagination, search, and filters (includes categories)
  static Future<Map<String, dynamic>> getAllProducts({
    String? search,
    String? category,
    int? categoryId,
    String sortBy = 'product_name',
    String sortOrder = 'ASC',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 AuthService: Getting all products - Page: $page, Limit: $limit');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (categoryId != null) 'category_id': categoryId.toString(),
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/products.php').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Products API Response Status: ${response.statusCode}');
      print('📊 Products API Response Body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Products retrieved successfully' : 'Failed to retrieve products'),
          'data': data['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve products: ${response.statusCode}',
          'code': 'PRODUCTS_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get all products: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Get single product by ID with price history
  static Future<Map<String, dynamic>> getProduct({required int productId}) async {
    try {
      print('🔍 AuthService: Getting product - ID: $productId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/products.php').replace(
          queryParameters: {'id': productId.toString()},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Product API Response Status: ${response.statusCode}');
      print('📊 Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product retrieved successfully' : 'Failed to retrieve product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to retrieve product: ${response.statusCode}',
          'code': 'PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to get product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Create new product (PDO-based API)
  static Future<Map<String, dynamic>> createNewProduct({
    required String productName,
    required String brand,
    required String manufacturer,
    required String unit,
    required double srp,
    int? categoryId,
    double? monitoredPrice,
    double? prevailingPrice,
    String? description,
    String? specifications,
    String? profilePic,
  }) async {
    try {
      print('📝 AuthService: Creating new product - Name: $productName');
      
      final requestBody = {
        'product_name': productName,
        'brand': brand,
        'manufacturer': manufacturer,
        'unit': unit,
        'srp': srp,
        if (categoryId != null) 'category_id': categoryId,
        if (monitoredPrice != null) 'monitored_price': monitoredPrice,
        if (prevailingPrice != null) 'prevailing_price': prevailingPrice,
        if (description != null) 'description': description,
        if (specifications != null) 'specifications': specifications,
        if (profilePic != null) 'profile_pic': profilePic,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Create Product API Response Status: ${response.statusCode}');
      print('📊 Create Product API Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product created successfully' : 'Failed to create product'),
          'data': data['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to create product: ${response.statusCode}',
          'code': 'CREATE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to create product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Update product (PDO-based API)
  static Future<Map<String, dynamic>> updateProductDetails({
    required int productId,
    String? productName,
    String? brand,
    String? manufacturer,
    String? unit,
    double? srp,
    double? monitoredPrice,
    double? prevailingPrice,
    int? categoryId,
    String? description,
    String? specifications,
    String? profilePic,
  }) async {
    try {
      print('✏️ AuthService: Updating product details - ID: $productId');
      
      final requestBody = <String, dynamic>{
        'product_id': productId,
        if (productName != null) 'product_name': productName,
        if (brand != null) 'brand': brand,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (unit != null) 'unit': unit,
        if (srp != null) 'srp': srp,
        if (monitoredPrice != null) 'monitored_price': monitoredPrice,
        if (prevailingPrice != null) 'prevailing_price': prevailingPrice,
        if (categoryId != null) 'category_id': categoryId,
        if (description != null) 'description': description,
        if (specifications != null) 'specifications': specifications,
        if (profilePic != null) 'profile_pic': profilePic,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/products.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Update Product API Response Status: ${response.statusCode}');
      print('📊 Update Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product updated successfully' : 'Failed to update product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to update product: ${response.statusCode}',
          'code': 'UPDATE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to update product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  /// Delete product (PDO-based API)
  static Future<Map<String, dynamic>> removeProduct({required int productId}) async {
    try {
      print('🗑️ AuthService: Removing product - ID: $productId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products.php').replace(
          queryParameters: {'id': productId.toString()},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(const Duration(seconds: 30));

      print('📊 Delete Product API Response Status: ${response.statusCode}');
      print('📊 Delete Product API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['success'] == true ? 'success' : 'error',
          'message': data['message'] ?? (data['success'] == true ? 'Product deleted successfully' : 'Failed to delete product'),
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'message': 'Product not found',
          'code': 'PRODUCT_NOT_FOUND',
          'http_status': 404
        };
      } else if (response.statusCode == 409) {
        return {
          'status': 'error',
          'message': 'Cannot delete product. It is being used in retail prices.',
          'code': 'PRODUCT_IN_USE',
          'http_status': 409
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to delete product: ${response.statusCode}',
          'code': 'DELETE_PRODUCT_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ AuthService: Failed to remove product: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // ================= ADMIN DASHBOARD INTEGRATION =================
  
  // Get comprehensive admin dashboard data
  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      print('🔍 AuthService: Getting comprehensive admin dashboard data');
      
      // Get all dashboard data in parallel
      final results = await Future.wait([
        AuthService.getStats(),
        AuthService.getAdminUsers(limit: 5),
        AuthService.getConsumers(limit: 5),
        AuthService.getRetailers(limit: 5),
        AuthService.getComplaints(limit: 5),
        getProducts(limit: 5),
        getNotifications(limit: 5),
      ]);

      // Process results
      final Map<String, dynamic> dashboardData = {
        'overview': {},
        'recent_activities': [],
        'statistics': {},
        'users': {},
        'complaints': {},
        'products': {},
        'notifications': {},
      };

      // Process statistics
      if (results[0]['status'] == 'success') {
        dashboardData['statistics'] = results[0]['data'];
      }

      // Process admin users
      if (results[1]['status'] == 'success') {
        dashboardData['users']['admin_users'] = results[1]['data'];
      }

      // Process consumers
      if (results[2]['status'] == 'success') {
        dashboardData['users']['consumers'] = results[2]['data'];
      }

      // Process retailers
      if (results[3]['status'] == 'success') {
        dashboardData['users']['retailers'] = results[3]['data'];
      }

      // Process complaints
      if (results[4]['status'] == 'success') {
        dashboardData['complaints'] = results[4]['data'];
      }

      // Process products
      if (results[5]['status'] == 'success') {
        dashboardData['products'] = results[5]['data'];
      }

      // Process notifications
      if (results[6]['status'] == 'success') {
        dashboardData['notifications'] = results[6]['data'];
      }

      return {
        'status': 'success',
        'message': 'Admin dashboard data retrieved successfully',
        'data': dashboardData,
      };
    } catch (e) {
      print('❌ AuthService: Failed to get admin dashboard data: $e');
      return {
        'status': 'error',
        'message': 'Failed to get admin dashboard data: $e',
        'code': 'DASHBOARD_ERROR'
      };
    }
  }

  // Load admin dashboard data using the new admin_dashboard.php API
  // Includes automatic retry logic for connection errors
  static Future<Map<String, dynamic>> loadAdminDashboard({String? adminId, int retryCount = 0}) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    
    try {
      print('🔍 AuthService: Loading admin dashboard data (attempt ${retryCount + 1}/${maxRetries + 1})');
      
      // Build URL with optional admin_id parameter
      String url = '$baseUrl/admin/admin_dashboard.php';
      if (adminId != null) {
        url += '?admin_id=$adminId';
      }
      
      print('📊 Admin Dashboard URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
          if (getSessionCookie() != null) 'Cookie': getSessionCookie()!,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout after 30 seconds');
        },
      );

      print('📊 Admin Dashboard API Response Status: ${response.statusCode}');
      print('📊 Admin Dashboard API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Admin dashboard data retrieved successfully',
          'data': data['data'], // This contains the dashboard data structure from PHP
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
          'http_status': response.statusCode
        };
      }
    } on TimeoutException catch (e) {
      print('❌ AuthService: Timeout loading admin dashboard data: $e');
      
      // Retry on timeout if attempts remaining
      if (retryCount < maxRetries) {
        print('🔄 Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return loadAdminDashboard(adminId: adminId, retryCount: retryCount + 1);
      }
      
      return {
        'success': false,
        'message': 'Connection timeout. Please check your internet connection and try again.',
        'error': 'CONNECTION_TIMEOUT'
      };
    } on SocketException catch (e) {
      print('❌ AuthService: Socket error loading admin dashboard data: $e');
      
      // Retry on socket errors if attempts remaining
      if (retryCount < maxRetries) {
        print('🔄 Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return loadAdminDashboard(adminId: adminId, retryCount: retryCount + 1);
      }
      
      // Provide user-friendly error message
      String errorMessage = 'Unable to connect to server. ';
      if (e.message.contains('Connection reset')) {
        errorMessage += 'The connection was reset. Please check your internet connection and try again.';
      } else if (e.message.contains('Failed host lookup')) {
        errorMessage += 'Cannot reach server. Please check your internet connection.';
      } else if (e.message.contains('Network is unreachable')) {
        errorMessage += 'Network is unreachable. Please check your internet connection.';
      } else {
        errorMessage += 'Please check your internet connection and try again.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': 'CONNECTION_FAILED',
        'socket_error': e.message,
      };
    } on HttpException catch (e) {
      print('❌ AuthService: HTTP error loading admin dashboard data: $e');
      return {
        'success': false,
        'message': 'Server communication error. Please try again.',
        'error': 'HTTP_EXCEPTION',
      };
    } catch (e) {
      print('❌ AuthService: Failed to load admin dashboard data: $e');
      
      // Retry on other errors if attempts remaining
      if (retryCount < maxRetries && e.toString().contains('Connection')) {
        print('🔄 Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return loadAdminDashboard(adminId: adminId, retryCount: retryCount + 1);
      }
      
      // Provide user-friendly error message
      String errorMessage = 'Connection error occurred. ';
      if (e.toString().contains('Connection reset')) {
        errorMessage += 'The connection was reset by the server. Please try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Request timed out. Please check your internet connection.';
      } else {
        errorMessage += 'Please check your internet connection and try again.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': 'CONNECTION_FAILED'
      };
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

// ================= CONSUMER DASHBOARD API METHODS =================
class ConsumerDashboardAPI {
  static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";

  // Load consumer dashboard data with consumer_id parameter
  static Future<Map<String, dynamic>> loadDashboardData({String? consumerId}) async {
    try {
      print('🔄 ConsumerDashboardAPI: Loading dashboard data...');
      
      // Get consumer ID from parameter or current user
      String? finalConsumerId = consumerId;
      if (finalConsumerId == null) {
        final currentUser = await AuthService.getCurrentUser();
        finalConsumerId = currentUser?['id']?.toString();
      }
      
      if (finalConsumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID is required. Please login first.',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      print('📋 ConsumerDashboardAPI: Using consumer ID: $finalConsumerId');
      
      // Use POST method with consumer_id in JSON body as per PHP API
      final requestBody = {
        'consumer_id': finalConsumerId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/consumer_dashboard.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Consumer Dashboard API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle API response structure
        if (data['status'] == 'success') {
        return {
          'status': 'success',
            'message': data['message'] ?? 'Consumer dashboard data loaded successfully',
            'data': data['data'],
            'code': data['code'] ?? 'CONSUMER_DASHBOARD_SUCCESS'
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to load consumer dashboard',
            'code': data['code'] ?? 'CONSUMER_DASHBOARD_ERROR'
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ ConsumerDashboardAPI: Failed to load dashboard data: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Load consumer notifications
  static Future<Map<String, dynamic>> loadNotifications({String? consumerId}) async {
    try {
      print('🔄 ConsumerDashboardAPI: Loading notifications...');
      
      // Get consumer ID from parameter or current user
      String? finalConsumerId = consumerId;
      if (finalConsumerId == null) {
        final currentUser = await AuthService.getCurrentUser();
        finalConsumerId = currentUser?['id']?.toString();
      }
      
      if (finalConsumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID is required. Please login first.',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      // Use GET method with consumer_id as query parameter
      final response = await http.get(
        Uri.parse('$baseUrl/consumer/notifications.php?user_id=$finalConsumerId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ ConsumerDashboardAPI: Failed to load notifications: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Load consumer price updates
  static Future<Map<String, dynamic>> loadPriceUpdates({String? consumerId}) async {
    try {
      print('🔄 ConsumerDashboardAPI: Loading price updates...');
      
      // Get consumer ID from parameter or current user
      String? finalConsumerId = consumerId;
      if (finalConsumerId == null) {
        final currentUser = await AuthService.getCurrentUser();
        finalConsumerId = currentUser?['id']?.toString();
      }
      
      if (finalConsumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID is required. Please login first.',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      // Use GET method with consumer_id as query parameter
      final response = await http.get(
        Uri.parse('$baseUrl/consumer/price-updates.php?consumer_id=$finalConsumerId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ ConsumerDashboardAPI: Failed to load price updates: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Perform consumer action
  static Future<Map<String, dynamic>> performAction(String action, {String? consumerId, Map<String, dynamic>? params}) async {
    try {
      print('🔄 ConsumerDashboardAPI: Performing action: $action');
      
      // Get consumer ID from parameter or current user
      String? finalConsumerId = consumerId;
      if (finalConsumerId == null) {
        final currentUser = await AuthService.getCurrentUser();
        finalConsumerId = currentUser?['id']?.toString();
      }
      
      if (finalConsumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID is required. Please login first.',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      final Map<String, dynamic> requestBody = {
        'action': action,
        'consumer_id': finalConsumerId,
      };
      if (params != null) {
        requestBody.addAll(params);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/consumer_dashboard.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'data': data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'HTTP_ERROR'
        };
      }
    } catch (e) {
      print('❌ ConsumerDashboardAPI: Failed to perform action: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Get sample price updates for demo
  static List<Map<String, dynamic>> getSamplePriceUpdates() {
    return [
      {
        'product': 'Milk (1L)',
        'previous_price': 85.00,
        'current_price': 82.00,
        'change_percent': -3.5,
      },
      {
        'product': 'Bread (500g)',
        'previous_price': 45.00,
        'current_price': 48.00,
        'change_percent': 6.7,
      },
      {
        'product': 'Rice (1kg)',
        'previous_price': 55.00,
        'current_price': 55.00,
        'change_percent': 0.0,
      },
    ];
  }

  // Get consumer dashboard data with proper structure matching PHP API
  static Future<Map<String, dynamic>> getConsumerDashboardData({String? consumerId}) async {
    try {
      print('🔄 ConsumerDashboardAPI: Getting consumer dashboard data...');
      
      // Get consumer ID from parameter or current user
      String? finalConsumerId = consumerId;
      if (finalConsumerId == null) {
        final currentUser = await AuthService.getCurrentUser();
        finalConsumerId = currentUser?['id']?.toString();
      }
      
      if (finalConsumerId == null) {
        return {
          'status': 'error',
          'message': 'Consumer ID is required. Please login first.',
          'code': 'MISSING_CONSUMER_ID'
        };
      }
      
      // Use POST method with consumer_id in JSON body as per PHP API
      final requestBody = {
        'consumer_id': finalConsumerId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/consumer_dashboard.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📊 Consumer Dashboard API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle API response structure matching PHP API
        if (data['status'] == 'success') {
          return {
            'status': 'success',
            'message': data['message'] ?? 'Consumer dashboard data retrieved successfully',
            'code': data['code'] ?? 'CONSUMER_DASHBOARD_SUCCESS',
            'data': data['data'], // This contains the dashboard data structure from PHP
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to retrieve consumer dashboard data',
            'code': data['code'] ?? 'CONSUMER_DASHBOARD_ERROR',
            'debug': data['debug'] // Include debug info if available
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
          'code': 'HTTP_ERROR',
          'http_status': response.statusCode
        };
      }
    } catch (e) {
      print('❌ ConsumerDashboardAPI: Failed to get consumer dashboard data: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
        'code': 'CONNECTION_FAILED'
      };
    }
  }

  // Get consumer statistics (products monitored, active retailers, etc.)
  static Future<Map<String, dynamic>> getConsumerStatistics({String? consumerId}) async {
    try {
      final dashboardData = await getConsumerDashboardData(consumerId: consumerId);
      
      if (dashboardData['status'] == 'success' && dashboardData['data'] != null) {
        final data = dashboardData['data'];
        return {
          'status': 'success',
          'statistics': data['statistics'] ?? {},
          'consumer': data['consumer'] ?? {},
          'recent_price_updates': data['recent_price_updates'] ?? [],
          'notifications': data['notifications'] ?? [],
        };
      } else {
        return dashboardData;
      }
    } catch (e) {
      print('❌ ConsumerDashboardAPI: Failed to get consumer statistics: $e');
      return {
        'status': 'error',
        'message': 'Failed to get consumer statistics: $e',
        'code': 'STATISTICS_ERROR'
      };
    }
  }
}
