import 'dart:convert';
import 'package:http/http.dart' as http;

/// Registration Debug Service
/// 
/// This service helps debug registration issues by providing detailed
/// logging and testing capabilities for the register.php API.
class RegistrationDebugService {
  static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";
  static const String registerEndpoint = "register.php";

  /// Test API connectivity and endpoint availability
  static Future<Map<String, dynamic>> testApiConnectivity() async {
    try {
      print('🔍 RegistrationDebugService: Testing API connectivity...');
      
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      // Test with GET request first
      final optionsResponse = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 OPTIONS Response Status: ${optionsResponse.statusCode}');
      print('📊 OPTIONS Response Headers: ${optionsResponse.headers}');

      // Test with a simple POST request
      final testData = {
        'user_type': 'consumer',
        'username': 'test_connectivity',
        'password': 'test123',
        'confirm_password': 'test123',
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'User',
        'middle_name': '',
        'gender': 'other',
        'birthdate': '1990-01-01',
        'age': '25',
        'location_id': '1',
      };

      final postResponse = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 30));

      print('📊 POST Response Status: ${postResponse.statusCode}');
      print('📊 POST Response Headers: ${postResponse.headers}');
      print('📊 POST Response Body: ${postResponse.body}');

      return {
        'status': 'success',
        'message': 'API connectivity test completed',
        'options_status': optionsResponse.statusCode,
        'post_status': postResponse.statusCode,
        'post_response': postResponse.body,
        'url': url.toString(),
      };
    } catch (e) {
      print('❌ RegistrationDebugService: Connectivity test failed: $e');
      return {
        'status': 'error',
        'message': 'Connectivity test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test consumer registration with detailed logging
  static Future<Map<String, dynamic>> testConsumerRegistration({
    String? customUsername,
    String? customEmail,
  }) async {
    try {
      print('🧪 RegistrationDebugService: Testing consumer registration...');
      
      final username = customUsername ?? 'test_consumer_${DateTime.now().millisecondsSinceEpoch}';
      final email = customEmail ?? 'test_consumer_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      final requestData = {
        'user_type': 'consumer',
        'username': username,
        'password': 'password123',
        'confirm_password': 'password123',
        'email': email,
        'first_name': 'Test',
        'last_name': 'Consumer',
        'middle_name': 'Debug',
        'gender': 'other',
        'birthdate': '1990-01-01',
        'age': '25',
        'location_id': '1',
        'phone': '+1234567890',
        'bio': 'Test consumer for debugging',
      };

      print('📤 RegistrationDebugService: Request URL: $url');
      print('📤 RegistrationDebugService: Request Headers: Content-Type: application/json, Accept: application/json, User-Agent: login_app/1.0');
      print('📤 RegistrationDebugService: Request Body: ${jsonEncode(requestData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('📊 RegistrationDebugService: Response Status: ${response.statusCode}');
      print('📊 RegistrationDebugService: Response Headers: ${response.headers}');
      print('📊 RegistrationDebugService: Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body);
        print('📊 RegistrationDebugService: Parsed Response: $responseData');
      } catch (e) {
        print('❌ RegistrationDebugService: Failed to parse JSON: $e');
        print('❌ RegistrationDebugService: Raw response: ${response.body}');
      }

      return {
        'status': response.statusCode == 200 ? 'success' : 'error',
        'message': 'Consumer registration test completed',
        'request_url': url.toString(),
        'request_data': requestData,
        'response_status': response.statusCode,
        'response_headers': response.headers,
        'response_body': response.body,
        'parsed_response': responseData,
        'is_success': response.statusCode == 200 && (responseData?['status'] == 'success'),
      };
    } catch (e) {
      print('❌ RegistrationDebugService: Consumer registration test failed: $e');
      return {
        'status': 'error',
        'message': 'Consumer registration test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test retailer registration with detailed logging
  static Future<Map<String, dynamic>> testRetailerRegistration({
    String? customUsername,
    String? customRegistrationCode,
  }) async {
    try {
      print('🧪 RegistrationDebugService: Testing retailer registration...');
      
      final username = customUsername ?? 'test_retailer_${DateTime.now().millisecondsSinceEpoch}';
      final registrationCode = customRegistrationCode ?? '123456';
      
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      final requestData = {
        'user_type': 'retailer',
        'username': username,
        'password': 'RetailPass123!',
        'confirm_password': 'RetailPass123!',
        'registration_code': registrationCode,
      };

      print('📤 RegistrationDebugService: Request URL: $url');
      print('📤 RegistrationDebugService: Request Headers: Content-Type: application/json, Accept: application/json, User-Agent: login_app/1.0');
      print('📤 RegistrationDebugService: Request Body: ${jsonEncode(requestData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('📊 RegistrationDebugService: Response Status: ${response.statusCode}');
      print('📊 RegistrationDebugService: Response Headers: ${response.headers}');
      print('📊 RegistrationDebugService: Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body);
        print('📊 RegistrationDebugService: Parsed Response: $responseData');
      } catch (e) {
        print('❌ RegistrationDebugService: Failed to parse JSON: $e');
        print('❌ RegistrationDebugService: Raw response: ${response.body}');
      }

      return {
        'status': response.statusCode == 200 ? 'success' : 'error',
        'message': 'Retailer registration test completed',
        'request_url': url.toString(),
        'request_data': requestData,
        'response_status': response.statusCode,
        'response_headers': response.headers,
        'response_body': response.body,
        'parsed_response': responseData,
        'is_success': response.statusCode == 200 && (responseData?['status'] == 'success'),
      };
    } catch (e) {
      print('❌ RegistrationDebugService: Retailer registration test failed: $e');
      return {
        'status': 'error',
        'message': 'Retailer registration test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Run comprehensive registration tests
  static Future<Map<String, dynamic>> runComprehensiveTests() async {
    print('🚀 RegistrationDebugService: Running comprehensive registration tests...');
    
    final results = <String, dynamic>{};
    
    // Test 1: API Connectivity
    print('\n=== TEST 1: API Connectivity ===');
    results['connectivity'] = await testApiConnectivity();
    
    // Test 2: Consumer Registration
    print('\n=== TEST 2: Consumer Registration ===');
    results['consumer_test'] = await testConsumerRegistration();
    
    // Test 3: Retailer Registration
    print('\n=== TEST 3: Retailer Registration ===');
    results['retailer_test'] = await testRetailerRegistration();
    
    // Test 4: Invalid Consumer Data
    print('\n=== TEST 4: Invalid Consumer Data ===');
    results['invalid_consumer_test'] = await testInvalidConsumerRegistration();
    
    // Test 5: Invalid Retailer Data
    print('\n=== TEST 5: Invalid Retailer Data ===');
    results['invalid_retailer_test'] = await testInvalidRetailerRegistration();
    
    // Summary
    final summary = _generateTestSummary(results);
    results['summary'] = summary;
    
    print('\n=== TEST SUMMARY ===');
    print('Connectivity: ${summary['connectivity_status']}');
    print('Consumer Registration: ${summary['consumer_status']}');
    print('Retailer Registration: ${summary['retailer_status']}');
    print('Invalid Consumer Test: ${summary['invalid_consumer_status']}');
    print('Invalid Retailer Test: ${summary['invalid_retailer_status']}');
    
    return results;
  }

  /// Test invalid consumer registration data
  static Future<Map<String, dynamic>> testInvalidConsumerRegistration() async {
    try {
      print('🧪 RegistrationDebugService: Testing invalid consumer registration...');
      
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      final requestData = {
        'user_type': 'consumer',
        'username': '', // Invalid: empty username
        'password': 'weak', // Invalid: weak password
        'confirm_password': 'different', // Invalid: password mismatch
        'email': 'invalid-email', // Invalid: bad email format
        'first_name': '', // Invalid: empty first name
        'last_name': '', // Invalid: empty last name
        'gender': 'invalid', // Invalid: invalid gender
        'birthdate': 'invalid-date', // Invalid: bad date format
        'age': '5', // Invalid: too young
        'location_id': '999999', // Invalid: non-existent location
      };

      print('📤 RegistrationDebugService: Request Body: ${jsonEncode(requestData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('📊 RegistrationDebugService: Response Status: ${response.statusCode}');
      print('📊 RegistrationDebugService: Response Body: ${response.body}');

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ RegistrationDebugService: Failed to parse JSON: $e');
      }

      return {
        'status': 'success',
        'message': 'Invalid consumer registration test completed',
        'response_status': response.statusCode,
        'response_body': response.body,
        'parsed_response': responseData,
        'expected_error': true,
        'got_error': response.statusCode != 200 || (responseData?['status'] == 'error'),
      };
    } catch (e) {
      print('❌ RegistrationDebugService: Invalid consumer test failed: $e');
      return {
        'status': 'error',
        'message': 'Invalid consumer test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test invalid retailer registration data
  static Future<Map<String, dynamic>> testInvalidRetailerRegistration() async {
    try {
      print('🧪 RegistrationDebugService: Testing invalid retailer registration...');
      
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      final requestData = {
        'user_type': 'retailer',
        'username': '', // Invalid: empty username
        'password': 'weak', // Invalid: weak password
        'confirm_password': 'different', // Invalid: password mismatch
        'registration_code': '123', // Invalid: wrong format (not 6 digits)
      };

      print('📤 RegistrationDebugService: Request Body: ${jsonEncode(requestData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('📊 RegistrationDebugService: Response Status: ${response.statusCode}');
      print('📊 RegistrationDebugService: Response Body: ${response.body}');

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ RegistrationDebugService: Failed to parse JSON: $e');
      }

      return {
        'status': 'success',
        'message': 'Invalid retailer registration test completed',
        'response_status': response.statusCode,
        'response_body': response.body,
        'parsed_response': responseData,
        'expected_error': true,
        'got_error': response.statusCode != 200 || (responseData?['status'] == 'error'),
      };
    } catch (e) {
      print('❌ RegistrationDebugService: Invalid retailer test failed: $e');
      return {
        'status': 'error',
        'message': 'Invalid retailer test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Generate test summary
  static Map<String, dynamic> _generateTestSummary(Map<String, dynamic> results) {
    return {
      'connectivity_status': results['connectivity']?['status'] == 'success' ? 'PASS' : 'FAIL',
      'consumer_status': results['consumer_test']?['is_success'] == true ? 'PASS' : 'FAIL',
      'retailer_status': results['retailer_test']?['is_success'] == true ? 'PASS' : 'FAIL',
      'invalid_consumer_status': results['invalid_consumer_test']?['got_error'] == true ? 'PASS' : 'FAIL',
      'invalid_retailer_status': results['invalid_retailer_test']?['got_error'] == true ? 'PASS' : 'FAIL',
      'total_tests': 5,
      'passed_tests': [
        results['connectivity']?['status'] == 'success',
        results['consumer_test']?['is_success'] == true,
        results['retailer_test']?['is_success'] == true,
        results['invalid_consumer_test']?['got_error'] == true,
        results['invalid_retailer_test']?['got_error'] == true,
      ].where((passed) => passed).length,
    };
  }
}
