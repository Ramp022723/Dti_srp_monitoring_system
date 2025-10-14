# Admin Management API Integration

This document outlines the integration between the Flutter app and the `admin_management.php` API endpoint.

## Overview

The Flutter app now uses a unified admin management service that matches the PHP API structure exactly. Both the existing `UserManagementService` and the new `AdminManagementService` have been updated to work with the `admin_management.php` endpoint.

## API Endpoint Structure

### PHP API: `admin_management.php`

The PHP API supports the following HTTP methods:

- **GET**: Fetch admin users (all or specific by ID)
- **POST**: Create new admin user
- **PUT**: Update existing admin user  
- **DELETE**: Delete admin user

## Changes Made

### 1. Updated UserManagementService

**File**: `lib/services/user_management_service.dart`

**Key Changes**:
- Changed all API endpoints from separate files (`admin_users.php`, `admin_register.php`) to use `admin_management.php`
- Updated response parsing to match PHP API format:
  - `data['data']` instead of `data['user']` or `data['users']`
  - `data['count']` instead of `data['total']`
  - Added proper `code` field handling from API responses
- Updated error codes to match PHP API:
  - `ADMIN_FETCHED`, `ADMIN_CREATED`, `ADMIN_UPDATED`, `ADMIN_DELETED`
  - `ADMIN_NOT_FOUND` instead of `USER_NOT_FOUND`

### 2. Created New AdminManagementService

**File**: `lib/services/admin_management_service.dart`

**Features**:
- Clean, dedicated service for admin management
- Comprehensive documentation
- Input validation utilities
- Error handling that matches PHP API responses
- Type-safe methods with proper return types

## API Response Format

### Success Response (GET All Users)
```json
{
  "status": "success",
  "message": "Admin users fetched successfully",
  "code": "ADMINS_FETCHED",
  "count": 5,
  "data": [
    {
      "admin_id": 1,
      "admin_type": "admin",
      "first_name": "John",
      "last_name": "Doe",
      "middle_name": "",
      "username": "admin1"
    }
  ]
}
```

### Success Response (GET Single User)
```json
{
  "status": "success",
  "message": "Admin user fetched successfully", 
  "code": "ADMIN_FETCHED",
  "data": {
    "admin_id": 1,
    "admin_type": "admin",
    "first_name": "John",
    "last_name": "Doe",
    "middle_name": "",
    "username": "admin1"
  }
}
```

### Success Response (CREATE)
```json
{
  "status": "success",
  "message": "New admin user added successfully",
  "code": "ADMIN_CREATED",
  "data": {
    "admin_id": 2,
    "admin_type": "barangay_admin",
    "first_name": "Jane",
    "last_name": "Smith",
    "middle_name": "M",
    "username": "jane.smith"
  }
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Username already exists. Please choose a different username",
  "code": "USERNAME_EXISTS"
}
```

## Usage Examples

### Using AdminManagementService

```dart
import 'package:login_app/services/admin_management_service.dart';

// Fetch all admin users
final result = await AdminManagementService.getAllAdminUsers();
if (result['status'] == 'success') {
  List<AdminUser> users = result['users'];
  int count = result['count'];
  print('Found $count admin users');
}

// Get specific admin user
final userResult = await AdminManagementService.getAdminUser(adminId: 1);
if (userResult['status'] == 'success') {
  AdminUser user = userResult['user'];
  print('User: ${user.fullName}');
}

// Create new admin user
final createResult = await AdminManagementService.createAdminUser(
  adminType: 'admin',
  firstName: 'John',
  lastName: 'Doe',
  middleName: '',
  username: 'john.doe',
  password: 'securepassword123',
);

// Update admin user
final updateResult = await AdminManagementService.updateAdminUser(
  adminId: 1,
  adminType: 'barangay_admin',
  firstName: 'John',
  lastName: 'Doe',
  middleName: 'M',
  username: 'john.doe.updated',
);

// Delete admin user
final deleteResult = await AdminManagementService.deleteAdminUser(
  adminId: 1,
);
```

### Using Updated UserManagementService

The existing `UserManagementService` continues to work with the same interface but now uses the `admin_management.php` endpoint internally:

```dart
import 'package:login_app/services/user_management_service.dart';

// All existing code continues to work
final result = await UserManagementService.getAllAdminUsers();
final createResult = await UserManagementService.createAdminUser(
  adminType: 'admin',
  firstName: 'John',
  lastName: 'Doe',
  middleName: '',
  username: 'john.doe',
  password: 'password123',
);
```

## Validation

The new service includes built-in validation:

```dart
// Validate admin user data before creating
final validation = AdminManagementService.validateAdminUserData(
  adminType: 'admin',
  firstName: 'John',
  lastName: 'Doe',
  username: 'john.doe',
  password: 'password123',
);

if (validation['valid']) {
  // Proceed with creation
} else {
  print('Validation error: ${validation['message']}');
}
```

## Error Handling

Both services now provide consistent error handling that matches the PHP API:

### Common Error Codes
- `ADMINS_FETCHED`: Successfully fetched admin users
- `ADMIN_FETCHED`: Successfully fetched single admin user
- `ADMIN_CREATED`: Admin user created successfully
- `ADMIN_UPDATED`: Admin user updated successfully
- `ADMIN_DELETED`: Admin user deleted successfully
- `ADMIN_NOT_FOUND`: Admin user not found
- `USERNAME_EXISTS`: Username already exists
- `SUPER_ADMIN_NOT_ALLOWED`: Cannot modify super admin
- `MISSING_REQUIRED_FIELDS`: Required fields missing
- `INVALID_ADMIN_TYPE`: Invalid admin type provided
- `CONNECTION_ERROR`: Network/connection error
- `SERVER_ERROR`: Server-side error

## Security Features

The integration maintains all security features from the PHP API:

1. **Super Admin Protection**: Cannot create, update, or delete super admin users
2. **Username Uniqueness**: Prevents duplicate usernames
3. **Input Validation**: Server-side validation for all fields
4. **Password Hashing**: Passwords are hashed on the server side
5. **Admin Type Validation**: Only allows 'admin' and 'barangay_admin' types

## Migration Guide

If you're currently using the old service methods, no changes are required. The existing `UserManagementService` has been updated to use the new API endpoint while maintaining backward compatibility.

For new development, consider using the dedicated `AdminManagementService` for better type safety and cleaner code organization.

## Testing

To test the integration:

1. Ensure your PHP server has the `admin_management.php` file deployed
2. Update the `baseUrl` in the service files to match your server URL
3. Test each operation (GET, POST, PUT, DELETE) through the Flutter app
4. Verify that error responses are handled correctly
5. Check that the AdminUser model correctly parses the API responses

## Troubleshooting

### Common Issues

1. **404 Error**: Ensure `admin_management.php` is deployed and accessible
2. **JSON Parsing Error**: Check that the PHP API returns valid JSON
3. **CORS Issues**: Ensure the PHP API includes proper CORS headers
4. **Timeout Errors**: Check network connectivity and server response times

### Debug Mode

Both services include detailed logging. Enable debug prints to see:
- Request URLs and payloads
- Response status codes and bodies
- Error messages and stack traces

```dart
// Logs are automatically printed in debug mode
print('📊 AdminManagementService: Response Status: ${response.statusCode}');
print('📊 AdminManagementService: Response Body: ${response.body}');
```
