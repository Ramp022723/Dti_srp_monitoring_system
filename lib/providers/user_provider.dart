import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_model.dart';
import '../utils/constants.dart';

class UserProvider with ChangeNotifier {
  bool _isLoading = false;
  List<User> _users = [];
  List<User> _consumers = [];
  String? _error;
  
  // Getters
  bool get isLoading => _isLoading;
  List<User> get users => _users;
  List<User> get consumers => _consumers;
  String? get error => _error;
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Fetch all admin users
  Future<void> fetchUsers({String? authToken}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.userManagementEndpoint}'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final usersList = data['data']['users'] as List;
          _users = usersList.map((userJson) => User.fromJson(userJson)).toList();
        } else {
          _setError(data['error'] ?? 'Failed to fetch users');
        }
      } else {
        _setError('Server error occurred');
      }
    } catch (e) {
      debugPrint('Fetch users error: $e');
      _setError('Network error occurred');
    } finally {
      _setLoading(false);
    }
  }
  
  // Fetch specific user
  Future<User?> fetchUser(int userId, {String? authToken}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.userManagementEndpoint}?id=$userId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        } else {
          _setError(data['error'] ?? 'Failed to fetch user');
          return null;
        }
      } else {
        _setError('Server error occurred');
        return null;
      }
    } catch (e) {
      debugPrint('Fetch user error: $e');
      _setError('Network error occurred');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Create new user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData, {String? authToken}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.userManagementEndpoint}'),
        headers: headers,
        body: json.encode(userData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Add new user to the list
          final newUser = User.fromJson(data['data']);
          _users.add(newUser);
          notifyListeners();
          
          return {'success': true, 'message': 'User created successfully', 'data': newUser};
        } else {
          return {'success': false, 'message': data['error'] ?? 'Failed to create user'};
        }
      } else {
        return {'success': false, 'message': 'Server error occurred'};
      }
    } catch (e) {
      debugPrint('Create user error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData, {String? authToken}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.userManagementEndpoint}'),
        headers: headers,
        body: json.encode(userData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Update user in the list
          final updatedUser = User.fromJson(data['data']);
          final index = _users.indexWhere((user) => user.id == updatedUser.id);
          if (index != -1) {
            _users[index] = updatedUser;
            notifyListeners();
          }
          
          return {'success': true, 'message': 'User updated successfully', 'data': updatedUser};
        } else {
          return {'success': false, 'message': data['error'] ?? 'Failed to update user'};
        }
      } else {
        return {'success': false, 'message': 'Server error occurred'};
      }
    } catch (e) {
      debugPrint('Update user error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete user
  Future<Map<String, dynamic>> deleteUser(int userId, {String? authToken}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.userManagementEndpoint}?id=$userId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Remove user from the list
          _users.removeWhere((user) => user.id == userId);
          notifyListeners();
          
          return {'success': true, 'message': 'User deleted successfully'};
        } else {
          return {'success': false, 'message': data['error'] ?? 'Failed to delete user'};
        }
      } else {
        return {'success': false, 'message': 'Server error occurred'};
      }
    } catch (e) {
      debugPrint('Delete user error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    } finally {
      _setLoading(false);
    }
  }
  
  // Fetch consumers
  Future<void> fetchConsumers({String? authToken}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.consumerManagementEndpoint}'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        // Parse the HTML response to extract consumer data
        // This is a simplified approach - in a real app, you'd have a proper API endpoint
        final htmlContent = response.body;
        
        // For now, we'll create mock data
        _consumers = _generateMockConsumers();
      } else {
        _setError('Server error occurred');
      }
    } catch (e) {
      debugPrint('Fetch consumers error: $e');
      _setError('Network error occurred');
    } finally {
      _setLoading(false);
    }
  }
  
  // Generate mock consumers data (replace with actual API call)
  List<User> _generateMockConsumers() {
    return [
      User(
        id: 1,
        username: 'john_doe',
        firstName: 'John',
        lastName: 'Doe',
        middleName: 'M',
        email: 'john.doe@email.com',
        adminType: 'consumer',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: 2,
        username: 'jane_smith',
        firstName: 'Jane',
        lastName: 'Smith',
        middleName: 'A',
        email: 'jane.smith@email.com',
        adminType: 'consumer',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      User(
        id: 3,
        username: 'mike_wilson',
        firstName: 'Mike',
        lastName: 'Wilson',
        middleName: 'B',
        email: 'mike.wilson@email.com',
        adminType: 'consumer',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
  
  // Search users
  List<User> searchUsers(String query) {
    if (query.isEmpty) return _users;
    
    return _users.where((user) {
      return user.username.toLowerCase().contains(query.toLowerCase()) ||
             user.firstName.toLowerCase().contains(query.toLowerCase()) ||
             user.lastName.toLowerCase().contains(query.toLowerCase()) ||
             user.email?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }
  
  // Search consumers
  List<User> searchConsumers(String query) {
    if (query.isEmpty) return _consumers;
    
    return _consumers.where((consumer) {
      return consumer.username.toLowerCase().contains(query.toLowerCase()) ||
             consumer.firstName.toLowerCase().contains(query.toLowerCase()) ||
             consumer.lastName.toLowerCase().contains(query.toLowerCase()) ||
             consumer.email?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }
}
