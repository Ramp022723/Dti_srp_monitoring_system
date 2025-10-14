import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'dart:async';

class RetailerProfilePage extends StatefulWidget {
  const RetailerProfilePage({Key? key}) : super(key: key);

  @override
  State<RetailerProfilePage> createState() => _RetailerProfilePageState();
}

class _RetailerProfilePageState extends State<RetailerProfilePage> {
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _monitoringData = {};
  bool _isLoading = true;
  String? _error;
  
  // Form controllers
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Form validation
  bool _isUsernameFormValid = false;
  bool _isPasswordFormValid = false;
  
  // File picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _lastProfilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    
    // Set up periodic refresh for real-time data (every 30 seconds)
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      _loadProfileData();
    });
    
    // Add listeners for form validation
    _usernameController.addListener(_validateUsernameForm);
    _currentPasswordController.addListener(_validateUsernameForm);
    _newPasswordController.addListener(_validatePasswordForm);
    _confirmPasswordController.addListener(_validatePasswordForm);
  }

  // Retailer HTTP result mapper (parity with admin-style messages)
  void _showHttpResultSnack(
    Map<String, dynamic> result, {
    String? fallbackSuccess,
    String? fallbackError,
  }) {
    if (!mounted) return;
    final dynamic rawStatus = result['http_status'];
    final int? httpStatus = rawStatus is int ? rawStatus : null;
    final String? code = result['code'] as String?;
    final bool isSuccess = (result['status'] == 'success') || httpStatus == 200 || code == 'HTTP_200';

    String message = (result['message'] as String?) ??
        (isSuccess ? (fallbackSuccess ?? 'Action completed successfully')
                   : (fallbackError ?? 'Action failed'));

    Color bg = Colors.green;
    if (!isSuccess) {
      final int? status = httpStatus ?? _codeToStatus(code);
      switch (status) {
        case 400:
          message = 'Bad Request: The request is invalid or unsupported.';
          bg = Colors.red;
          break;
        case 404:
          message = 'API endpoint not found. Please check the server configuration.';
          bg = Colors.red;
          break;
        case 500:
          message = 'Internal server error. Please try again later.';
          bg = Colors.red;
          break;
        default:
          final label = status != null ? '$status' : (code ?? 'UNKNOWN');
          message = 'Server error: $label';
          bg = Colors.red;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bg, duration: const Duration(seconds: 4)),
    );
  }

  int? _codeToStatus(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'HTTP_200':
        return 200;
      case 'HTTP_400':
        return 400;
      case 'HTTP_404':
        return 404;
      case 'HTTP_500':
        return 500;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateUsernameForm() {
    setState(() {
      _isUsernameFormValid = _usernameController.text.isNotEmpty && 
                           _currentPasswordController.text.isNotEmpty;
    });
  }

  void _validatePasswordForm() {
    setState(() {
      _isPasswordFormValid = _currentPasswordController.text.isNotEmpty &&
                           _newPasswordController.text.isNotEmpty &&
                           _confirmPasswordController.text.isNotEmpty &&
                           _newPasswordController.text == _confirmPasswordController.text;
    });
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.getRetailerProfile();
      final dynamic rawStatus = result['http_status'];
      final int? httpStatus = rawStatus is int ? rawStatus : null;
      final String? code = result['code'] as String?;
      final bool unauthorized = httpStatus == 401 || code == 'UNAUTHORIZED';
      final bool forbidden = httpStatus == 403 || code == 'FORBIDDEN';

      if (unauthorized || forbidden) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      
      if (result['status'] == 'success') {
        final Map<String, dynamic> data = (result['data'] as Map<String, dynamic>? ) ?? {};
        setState(() {
          // API returns { profile, monitoring_form, account_status }
          _profileData = (data['profile'] as Map<String, dynamic>? ) ?? {};
          _monitoringData = (data['monitoring_form'] as Map<String, dynamic>? ) ?? {};
          _isLoading = false;
        });
        
        // Set initial username in form
        _usernameController.text = _profileData['username'] ?? '';
      } else {
        // Do not block UI; show SnackBar and continue with empty data
        setState(() {
          _profileData = {};
          _monitoringData = {};
          _isLoading = false;
          _error = null;
        });
        _showHttpResultSnack(result, fallbackError: 'Failed to load profile');
      }
    } catch (e) {
      setState(() {
        _profileData = {};
        _monitoringData = {};
        _isLoading = false;
        _error = null;
      });
      _showHttpResultSnack({'status': 'error', 'message': 'Error loading profile: $e'});
    }
  }

  Future<void> _loadMonitoringData() async {
    // Monitoring data now comes from the profile API; nothing to do
    return;
  }

  Future<void> _updateUsername() async {
    if (!_isUsernameFormValid) return;

    try {
      final result = await AuthService.updateRetailerProfile(
        username: _usernameController.text.trim(),
        currentPassword: _currentPasswordController.text,
      );

      if (result['status'] == 'success') {
        setState(() {
          _profileData['username'] = _usernameController.text.trim();
        });
        
        if (mounted) {
          _showHttpResultSnack({'status': 'success', 'message': 'Username updated successfully!', 'http_status': 200, 'code': 'HTTP_200'});
          Navigator.pop(context); // Close modal
        }
      } else {
        if (mounted) {
          _showHttpResultSnack(result, fallbackError: 'Failed to update username');
        }
      }
    } catch (e) {
      if (mounted) {
        _showHttpResultSnack({'status': 'error', 'message': 'Error updating username: $e'});
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_isPasswordFormValid) return;

    try {
      final result = await AuthService.updateRetailerProfile(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result['status'] == 'success') {
        if (mounted) {
          _showHttpResultSnack({'status': 'success', 'message': 'Password updated successfully!', 'http_status': 200, 'code': 'HTTP_200'});
          Navigator.pop(context); // Close modal
        }
      } else {
        if (mounted) {
          _showHttpResultSnack(result, fallbackError: 'Failed to update password');
        }
      }
    } catch (e) {
      if (mounted) {
        _showHttpResultSnack({'status': 'error', 'message': 'Error updating password: $e'});
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Upload the image
        await _uploadProfileImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    try {
      print('🔄 RetailerProfilePage: Starting image upload...');
      final result = await AuthService.uploadProfilePicture(_selectedImage!);
      print('📊 RetailerProfilePage: Upload result: $result');

      if (result['status'] == 'success') {
        print('✅ RetailerProfilePage: Upload successful, updating UI...');
        print('📁 RetailerProfilePage: New profile_pic: ${result['data']?['profile_pic']}');
        print('🔗 RetailerProfilePage: New profile_pic_url: ${result['data']?['profile_pic_url']}');
        
        setState(() {
          // Update profile data with new picture filename
          if (result['data'] != null) {
          _profileData['profile_pic'] = result['data']['profile_pic'];
            print('📝 RetailerProfilePage: Updated _profileData[profile_pic] to: ${_profileData['profile_pic']}');
            
          }
          _selectedImage = null;
        });
        
        // Build the new profile picture URL for verification
        final newProfileUrl = AuthService.buildProfilePictureUrl(_profileData['profile_pic']);
        print('🔗 RetailerProfilePage: Built profile URL: $newProfileUrl');
        
        // Test if the URL is accessible
        print('🧪 RetailerProfilePage: Testing if image URL is accessible...');
        try {
          final response = await http.head(Uri.parse(newProfileUrl));
          print('📊 RetailerProfilePage: Image URL response status: ${response.statusCode}');
          if (response.statusCode == 200) {
            print('✅ RetailerProfilePage: Image URL is accessible!');
          } else {
            print('❌ RetailerProfilePage: Image URL returned status: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ RetailerProfilePage: Error testing image URL: $e');
        }
        
        // Refresh profile data from server to ensure we have the latest
        print('🔄 RetailerProfilePage: Refreshing profile data from server...');
        await _loadProfileData();
        
        if (mounted) {
          _showHttpResultSnack(result, fallbackSuccess: 'Profile picture updated successfully!');
        }
      } else {
        print('❌ RetailerProfilePage: Upload failed: ${result['message']}');
        if (mounted) {
          _showHttpResultSnack(result, fallbackError: 'Failed to upload image');
        }
      }
    } catch (e) {
      print('❌ RetailerProfilePage: Upload error: $e');
      if (mounted) {
        _showHttpResultSnack({'status': 'error', 'message': 'Error uploading image: $e'});
      }
    }
  }

  void _showUsernameChangeModal() {
    _usernameController.text = _profileData['username'] ?? '';
    _currentPasswordController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUsernameChangeModal(),
    );
  }

  void _showPasswordChangeModal() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPasswordChangeModal(),
    );
  }

  Widget _buildUsernameChangeModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Update Username',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              width: double.infinity,
            ),
            
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'New Username',
                      hintText: 'Enter new username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter current password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUsernameFormValid ? _updateUsername : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Update Username',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordChangeModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              width: double.infinity,
            ),
            
            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter current password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Confirm new password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _confirmPasswordController.text.isNotEmpty &&
                                _newPasswordController.text != _confirmPasswordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPasswordFormValid ? _updatePassword : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Update Password',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Profile Picture',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileData['profile_pic'] != null
                        ? NetworkImage(
                            AuthService.buildProfilePictureUrl(_profileData['profile_pic']),
                          )
                        : null,
                    child: _profileData['profile_pic'] == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  if (_selectedImage != null)
                    Positioned.fill(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.black54,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Change Picture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Debug button to test profile picture
            ElevatedButton.icon(
              onPressed: () async {
                print('🔍 RetailerProfilePage: Manual profile picture debug...');
                print('📊 Current profile_pic: ${_profileData['profile_pic']}');
                
                final url = AuthService.buildProfilePictureUrl(_profileData['profile_pic']);
                print('🔗 Built URL: $url');
                
                // Test URL accessibility
                try {
                  final response = await http.head(Uri.parse(url));
                  print('📊 URL test response: ${response.statusCode}');
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile pic: ${_profileData['profile_pic']}\nURL: $url\nStatus: ${response.statusCode}'),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ URL test error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('URL test error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Profile Pic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Username', _profileData['username'] ?? 'N/A'),
            _buildInfoRow('Email', _profileData['email'] ?? 'N/A'),
            _buildInfoRow('Store Name', _profileData['store_name'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('First Name', _profileData['first_name']?.toString() ?? 'N/A'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoRow('Last Name', _profileData['last_name']?.toString() ?? 'N/A'),
                ),
              ],
            ),
            _buildInfoRow('Middle Name', _profileData['middle_name']?.toString() ?? 'N/A'),
            _buildInfoRow('Location', _profileData['location_string']?.toString() ?? '${_profileData['barangay_name'] ?? 'N/A'}, ${_profileData['city_name'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringInfoCard() {
    if (_monitoringData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Store Monitoring Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Store Name', _monitoringData['store_name']?.toString() ?? 'N/A'),
                      _buildInfoRow('Store Address', _monitoringData['store_address']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Monitoring Date', _monitoringData['monitoring_date']?.toString() ?? 'N/A'),
                      _buildInfoRow('Monitoring Mode', _monitoringData['monitoring_mode']?.toString() ?? 'N/A'),
                      _buildInfoRow('DTI Monitor', _monitoringData['dti_monitor']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Navigate back to dashboard instead of login page
        Navigator.pushReplacementNamed(context, '/retailer-dashboard');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Retailer Profile'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/retailer-dashboard');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProfileData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showUsernameChangeModal,
                              icon: const Icon(Icons.edit),
                              label: const Text('Change Username'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showPasswordChangeModal,
                              icon: const Icon(Icons.key),
                              label: const Text('Change Password'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Profile Picture and Account Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildProfilePictureCard(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAccountInfoCard(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Personal Information
                      _buildPersonalInfoCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Monitoring Information
                      _buildMonitoringInfoCard(),
                    ],
                  ),
                ),
      ),
    );
  }
}
