import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  
  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _middleNameController.text = user.middleName ?? '';
      _usernameController.text = user.username;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Profile Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            authProvider.userInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          authProvider.userDisplayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.currentUser?.adminTypeDisplay ?? 'Admin',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _toggleEdit,
                              icon: Icon(_isEditing ? Icons.close : Icons.edit),
                              label: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(width: AppConstants.defaultPadding),
                              ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Profile Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.largePadding),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _firstNameController,
                              labelText: 'First Name',
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.defaultPadding),
                          Expanded(
                            child: CustomTextField(
                              controller: _lastNameController,
                              labelText: 'Last Name',
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      CustomTextField(
                        controller: _middleNameController,
                        labelText: 'Middle Name',
                        enabled: _isEditing,
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      CustomTextField(
                        controller: _usernameController,
                        labelText: 'Username',
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Admin Type'),
                        enabled: false,
                        initialValue: Provider.of<AuthProvider>(context, listen: false)
                            .currentUser?.adminTypeDisplay ?? 'Admin',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Account Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                    
                    _buildInfoRow(
                      'User ID',
                      Provider.of<AuthProvider>(context, listen: false)
                          .currentUser?.id.toString() ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Email',
                      Provider.of<AuthProvider>(context, listen: false)
                          .currentUser?.email ?? 'Not provided',
                    ),
                    _buildInfoRow(
                      'Created',
                      Provider.of<AuthProvider>(context, listen: false)
                          .currentUser?.createdAt?.toString().split(' ')[0] ?? 'Unknown',
                    ),
                    _buildInfoRow(
                      'Last Updated',
                      Provider.of<AuthProvider>(context, listen: false)
                          .currentUser?.updatedAt?.toString().split(' ')[0] ?? 'Unknown',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Recent Activity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                    
                    _buildActivityItem(
                      Icons.edit,
                      'Profile updated',
                      'Your profile information was updated',
                      'Just now',
                    ),
                    _buildActivityItem(
                      Icons.people,
                      'Managed user accounts',
                      'You managed several user accounts',
                      '2 hours ago',
                    ),
                    _buildActivityItem(
                      Icons.store,
                      'Approved new retailer',
                      'You approved a new retailer registration',
                      '1 day ago',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(IconData icon, String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.lightTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: AppTheme.lightTextMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _loadUserData(); // Reset form data
      }
    });
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Profile updates are not available in this version
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updates are not available in this version'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
