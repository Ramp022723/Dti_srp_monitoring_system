import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: AppConstants.defaultPadding,
              right: AppConstants.defaultPadding,
              bottom: AppConstants.defaultPadding,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        authProvider.userInitials,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Text(
                      authProvider.userDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.currentUser?.adminTypeDisplay ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuSection(
                  context,
                  'Overview',
                  [
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to dashboard
                      },
                    ),
                  ],
                ),
                
                _buildMenuSection(
                  context,
                  'Management',
                  [
                    _buildMenuItem(
                      context,
                      icon: Icons.people_outline,
                      title: 'Manage Admin Users',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to user management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Consumer Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to consumer management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.store_outlined,
                      title: 'Retailer Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to retailer management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.inventory_outlined,
                      title: 'Product Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to product management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Retailer Store Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to store management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.report_problem_outlined,
                      title: 'Complaint Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to complaint management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.credit_card_outlined,
                      title: 'Retailer Registration',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to retailer registration
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.warning_outlined,
                      title: 'Price Freeze Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to price freeze management
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.verified_user_outlined,
                      title: 'Consumer Verification',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to consumer verification
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.gavel_outlined,
                      title: 'SRP Violation Management',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to violation management
                      },
                    ),
                  ],
                ),
                
                _buildMenuSection(
                  context,
                  'Account',
                  [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to profile
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to settings
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: AppTheme.errorColor,
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                const Divider(),
                Text(
                  'DTI TACP System',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.defaultPadding,
            AppConstants.largePadding,
            AppConstants.defaultPadding,
            AppConstants.smallPadding,
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTextMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.lightTextSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 4,
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
