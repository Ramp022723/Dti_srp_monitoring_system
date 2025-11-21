import 'dart:convert';
import 'package:http/http.dart' as http;

/// Quick Registration Test
/// 
/// Simple test functions you can call immediately to debug registration issues
class QuickRegistrationTest {
  static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";
  static const String registerEndpoint = "register.php";

  /// Quick test to see if the API is working
  static Future<void> testApiQuick() async {
    print('🚀 QuickRegistrationTest: Testing API...');
    
    try {
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      // Test with minimal consumer data
      final testData = {
        'user_type': 'consumer',
        'username': 'quick_test_${DateTime.now().millisecondsSinceEpoch}',
        'password': 'password123',
        'confirm_password': 'password123',
        'email': 'quicktest${DateTime.now().millisecondsSinceEpoch}@example.com',
        'first_name': 'Quick',
        'last_name': 'Test',
        'middle_name': '',
        'gender': 'other',
        'birthdate': '1990-01-01',
        'age': '25',
        'location_id': '1',
      };

      print('📤 Sending request to: $url');
      print('📤 Request data: ${jsonEncode(testData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 30));

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Headers: ${response.headers}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ JSON Parsed Successfully: $data');
          
          if (data['status'] == 'success') {
            print('🎉 REGISTRATION SUCCESSFUL!');
            print('User ID: ${data['data']?['user']?['id']}');
            print('Username: ${data['data']?['user']?['username']}');
          } else {
            print('❌ Registration failed: ${data['message']}');
            print('Error code: ${data['code']}');
          }
        } catch (e) {
          print('❌ Failed to parse JSON: $e');
          print('Raw response: ${response.body}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  /// Test retailer registration
  static Future<void> testRetailerQuick() async {
    print('🚀 QuickRegistrationTest: Testing Retailer Registration...');
    
    try {
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      // Test with retailer data
      final testData = {
        'user_type': 'retailer',
        'username': 'quick_retailer_${DateTime.now().millisecondsSinceEpoch}',
        'password': 'RetailPass123!',
        'confirm_password': 'RetailPass123!',
        'registration_code': '123456', // You may need to change this to a valid code
      };

      print('📤 Sending request to: $url');
      print('📤 Request data: ${jsonEncode(testData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 30));

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Headers: ${response.headers}');
      print('📊 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ JSON Parsed Successfully: $data');
          
          if (data['status'] == 'success') {
            print('🎉 RETAILER REGISTRATION SUCCESSFUL!');
            print('User ID: ${data['data']?['user']?['id']}');
            print('Username: ${data['data']?['user']?['username']}');
          } else {
            print('❌ Registration failed: ${data['message']}');
            print('Error code: ${data['code']}');
          }
        } catch (e) {
          print('❌ Failed to parse JSON: $e');
          print('Raw response: ${response.body}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  /// Test API connectivity only
  static Future<void> testConnectivityOnly() async {
    print('🚀 QuickRegistrationTest: Testing API Connectivity...');
    
    try {
      final url = Uri.parse('$baseUrl/$registerEndpoint');
      
      // Test with OPTIONS request first
      print('📤 Testing OPTIONS request...');
      final optionsResponse = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'login_app/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 OPTIONS Status: ${optionsResponse.statusCode}');
      print('📊 OPTIONS Headers: ${optionsResponse.headers}');

      if (optionsResponse.statusCode == 200) {
        print('✅ API is reachable!');
      } else {
        print('❌ API may not be reachable. Status: ${optionsResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Connectivity test failed: $e');
      print('This usually means:');
      print('1. Server is down');
      print('2. Wrong URL');
      print('3. Network issues');
      print('4. CORS problems');
    }
  }

  /// Run all quick tests
  static Future<void> runAllQuickTests() async {
    print('🚀 QuickRegistrationTest: Running All Quick Tests...\n');
    
    print('=== TEST 1: API Connectivity ===');
    await testConnectivityOnly();
    
    print('\n=== TEST 2: Consumer Registration ===');
    await testApiQuick();
    
    print('\n=== TEST 3: Retailer Registration ===');
    await testRetailerQuick();
    
    print('\n🏁 All quick tests completed!');
  }
}
