import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import shared pages
import 'shared/registration_page.dart';
import 'shared/landing_page.dart';
import 'shared/user_type_selection_page.dart';

// Import consumer pages
import 'consumer/consumer_dashboard.dart';
import 'consumer/consumer_dashboard_page.dart';
import 'consumer/consumer_registration_page.dart';
import 'consumer/consumer_login_page.dart';

// Import retailer pages
import 'retailer/retailer_dashboard.dart';
import 'retailer/retailer_registration_page.dart';
import 'retailer/retailer_login_page.dart';
import 'retailer/retailer_agreement_page.dart';
import 'retailer/retailer_product_list_page.dart';
import 'retailer/retailer_profile_page.dart';
import 'retailer/retailer_store_products_page.dart';
import 'retailer/retailer_notifications_page.dart';
// Note: RetailerNotificationDetailPage requires notification parameter,
// navigate using: Navigator.push(context, MaterialPageRoute(builder: (context) => RetailerNotificationDetailPage(notification: data)))

// Import admin pages
import 'admin/admin_dashboard.dart';
import 'admin/admin_login_page.dart';
import 'admin/product_folders_page.dart';
import 'admin/price_management_page.dart';
import 'admin/price_freeze_management_page.dart';
import 'admin/product_crud_page.dart';
import 'admin/admin_user_management_page.dart';
import 'admin/complaints_management_page.dart';
import 'admin/monitoring.dart';
import 'admin/products.dart';
import 'admin/retailer_store_management.dart';

// Import admin screens from main_screen
import 'admin/screens/dashboard_screen.dart';
import 'admin/screens/user_management_screen.dart';
import 'admin/screens/consumer_management_screen.dart';
import 'admin/screens/retailer_management_screen.dart';
import 'admin/screens/product_management_screen.dart';
import 'admin/screens/complaint_management_screen.dart';
import 'admin/screens/profile_screen.dart';

// Import monitoring screens
import 'screens/monitoring/monitoring_screen.dart';
import 'screens/monitoring/monitoring_forms_screen.dart';
import 'screens/monitoring/create_monitoring_form_screen.dart';
import 'screens/monitoring/form_details_screen.dart';

// Import products screens
import 'screens/products/products_screen.dart';

// Import retailer store screens
import 'screens/retailers/retailer_store_screen.dart';

// Import services
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';

// Note: Providers, utils, and widgets from main_screen.dart are available 
// but not used in the current main.dart structure
// They can be imported when needed for specific screens

// Note: admin/screens/ folder contains alternative UI components
// These are currently not used in routes, kept for future reference

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences for session management
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize AuthService to load persisted session
  await AuthService.init();
  
  runApp(
    MultiProvider(
      providers: [
        // Add your providers here if they exist
        // ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        // ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        // ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const DTIAdminApp(),
    ),
  );
}

class DTIAdminApp extends StatelessWidget {
  const DTIAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DTI TACP System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.blueAccent, // 15% Blue
          onPrimary: Colors.white,
          secondary: Colors.redAccent, // 15% Red
          onSecondary: Colors.white,
          error: Colors.red.shade700,
          onError: Colors.white,
          background: Colors.white, // 60% White background
          onBackground: Colors.black,
          surface: Colors.yellow.shade100, // 10% Yellow accent
          onSurface: Colors.black,
        ),
        useMaterial3: true,
      ),
      // Use AuthWrapper as home to handle authentication state
      home: const AuthWrapper(),
      // Keep routes for direct navigation
      routes: {
         '/': (context) => const LandingPage(),
        '/user-type-selection': (context) => const UserTypeSelectionPage(),
        // Legacy login route (for backward compatibility)
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final userType = args?['userType'] as String?;
          
          // Redirect to specific login page based on userType
          if (userType != null) {
            switch (userType.toLowerCase()) {
              case 'admin':
                return const AdminLoginPage();
              case 'consumer':
                return const ConsumerLoginPage();
              case 'retailer':
                return const RetailerLoginPage();
              default:
                return const UserTypeSelectionPage();
            }
          }
          // If no userType specified, go to user type selection
          return const UserTypeSelectionPage();
        },
        // Separate login pages for each user type
        '/admin-login': (context) => const AdminLoginPage(),
        '/consumer-login': (context) => const ConsumerLoginPage(),
        '/retailer-login': (context) => const RetailerLoginPage(),
        // Registration routes
        '/register': (context) => const RegistrationPage(),
        '/consumer-registration': (context) => const ConsumerRegistrationPage(),
        '/retailer-registration': (context) => const RetailerRegistrationPage(),
        // Dashboard routes
        '/consumer-dashboard': (context) => const ConsumerDashboard(),
        '/consumer_dashboard': (context) => const ConsumerDashboardPage(),
        '/retailer-dashboard': (context) => const RetailerDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        // Admin sub-pages
      '/admin/product-folders': (context) => const ProductFoldersPage(),
      '/admin/price-management': (context) => const PriceManagementPage(),
      '/admin/price-freeze': (context) => const PriceFreezeManagementPage(),
      '/admin/product-crud': (context) => const ProductCRUDPage(),
      '/admin/user-management': (context) => const AdminUserManagementPage(),
      '/admin/complaints': (context) => const ComplaintsManagementPage(),
        // Admin screens from main_screen
        '/admin/dashboard-screen': (context) => const DashboardScreen(),
        '/admin/user-management-screen': (context) => const UserManagementScreen(),
        '/admin/consumer-management-screen': (context) => const ConsumerManagementScreen(),
        '/admin/retailer-management-screen': (context) => const RetailerManagementScreen(),
        '/admin/product-management-screen': (context) => const ProductManagementScreen(),
        '/admin/complaint-management-screen': (context) => const ComplaintManagementScreen(),
        '/admin/profile-screen': (context) => const ProfileScreen(),
        // Monitoring routes
        '/monitoring': (context) => const MonitoringScreen(),
        '/monitoring/forms': (context) => const MonitoringFormsScreen(),
        '/monitoring/create-form': (context) => const CreateMonitoringFormScreen(),
        // Note: Form details uses Navigator.push with form parameter
        // Products routes
        '/products': (context) => const ProductsScreen(),
        // Note: Product details, create, and analytics use Navigator.push with parameters
        // Retailer store management routes
        '/retailers/stores': (context) => const RetailerStoreScreen(),
        // Note: Retailer details, violation alerts, and analytics use Navigator.push
        // Retailer sub-pages
        '/retailer/agreements': (context) => const RetailerAgreementPage(),
        '/retailer/product-list': (context) => const RetailerProductListPage(),
        '/retailer/profile': (context) => const RetailerProfilePage(),
        '/retailer/store-products': (context) => const RetailerStoreProductsPage(),
        '/retailer/notifications': (context) => const RetailerNotificationsPage(),
        // Note: RetailerNotificationDetailPage requires parameters, use Navigator.push() instead
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userRole;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check if user is logged in using AuthService
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (isLoggedIn) {
        // Get user role and data
        final role = await AuthService.getUserRole();
        final userData = await AuthService.getCurrentUser();
        
        setState(() {
          _isAuthenticated = true;
          _userRole = role;
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isAuthenticated = false;
          _userRole = null;
          _userData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ AuthWrapper: Error checking auth status: $e');
      setState(() {
        _isAuthenticated = false;
        _userRole = null;
        _userData = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      setState(() {
        _isAuthenticated = false;
        _userRole = null;
        _userData = null;
      });
    } catch (e) {
      print('❌ AuthWrapper: Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading DTI TACP System...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_isAuthenticated && _userRole != null) {
      // User is authenticated, show appropriate dashboard
      return DashboardService.getDashboardByRole(_userRole!);
    } else {
      // User is not authenticated, show landing page
      return const LandingPage();
    }
  }
}

// Enhanced Landing Page with better integration
class EnhancedLandingPage extends StatelessWidget {
  const EnhancedLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DTI TACP System'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to DTI TACP System',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Department of Trade and Industry\nTracking and Consumer Portal',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/user-type-selection');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Admin Login',
                    Icons.admin_panel_settings,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/admin-login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Consumer Login',
                    Icons.person,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/consumer-login'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Retailer Login',
                    Icons.store,
                    Colors.orange,
                    () => Navigator.pushNamed(context, '/retailer-login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Register',
                    Icons.person_add,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/register'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}