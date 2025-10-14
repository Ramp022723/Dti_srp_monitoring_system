import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  
  AuthProvider(this._prefs) {
    _loadAuthData();
  }
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  User? _currentUser;
  String? _authToken;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  
  // Load authentication data from storage
  Future<void> _loadAuthData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _authToken = _prefs.getString(AppConstants.tokenKey);
      final userDataString = _prefs.getString(AppConstants.userDataKey);
      
      if (_authToken != null && userDataString != null) {
        final userData = json.decode(userDataString);
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error loading auth data: $e');
      await _clearAuthData();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _authToken = data['token'] ?? 'session_token';
          _currentUser = User.fromJson(data['user']);
          _isAuthenticated = true;
          
          // Save to storage
          await _prefs.setString(AppConstants.tokenKey, _authToken!);
          await _prefs.setString(AppConstants.userDataKey, json.encode(_currentUser!.toJson()));
          
          notifyListeners();
          return {'success': true, 'message': 'Login successful'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Login failed'};
        }
      } else {
        return {'success': false, 'message': 'Server error occurred'};
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Call logout endpoint if needed
      if (_authToken != null) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/logout.php'),
          headers: {
            'Authorization': 'Bearer $_authToken',
          },
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _clearAuthData();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear authentication data
  Future<void> _clearAuthData() async {
    _authToken = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.userDataKey);
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    if (!_isAuthenticated || _authToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.userManagementEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(userData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _currentUser = User.fromJson(data['data']);
          
          // Update stored user data
          await _prefs.setString(AppConstants.userDataKey, json.encode(_currentUser!.toJson()));
          
          notifyListeners();
          return {'success': true, 'message': 'Profile updated successfully'};
        } else {
          return {'success': false, 'message': data['error'] ?? 'Update failed'};
        }
      } else {
        return {'success': false, 'message': 'Server error occurred'};
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check if user has permission
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    // Define permissions based on user type
    switch (_currentUser!.adminType) {
      case 'admin':
        return true; // Admin has all permissions
      case 'barangay_admin':
        return ['view_consumers', 'view_retailers', 'view_products'].contains(permission);
      default:
        return false;
    }
  }
  
  // Get user display name
  String get userDisplayName {
    if (_currentUser == null) return 'Admin';
    return '${_currentUser!.firstName} ${_currentUser!.lastName}';
  }
  
  // Get user initials
  String get userInitials {
    if (_currentUser == null) return 'A';
    return '${_currentUser!.firstName.isNotEmpty ? _currentUser!.firstName[0] : ''}${_currentUser!.lastName.isNotEmpty ? _currentUser!.lastName[0] : ''}'.toUpperCase();
  }
}
