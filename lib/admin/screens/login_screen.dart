import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    
    if (mounted) {
      if (result['success'] == true) {
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDarkColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding * 2),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and Title
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: AppConstants.largePadding * 2),
                        
                        // Username Field
                        CustomTextField(
                          controller: _usernameController,
                          labelText: 'Username',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        
                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline,
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
                              return 'Please enter your password';
                            }
                            if (value.length < AppConstants.minPasswordLength) {
                              return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        
                        // Login Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return LoadingButton(
                              onPressed: authProvider.isLoading ? null : _handleLogin,
                              isLoading: authProvider.isLoading,
                              child: const Text('Login'),
                            );
                          },
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        
                        // Footer
                        Text(
                          'DTI Tracking and Consumer Portal System',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTextMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        
                        Text(
                          'Version ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
