class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://dtisrpmonitoring.bccbsis.com';
  static const String apiBaseUrl = '$baseUrl/api';
  
  // API Endpoints
  static const String loginEndpoint = '/login.php';
  static const String userManagementEndpoint = '/api_user_management.php';
  static const String consumerManagementEndpoint = '/consumer_management.php';
  static const String retailerManagementEndpoint = '/retailer_management.php';
  static const String productManagementEndpoint = '/product_management.php';
  static const String complaintManagementEndpoint = '/complaint_management.php';
  
  // App Configuration
  static const String appName = 'DTI Admin';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Colors
  static const int primaryColorValue = 0xFF3B82F6;
  static const int primaryLightColorValue = 0xFFEFF6FF;
  static const int primaryDarkColorValue = 0xFF1D4ED8;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 50;
  static const int maxNameLength = 100;
  
  // Error Messages
  static const String networkError = 'Network connection error';
  static const String serverError = 'Server error occurred';
  static const String unauthorizedError = 'Unauthorized access';
  static const String notFoundError = 'Resource not found';
  static const String validationError = 'Validation error';
  
  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String logoutSuccess = 'Logout successful';
  static const String updateSuccess = 'Update successful';
  static const String deleteSuccess = 'Delete successful';
  static const String createSuccess = 'Create successful';
}
