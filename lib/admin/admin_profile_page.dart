import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'dart:async';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({Key? key}) : super(key: key);

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _adminData = {};
  bool _isLoading = true;
  String? _error;
  
  // Form controllers
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Form validation
  bool _isProfileFormValid = false;
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
    _usernameController.addListener(_validateProfileForm);
    _firstNameController.addListener(_validateProfileForm);
    _lastNameController.addListener(_validateProfileForm);
    _emailController.addListener(_validateProfileForm);
    _currentPasswordController.addListener(_validatePasswordForm);
    _newPasswordController.addListener(_validatePasswordForm);
    _confirmPasswordController.addListener(_validatePasswordForm);
  }

  // Admin HTTP result mapper (parity with retailer-style messages)
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateProfileForm() {
    setState(() {
      _isProfileFormValid = _usernameController.text.isNotEmpty && 
                           _firstNameController.text.isNotEmpty &&
                           _lastNameController.text.isNotEmpty &&
                           _emailController.text.isNotEmpty;
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
      final result = await AuthService.getAdminProfile();
      final dynamic rawStatus = result['http_status'];
      final int? httpStatus = rawStatus is int ? rawStatus : null;
      final String? code = result['code'] as String?;
      final bool unauthorized = httpStatus == 401 || code == 'UNAUTHORIZED';
      final bool forbidden = httpStatus == 403 || code == 'FORBIDDEN';

      if (unauthorized || forbidden) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin-login');
        return;
      }
      
      if (result['status'] == 'success') {
        final Map<String, dynamic> data = (result['data'] as Map<String, dynamic>? ) ?? {};
        setState(() {
          // API returns admin profile data
          _profileData = data;
          _adminData = data;
          _isLoading = false;
        });
        
        // Set initial form values
        _usernameController.text = _profileData['username'] ?? '';
        _firstNameController.text = _profileData['first_name'] ?? '';
        _lastNameController.text = _profileData['last_name'] ?? '';
        _emailController.text = _profileData['email'] ?? '';
        _lastProfilePicUrl = _profileData['profile_picture'];
      } else {
        // Do not block UI; show SnackBar and continue with empty data
        setState(() {
          _profileData = {};
          _adminData = {};
          _isLoading = false;
          _error = null;
        });
        _showHttpResultSnack(result, fallbackError: 'Failed to load admin profile');
      }
    } catch (e) {
      setState(() {
        _profileData = {};
        _adminData = {};
        _isLoading = false;
        _error = null;
      });
      _showHttpResultSnack({'status': 'error', 'message': 'Error loading admin profile: $e'});
    }
  }

  Future<void> _updateProfile() async {
    if (!_isProfileFormValid) return;

    try {
      final profileData = {
        'username': _usernameController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      final result = await AuthService.updateAdminProfile(profileData);
      _showHttpResultSnack(result, 
        fallbackSuccess: 'Profile updated successfully',
        fallbackError: 'Failed to update profile'
      );

      if (result['status'] == 'success') {
        // Reload profile data to get updated information
        await _loadProfileData();
      }
    } catch (e) {
      _showHttpResultSnack({'status': 'error', 'message': 'Error updating profile: $e'});
    }
  }

  Future<void> _updatePassword() async {
    if (!_isPasswordFormValid) return;

    try {
      final passwordData = {
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
        'confirm_password': _confirmPasswordController.text,
      };

      final result = await AuthService.updateAdminPassword(passwordData);
      _showHttpResultSnack(result, 
        fallbackSuccess: 'Password updated successfully',
        fallbackError: 'Failed to update password'
      );

      if (result['status'] == 'success') {
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      _showHttpResultSnack({'status': 'error', 'message': 'Error updating password: $e'});
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // Upload the image
        await _uploadProfilePicture();
      }
    } catch (e) {
      _showHttpResultSnack({'status': 'error', 'message': 'Error picking image: $e'});
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

    try {
      final result = await AuthService.uploadAdminProfilePicture(_selectedImage!);
      _showHttpResultSnack(result, 
        fallbackSuccess: 'Profile picture updated successfully',
        fallbackError: 'Failed to upload profile picture'
      );

      if (result['status'] == 'success') {
        // Reload profile data to get updated picture URL
        await _loadProfileData();
        setState(() {
          _selectedImage = null;
        });
      }
    } catch (e) {
      _showHttpResultSnack({'status': 'error', 'message': 'Error uploading profile picture: $e'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        // Navigate back to admin dashboard
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: _isLoading
            ? _buildLoadingWidget()
            : _error != null
                ? _buildErrorWidget()
                : _buildMainContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Manage your account',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pushReplacementNamed(context, '/admin-dashboard'),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading admin profile...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An error occurred while loading your profile',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Picture Section
          _buildProfilePictureSection(),
          const SizedBox(height: 24),
          
          // Profile Information Section
          _buildProfileInfoSection(),
          const SizedBox(height: 24),
          
          // Change Password Section
          _buildPasswordSection(),
          const SizedBox(height: 24),
          
          // Admin Statistics Section
          _buildAdminStatsSection(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (_lastProfilePicUrl != null && _lastProfilePicUrl!.isNotEmpty)
                        ? NetworkImage(_lastProfilePicUrl!)
                        : null,
                child: _selectedImage == null && (_lastProfilePicUrl == null || _lastProfilePicUrl!.isEmpty)
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF3B82F6),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_profileData['first_name'] ?? ''} ${_profileData['last_name'] ?? ''}'.trim(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _profileData['admin_type'] ?? 'Administrator',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _profileData['email'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline,
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person,
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person,
            enabled: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: true,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProfileFormValid ? _updateProfile : null,
              icon: const Icon(Icons.save),
              label: const Text('Update Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _currentPasswordController,
            label: 'Current Password',
            icon: Icons.lock,
            enabled: true,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _newPasswordController,
            label: 'New Password',
            icon: Icons.lock_outline,
            enabled: true,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            icon: Icons.lock_outline,
            enabled: true,
            obscureText: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPasswordFormValid ? _updatePassword : null,
              icon: const Icon(Icons.security),
              label: const Text('Update Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Admin ID', _profileData['admin_id']?.toString() ?? 'N/A'),
          _buildInfoRow('Admin Type', _profileData['admin_type'] ?? 'N/A'),
          _buildInfoRow('Status', _profileData['status'] ?? 'Active'),
          _buildInfoRow('Created', _formatDate(_profileData['created_at'])),
          _buildInfoRow('Last Updated', _formatDate(_profileData['updated_at'])),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

