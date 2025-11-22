import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import 'dart:async';

/// Settings Page
/// 
/// Common Android/mobile app settings page with:
/// - Account & Profile settings
/// - App Preferences (Theme, Language, etc.)
/// - Notifications settings
/// - Data & Storage management
/// - Privacy & Security
/// - About & Help
/// - Logout
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSyncEnabled = true;
  bool _biometricEnabled = false;
  String _themeMode = 'system'; // system, light, dark
  String _language = 'en';
  int _dataRefreshInterval = 30; // seconds
  int _sessionTimeout = 30; // minutes
  bool _cacheEnabled = true;
  
  // App info
  String _appVersion = AppConstants.appVersion;
  String _appName = AppConstants.appName;
  
  // Loading state
  bool _isLoading = true;
  
  // User info
  Map<String, dynamic>? _userInfo;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
    _loadUserInfo();
  }

  Future<void> _loadAppInfo() async {
    // App info is loaded from constants
    // In a production app, you could use package_info_plus to get actual version
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _userInfo = user;
          _userRole = user['role'] ?? user['user_type'] ?? 'user';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current theme from ThemeProvider
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      String currentTheme = 'system';
      if (themeProvider.isLightMode) {
        currentTheme = 'light';
      } else if (themeProvider.isDarkMode) {
        currentTheme = 'dark';
      } else {
        currentTheme = 'system';
      }
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
          _soundEnabled = prefs.getBool('settings_sound') ?? true;
          _vibrationEnabled = prefs.getBool('settings_vibration') ?? true;
          _autoSyncEnabled = prefs.getBool('settings_auto_sync') ?? true;
          _biometricEnabled = prefs.getBool('settings_biometric') ?? false;
          _themeMode = prefs.getString('settings_theme') ?? currentTheme;
          _language = prefs.getString('settings_language') ?? 'en';
          _dataRefreshInterval = prefs.getInt('settings_refresh_interval') ?? 30;
          _sessionTimeout = prefs.getInt('settings_session_timeout') ?? 30;
          _cacheEnabled = prefs.getBool('settings_cache') ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear non-essential cached data
      await prefs.remove('cached_products');
      await prefs.remove('cached_retailers');
      await prefs.remove('cached_folders');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode || 
                       (themeProvider.isSystemMode && 
                        MediaQuery.of(context).platformBrightness == Brightness.dark);
        
        return PopScope(
          canPop: true, // Allow back navigation to dashboard
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              // Back button will work automatically
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Account Section
                  _buildSectionHeader('Account'),
                  _buildAccountSection(),
                  
                  // App Preferences Section
                  _buildSectionHeader('App Preferences'),
                  _buildAppPreferencesSection(),
                  
                  // Notifications Section
                  _buildSectionHeader('Notifications'),
                  _buildNotificationsSection(),
                  
                  // Data & Storage Section
                  _buildSectionHeader('Data & Storage'),
                  _buildDataStorageSection(),
                  
                  // Privacy & Security Section
                  _buildSectionHeader('Privacy & Security'),
                  _buildPrivacySecuritySection(),
                  
                  // About Section
                  _buildSectionHeader('About'),
                  _buildAboutSection(),
                  
                  // Logout Button
                  _buildLogoutSection(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    final username = _userInfo?['username'] ?? _userInfo?['user_name'] ?? 'User';
    final email = _userInfo?['email'] ?? '';
    final role = _userRole.isNotEmpty ? _userRole.toUpperCase() : 'USER';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFF2563EB)),
            ),
            title: Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: email.isNotEmpty
                ? Text(email)
                : Text('Role: $role'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
            onTap: () {
              // Navigate to profile page based on role
              if (_userRole == 'admin') {
                Navigator.pushNamed(context, '/admin/profile');
              } else if (_userRole == 'retailer') {
                Navigator.pushNamed(context, '/retailer/profile');
              }
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: _themeMode == 'system'
                ? 'System Default'
                : _themeMode == 'light'
                    ? 'Light'
                    : 'Dark',
            trailing: _buildThemeSelector(),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _language == 'en' ? 'English' : 'Filipino',
            trailing: _buildLanguageSelector(),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.refresh,
            title: 'Data Refresh Interval',
            subtitle: '${_dataRefreshInterval} seconds',
            trailing: _buildRefreshIntervalSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Enable Notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSetting('settings_notifications', value);
            },
          ),
          if (_notificationsEnabled) ...[
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Sound',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _saveSetting('settings_sound', value);
              },
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.vibration,
              title: 'Vibration',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                _saveSetting('settings_vibration', value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataStorageSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSwitchTile(
            icon: Icons.sync,
            title: 'Auto Sync',
            subtitle: 'Automatically sync data in background',
            value: _autoSyncEnabled,
            onChanged: (value) {
              setState(() {
                _autoSyncEnabled = value;
              });
              _saveSetting('settings_auto_sync', value);
            },
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.storage,
            title: 'Enable Cache',
            subtitle: 'Cache data for offline access',
            value: _cacheEnabled,
            onChanged: (value) {
              setState(() {
                _cacheEnabled = value;
              });
              _saveSetting('settings_cache', value);
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: _clearCache,
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySecuritySection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSettingsTile(
            icon: Icons.timer_outlined,
            title: 'Session Timeout',
            subtitle: '${_sessionTimeout} minutes',
            trailing: _buildSessionTimeoutSelector(),
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() {
                _biometricEnabled = value;
              });
              _saveSetting('settings_biometric', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: 'Version $_appVersion',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$_appName v$_appVersion'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _showHelpDialog(),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => _showTermsDialog(),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showPrivacyDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null
          ? Icon(Icons.chevron_right, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
          : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return PopupMenuButton<String>(
      icon: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      onSelected: (value) async {
        setState(() {
          _themeMode = value;
        });
        _saveSetting('settings_theme', value);
        
        // Update theme provider
        switch (value) {
          case 'light':
            await themeProvider.setLightMode();
            break;
          case 'dark':
            await themeProvider.setDarkMode();
            break;
          case 'system':
          default:
            await themeProvider.setSystemMode();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'system',
          child: Text('System Default'),
        ),
        const PopupMenuItem(
          value: 'light',
          child: Text('Light'),
        ),
        const PopupMenuItem(
          value: 'dark',
          child: Text('Dark'),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return PopupMenuButton<String>(
      icon: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      onSelected: (value) {
        setState(() {
          _language = value;
        });
        _saveSetting('settings_language', value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        const PopupMenuItem(
          value: 'fil',
          child: Text('Filipino'),
        ),
      ],
    );
  }

  Widget _buildRefreshIntervalSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return PopupMenuButton<int>(
      icon: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      onSelected: (value) {
        setState(() {
          _dataRefreshInterval = value;
        });
        _saveSetting('settings_refresh_interval', value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 10, child: Text('10 seconds')),
        const PopupMenuItem(value: 30, child: Text('30 seconds')),
        const PopupMenuItem(value: 60, child: Text('1 minute')),
        const PopupMenuItem(value: 300, child: Text('5 minutes')),
      ],
    );
  }

  Widget _buildSessionTimeoutSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode || 
                   (themeProvider.isSystemMode && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return PopupMenuButton<int>(
      icon: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      onSelected: (value) {
        setState(() {
          _sessionTimeout = value;
        });
        _saveSetting('settings_session_timeout', value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 15, child: Text('15 minutes')),
        const PopupMenuItem(value: 30, child: Text('30 minutes')),
        const PopupMenuItem(value: 60, child: Text('1 hour')),
        const PopupMenuItem(value: 120, child: Text('2 hours')),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Call change password API
              // This would need to be implemented in AuthService
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Need help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Contact support: support@dti.gov.ph'),
              SizedBox(height: 8),
              Text('• Phone: (02) 751-3330'),
              SizedBox(height: 8),
              Text('• Visit our website for more information'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to comply with all applicable laws and regulations. '
            'The Department of Trade and Industry (DTI) reserves the right to modify these terms at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. We collect and use your data in accordance with the Data Privacy Act of 2012. '
            'We do not share your personal information with third parties without your consent.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

