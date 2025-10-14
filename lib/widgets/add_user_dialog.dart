import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'custom_text_field.dart';
import 'loading_button.dart';

class AddUserDialog extends StatefulWidget {
  final User? user;
  final Function(User)? onUserAdded;
  
  const AddUserDialog({
    super.key,
    this.user,
    this.onUserAdded,
  });
  
  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedAdminType = 'admin';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _middleNameController.text = widget.user!.middleName ?? '';
      _usernameController.text = widget.user!.username;
      _selectedAdminType = widget.user!.adminType;
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.person_add,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Text(
                        isEditing ? 'Edit User' : 'Add New User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Admin Type
                  DropdownButtonFormField<String>(
                    value: _selectedAdminType,
                    decoration: const InputDecoration(
                      labelText: 'Admin Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'barangay_admin',
                        child: Text('Barangay Admin'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAdminType = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an admin type';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Name Fields
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _firstNameController,
                          labelText: 'First Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter first name';
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter last name';
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
                    labelText: 'Middle Name (Optional)',
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  
                  if (!isEditing) ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < AppConstants.minPasswordLength) {
                          return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppConstants.defaultPadding),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return LoadingButton(
                            onPressed: userProvider.isLoading ? null : _saveUser,
                            isLoading: userProvider.isLoading,
                            isFullWidth: false,
                            child: Text(isEditing ? 'Update' : 'Create'),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final userData = {
      'admin_type': _selectedAdminType,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'middle_name': _middleNameController.text.trim(),
      'username': _usernameController.text.trim(),
    };
    
    // Add password for new users
    if (widget.user == null) {
      userData['password'] = _passwordController.text;
    } else {
      userData['admin_id'] = widget.user!.id.toString();
    }
    
    Map<String, dynamic> result;
    
    if (widget.user == null) {
      result = await userProvider.createUser(
        userData,
        authToken: authProvider.authToken,
      );
    } else {
      result = await userProvider.updateUser(
        userData,
        authToken: authProvider.authToken,
      );
    }
    
    if (mounted) {
      if (result['success'] == true) {
        Navigator.of(context).pop();
        if (widget.onUserAdded != null) {
          widget.onUserAdded!(result['data']);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
