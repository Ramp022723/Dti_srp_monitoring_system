# Registration Debug Guide

This guide will help you identify and fix why registration data isn't being stored in the database.

## Quick Debug Steps

### 1. **Run the Debug Service**

Add this to your app to test registration:

```dart
import 'package:login_app/services/registration_debug_service.dart';

// Test API connectivity
final connectivityResult = await RegistrationDebugService.testApiConnectivity();
print('Connectivity Test: $connectivityResult');

// Test consumer registration
final consumerResult = await RegistrationDebugService.testConsumerRegistration();
print('Consumer Test: $consumerResult');

// Test retailer registration  
final retailerResult = await RegistrationDebugService.testRetailerRegistration();
print('Retailer Test: $retailerResult');
```

### 2. **Check Console Logs**

The updated registration service now includes detailed logging. Look for these in your console:

```
📝 RegistrationService: Registering consumer - username
📤 RegistrationService: Request body: {...}
📊 RegistrationService: CONSUMER Response Status: 200
📊 RegistrationService: CONSUMER Response Body: {...}
🔍 RegistrationService: Processing response for consumer
✅ RegistrationService: Registration successful for consumer
```

## Common Issues and Solutions

### Issue 1: API Endpoint Not Found (404 Error)

**Symptoms:**
- HTTP 404 response
- "API endpoint not found" message

**Solutions:**
1. **Check URL**: Ensure `register.php` is in the correct directory
2. **Check server**: Verify your PHP server is running
3. **Check path**: Make sure the file path is correct

```dart
// Current URL being used
static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";
static const String registerEndpoint = "register.php";
// Full URL: https://dtisrpmonitoring.bccbsis.com/api/register.php
```

### Issue 2: Server Error (500 Error)

**Symptoms:**
- HTTP 500 response
- "Internal server error" message

**Solutions:**
1. **Check PHP logs**: Look at your server error logs
2. **Check database connection**: Ensure `db_conn.php` is working
3. **Check PHP syntax**: Validate your `register.php` file

### Issue 3: Validation Errors (400 Error)

**Symptoms:**
- HTTP 400 response
- "Missing required fields" or validation error messages

**Solutions:**
1. **Check required fields**: Ensure all required fields are provided
2. **Check data format**: Verify data types and formats match PHP expectations
3. **Check validation rules**: Ensure data passes PHP validation

### Issue 4: Database Insert Fails

**Symptoms:**
- HTTP 200 response with success message
- But data not appearing in database

**Solutions:**
1. **Check database connection**: Verify database is accessible
2. **Check table structure**: Ensure tables exist and have correct columns
3. **Check permissions**: Verify database user has INSERT permissions
4. **Check PHP logs**: Look for database error messages

## Debugging Checklist

### ✅ **Step 1: Verify API Endpoint**

Test if your API is reachable:

```dart
// Test basic connectivity
final result = await RegistrationDebugService.testApiConnectivity();
print('API Status: ${result['status']}');
print('Response: ${result['post_response']}');
```

**Expected Result:**
- Status: 200
- Response contains JSON with status field

### ✅ **Step 2: Test Consumer Registration**

```dart
// Test consumer registration
final result = await RegistrationDebugService.testConsumerRegistration();
print('Consumer Test: ${result['is_success']}');
print('Response: ${result['response_body']}');
```

**Expected Result:**
- `is_success`: true
- Response contains user data with ID

### ✅ **Step 3: Test Retailer Registration**

```dart
// Test retailer registration (use valid registration code)
final result = await RegistrationDebugService.testRetailerRegistration(
  customRegistrationCode: '123456', // Use a valid code from your database
);
print('Retailer Test: ${result['is_success']}');
print('Response: ${result['response_body']}');
```

**Expected Result:**
- `is_success`: true
- Response contains user data with ID

### ✅ **Step 4: Check Database**

After successful registration, check your database:

```sql
-- Check consumer table
SELECT * FROM consumer ORDER BY id DESC LIMIT 5;

-- Check retailer table  
SELECT * FROM retailer ORDER BY id DESC LIMIT 5;

-- Check if registration codes are being marked as used
SELECT * FROM retailer_registration_codes WHERE used = 1 ORDER BY id DESC LIMIT 5;
```

## Detailed Debugging

### **Enable Detailed Logging**

The registration service now includes comprehensive logging. Check your console for:

1. **Request Details:**
   ```
   📤 RegistrationService: Request body: {...}
   ```

2. **Response Details:**
   ```
   📊 RegistrationService: CONSUMER Response Status: 200
   📊 RegistrationService: CONSUMER Response Body: {...}
   ```

3. **Processing Details:**
   ```
   🔍 RegistrationService: Processing response for consumer
   🔍 RegistrationService: Status Code: 200
   🔍 RegistrationService: Response Body: {...}
   ```

### **Check Response Format**

Your PHP API should return this format:

```json
{
  "status": "success",
  "message": "Consumer registration successful",
  "code": "CONSUMER_REGISTRATION_SUCCESS",
  "data": {
    "user": {
      "id": 123,
      "username": "test.user",
      "role": "consumer",
      "created_at": "2025-01-27 10:30:00",
      "email": "test@example.com",
      "first_name": "Test",
      "last_name": "User"
    }
  }
}
```

### **Common Response Issues**

1. **Empty Response Body:**
   - Check if PHP script is running
   - Check for PHP errors
   - Verify file permissions

2. **HTML Instead of JSON:**
   - Check for PHP errors before JSON output
   - Ensure no whitespace before `<?php`
   - Check for echo/print statements

3. **Invalid JSON:**
   - Check for extra characters in response
   - Verify JSON encoding
   - Check for encoding issues

## Testing with Postman

### **Test Consumer Registration**

**URL:** `POST https://dtisrpmonitoring.bccbsis.com/api/register.php`

**Headers:**
```
Content-Type: application/json
Accept: application/json
User-Agent: login_app/1.0
```

**Body:**
```json
{
  "user_type": "consumer",
  "username": "test.consumer",
  "password": "password123",
  "confirm_password": "password123",
  "email": "test@example.com",
  "first_name": "Test",
  "last_name": "Consumer",
  "middle_name": "",
  "gender": "other",
  "birthdate": "1990-01-01",
  "age": "25",
  "location_id": "1"
}
```

### **Test Retailer Registration**

**URL:** `POST https://dtisrpmonitoring.bccbsis.com/api/register.php`

**Headers:**
```
Content-Type: application/json
Accept: application/json
User-Agent: login_app/1.0
```

**Body:**
```json
{
  "user_type": "retailer",
  "username": "test.retailer",
  "password": "RetailPass123!",
  "confirm_password": "RetailPass123!",
  "registration_code": "123456"
}
```

## Troubleshooting Steps

### **1. Check Server Logs**

Look at your PHP server error logs for:
- Database connection errors
- SQL syntax errors
- PHP fatal errors
- Permission errors

### **2. Test Database Connection**

Create a simple test script:

```php
<?php
require_once 'db_conn.php';

try {
    $pdo = getDBConnection();
    if ($pdo) {
        echo "Database connection successful\n";
        
        // Test insert
        $stmt = $pdo->prepare("INSERT INTO consumer (username, password, email, first_name, last_name, gender, birthdate, age, location_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $result = $stmt->execute(['test', 'password', 'test@example.com', 'Test', 'User', 'other', '1990-01-01', 25, 1]);
        
        if ($result) {
            echo "Test insert successful\n";
            echo "New ID: " . $pdo->lastInsertId() . "\n";
        } else {
            echo "Test insert failed\n";
        }
    } else {
        echo "Database connection failed\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
```

### **3. Check Table Structure**

Verify your database tables have the correct structure:

```sql
-- Check consumer table structure
DESCRIBE consumer;

-- Check retailer table structure  
DESCRIBE retailer;

-- Check location table
DESCRIBE location;

-- Check retailer_registration_codes table
DESCRIBE retailer_registration_codes;
```

### **4. Check Registration Codes**

For retailer registration, ensure you have valid registration codes:

```sql
-- Check available registration codes
SELECT * FROM retailer_registration_codes WHERE used = 0 AND expires_at > NOW();

-- Check if a specific code exists
SELECT * FROM retailer_registration_codes WHERE code = '123456';
```

## Quick Fixes

### **Fix 1: Update Base URL**

If your API is on a different server:

```dart
// In registration_service.dart
static const String baseUrl = "https://your-actual-server.com/api";
```

### **Fix 2: Check File Path**

Ensure `register.php` is in the correct directory:

```
https://dtisrpmonitoring.bccbsis.com/api/register.php
```

### **Fix 3: Enable Error Reporting**

In your `register.php`, temporarily add:

```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

### **Fix 4: Check CORS Headers**

Ensure your PHP API has proper CORS headers:

```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, User-Agent');
```

## Still Having Issues?

If you're still experiencing problems:

1. **Run the comprehensive debug test:**
   ```dart
   final results = await RegistrationDebugService.runComprehensiveTests();
   print('Debug Results: $results');
   ```

2. **Check the debug page** in your app (if you added it to your navigation)

3. **Share the console logs** - the detailed logging will show exactly what's happening

4. **Test with Postman first** - this will help isolate if it's a Flutter or server issue

The registration service is now equipped with comprehensive debugging capabilities that will help you identify exactly where the issue is occurring! 🔍
