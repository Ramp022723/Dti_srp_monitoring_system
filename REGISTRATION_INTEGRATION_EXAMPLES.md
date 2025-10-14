# Registration Service Integration Examples

This document provides comprehensive examples of how to use the updated registration services that match your `register.php` API.

## Overview

The Flutter app now has two ways to handle registration:

1. **RegistrationService** - Dedicated service with full validation and type safety
2. **AuthService** - Updated to use the unified `register.php` endpoint with convenience methods

## API Response Format

Your `register.php` API returns responses in this format:

### Success Response
```json
{
  "status": "success",
  "message": "Consumer registration successful",
  "code": "CONSUMER_REGISTRATION_SUCCESS",
  "data": {
    "user": {
      "id": 123,
      "username": "john.doe",
      "role": "consumer",
      "created_at": "2025-01-27 10:30:00",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "middle_name": "M",
      "gender": "male",
      "birthdate": "1990-01-01",
      "age": 34,
      "location_id": 1
    }
  }
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Username already exists",
  "code": "USERNAME_EXISTS"
}
```

## Usage Examples

### 1. Using RegistrationService (Recommended)

#### Consumer Registration
```dart
import 'package:login_app/services/registration_service.dart';

// Register a consumer
final result = await RegistrationService.registerConsumer(
  username: 'john.doe',
  password: 'password123',
  confirmPassword: 'password123',
  email: 'john@example.com',
  firstName: 'John',
  lastName: 'Doe',
  middleName: 'Michael',
  gender: 'male',
  birthdate: '1990-01-01',
  age: 34,
  locationId: 1,
  phone: '+1234567890',
  bio: 'I am a consumer',
  profilePicture: 'https://example.com/profile.jpg',
);

if (result['status'] == 'success') {
  print('Consumer registered successfully!');
  print('User ID: ${result['data']['user']['id']}');
  print('Username: ${result['data']['user']['username']}');
} else {
  print('Registration failed: ${result['message']}');
  print('Error code: ${result['code']}');
}
```

#### Retailer Registration
```dart
// Register a retailer
final result = await RegistrationService.registerRetailer(
  username: 'store.owner',
  password: 'SecurePass123!',
  confirmPassword: 'SecurePass123!',
  registrationCode: '123456',
);

if (result['status'] == 'success') {
  print('Retailer registered successfully!');
  print('User ID: ${result['data']['user']['id']}');
  print('Store Name: ${result['data']['data']['profile_info']['store_name']}');
  print('Location: ${result['data']['data']['profile_info']['location']}');
} else {
  print('Registration failed: ${result['message']}');
  print('Error code: ${result['code']}');
}
```

#### Unified Registration
```dart
// Register using unified method
final consumerData = {
  'username': 'jane.doe',
  'password': 'password123',
  'confirm_password': 'password123',
  'email': 'jane@example.com',
  'first_name': 'Jane',
  'last_name': 'Doe',
  'middle_name': 'Marie',
  'gender': 'female',
  'birthdate': '1995-05-15',
  'age': 28,
  'location_id': 2,
};

final result = await RegistrationService.registerUser(
  userType: 'consumer',
  registrationData: consumerData,
);
```

### 2. Using AuthService (Backward Compatible)

#### Basic Registration
```dart
import 'package:login_app/services/auth_service.dart';

// Basic registration (backward compatible)
final result = await AuthService.createUser(
  username: 'basic.user',
  password: 'password123',
  name: 'Basic User',
  userType: 'consumer',
  email: 'basic@example.com',
  additionalData: {
    'confirm_password': 'password123',
    'first_name': 'Basic',
    'last_name': 'User',
    'middle_name': '',
    'gender': 'other',
    'birthdate': '1990-01-01',
    'age': '25',
    'location_id': '1',
  },
);
```

#### Enhanced Consumer Registration
```dart
// Enhanced consumer registration using AuthService
final result = await AuthService.registerConsumer(
  username: 'enhanced.consumer',
  password: 'password123',
  confirmPassword: 'password123',
  email: 'enhanced@example.com',
  firstName: 'Enhanced',
  lastName: 'Consumer',
  middleName: 'User',
  gender: 'male',
  birthdate: '1988-03-20',
  age: 35,
  locationId: 3,
  phone: '+1234567890',
  bio: 'Enhanced consumer user',
);
```

#### Enhanced Retailer Registration
```dart
// Enhanced retailer registration using AuthService
final result = await AuthService.registerRetailer(
  username: 'retail.store',
  password: 'RetailPass123!',
  confirmPassword: 'RetailPass123!',
  registrationCode: '654321',
);
```

## Error Handling

### Common Error Codes
- `MISSING_REQUIRED_FIELDS` - Required fields are missing
- `INVALID_EMAIL` - Invalid email format
- `WEAK_PASSWORD` - Password doesn't meet strength requirements
- `PASSWORD_MISMATCH` - Password and confirm password don't match
- `INVALID_GENDER` - Invalid gender value
- `INVALID_BIRTHDATE` - Invalid birthdate format
- `INVALID_AGE` - Age out of valid range (18-120)
- `INVALID_REGISTRATION_CODE_FORMAT` - Registration code not 6 digits
- `INVALID_REGISTRATION_CODE` - Registration code invalid/expired/used
- `USERNAME_EXISTS` - Username already taken
- `EMAIL_EXISTS` - Email already taken
- `INVALID_LOCATION_ID` - Location doesn't exist
- `CONNECTION_ERROR` - Network/connection error
- `SERVER_ERROR` - Server-side error

### Error Handling Example
```dart
try {
  final result = await RegistrationService.registerConsumer(
    username: 'test.user',
    password: 'weak',
    confirmPassword: 'weak',
    email: 'invalid-email',
    firstName: 'Test',
    lastName: 'User',
    middleName: '',
    gender: 'invalid',
    birthdate: 'invalid-date',
    age: 15,
    locationId: 999,
  );

  if (result['status'] == 'success') {
    // Handle success
    print('Registration successful!');
  } else {
    // Handle specific errors
    switch (result['code']) {
      case 'WEAK_PASSWORD':
        print('Password is too weak. Please use at least 6 characters.');
        break;
      case 'INVALID_EMAIL':
        print('Please enter a valid email address.');
        break;
      case 'PASSWORD_MISMATCH':
        print('Passwords do not match.');
        break;
      case 'INVALID_AGE':
        print('Age must be between 18 and 120.');
        break;
      case 'USERNAME_EXISTS':
        print('Username is already taken. Please choose another.');
        break;
      default:
        print('Registration failed: ${result['message']}');
    }
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Validation Features

### Consumer Validation
- Username, password, confirm password, email, first name, last name, gender, birthdate, age, location ID are required
- Password minimum 6 characters
- Email format validation
- Gender must be 'male', 'female', or 'other'
- Birthdate must be in YYYY-MM-DD format
- Age must be between 18 and 120
- Location ID must exist in database

### Retailer Validation
- Username, password, confirm password, registration code are required
- Password must be at least 8 characters with uppercase, number, and special character
- Registration code must be exactly 6 digits
- Registration code must be valid, unused, and not expired

## Testing

### Test Consumer Registration
```dart
void testConsumerRegistration() async {
  final result = await RegistrationService.registerConsumer(
    username: 'test.consumer.${DateTime.now().millisecondsSinceEpoch}',
    password: 'password123',
    confirmPassword: 'password123',
    email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
    firstName: 'Test',
    lastName: 'Consumer',
    middleName: 'User',
    gender: 'male',
    birthdate: '1990-01-01',
    age: 34,
    locationId: 1,
  );
  
  print('Test result: $result');
}
```

### Test Retailer Registration
```dart
void testRetailerRegistration() async {
  final result = await RegistrationService.registerRetailer(
    username: 'test.retailer.${DateTime.now().millisecondsSinceEpoch}',
    password: 'RetailPass123!',
    confirmPassword: 'RetailPass123!',
    registrationCode: '123456', // Use a valid code from your database
  );
  
  print('Test result: $result');
}
```

## Migration Guide

### From Old Registration Methods
If you're currently using the old registration methods, you can:

1. **Keep using existing code** - The `AuthService.createUser()` method has been updated to work with `register.php`
2. **Migrate to new methods** - Use `RegistrationService` or the enhanced `AuthService` methods for better validation and type safety

### Example Migration
```dart
// Old way (still works)
final result = await AuthService.createUser(
  username: 'user',
  password: 'pass',
  name: 'User Name',
  userType: 'consumer',
);

// New way (recommended)
final result = await AuthService.registerConsumer(
  username: 'user',
  password: 'pass',
  confirmPassword: 'pass',
  email: 'user@example.com',
  firstName: 'User',
  lastName: 'Name',
  middleName: '',
  gender: 'other',
  birthdate: '1990-01-01',
  age: 25,
  locationId: 1,
);
```

## Troubleshooting

### Common Issues

1. **404 Error**: Ensure `register.php` is deployed and accessible
2. **Validation Errors**: Check that all required fields are provided with correct formats
3. **Registration Code Issues**: Ensure the code exists in your database and hasn't been used
4. **Location ID Issues**: Verify the location exists in your location table
5. **Password Strength**: Retailers require stronger passwords than consumers

### Debug Mode
Both services include detailed logging. Check the console output for:
- Request URLs and payloads
- Response status codes and bodies
- Validation errors and stack traces

The integration is now complete and ready to use with your `register.php` API! 🚀
