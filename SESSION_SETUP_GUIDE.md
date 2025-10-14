# Session Management Setup Guide

This guide will help you set up session management for your Flutter app with the PHP API.

## 📁 **Files Created**

I've created the following files for you:

### **PHP API Files:**
1. `check-session.php` - Check if user is logged in
2. `get-current-user.php` - Get current user data
3. `clear-session.php` - Logout user (clear session)
4. `session_helper.php` - Helper functions for session management
5. `consumer_login.php` - Updated consumer login with session creation

### **Database Files:**
1. `create_sessions_table.sql` - SQL to create sessions table

## 🗄️ **Database Setup**

### **Step 1: Create Sessions Table**

Run this SQL in your database:

```sql
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    user_type ENUM('consumer', 'retailer', 'admin') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    INDEX idx_session_id (session_id),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
);
```

### **Step 2: Optional Cleanup**

To automatically clean up expired sessions, you can also run:

```sql
-- Create cleanup procedure
DELIMITER //
CREATE PROCEDURE CleanupExpiredSessions()
BEGIN
    DELETE FROM user_sessions WHERE expires_at < NOW();
END //
DELIMITER ;

-- Create daily cleanup event (optional)
SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS cleanup_expired_sessions
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  CALL CleanupExpiredSessions();
```

## 📂 **File Placement**

Place all the PHP files in your API directory:

```
your-api-directory/
├── check-session.php
├── get-current-user.php
├── clear-session.php
├── session_helper.php
├── consumer_login.php
├── register.php (existing)
├── db_conn.php (existing)
└── ... (other existing files)
```

## 🔧 **How It Works**

### **Login Flow:**
1. User logs in with username/password
2. Server validates credentials
3. Server creates a session in `user_sessions` table
4. Server returns user data + session ID
5. Flutter app stores session ID for future requests

### **Session Check Flow:**
1. Flutter app sends session ID to `check-session.php`
2. Server checks if session exists and is not expired
3. Server returns login status

### **Get User Data Flow:**
1. Flutter app sends session ID to `get-current-user.php`
2. Server looks up user data based on session
3. Server returns user information

### **Logout Flow:**
1. Flutter app sends session ID to `clear-session.php`
2. Server deletes session from database
3. User is logged out

## 🚀 **Testing the Setup**

### **Test 1: Database Connection**

Create a test file `test_sessions.php`:

```php
<?php
require_once 'db_conn.php';
require_once 'session_helper.php';

try {
    $pdo = getDBConnection();
    if ($pdo) {
        echo "Database connection successful\n";
        
        // Test session creation
        $result = createUserSession($pdo, 1, 'consumer', 24);
        if ($result['success']) {
            echo "Session created: " . $result['session_id'] . "\n";
            echo "Expires at: " . $result['expires_at'] . "\n";
        } else {
            echo "Session creation failed: " . $result['error'] . "\n";
        }
    } else {
        echo "Database connection failed\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
```

### **Test 2: API Endpoints**

Test each endpoint with Postman or curl:

#### **Test Consumer Login:**
```bash
curl -X POST https://your-domain.com/api/consumer_login.php \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","password":"test_password"}'
```

#### **Test Session Check:**
```bash
curl -X GET "https://your-domain.com/api/check-session.php?session_id=YOUR_SESSION_ID"
```

#### **Test Get Current User:**
```bash
curl -X GET "https://your-domain.com/api/get-current-user.php?session_id=YOUR_SESSION_ID"
```

#### **Test Clear Session:**
```bash
curl -X POST https://your-domain.com/api/clear-session.php \
  -H "Content-Type: application/json" \
  -d '{"session_id":"YOUR_SESSION_ID"}'
```

## 🔄 **Update Your Flutter App**

Your Flutter app should now work with these endpoints. The existing `auth_service.dart` methods will work:

```dart
// Check if user is logged in
bool loggedIn = await AuthService.isLoggedIn();

// Get current user data
Map<String, dynamic>? user = await AuthService.getCurrentUser();

// Get user role
String? role = await AuthService.getUserRole();

// Logout
await AuthService.logout();
```

## 🛠️ **Customization Options**

### **Session Expiration**
You can change session duration by modifying the `createUserSession()` call:

```php
// 24 hours (default)
createUserSession($pdo, $userId, $userType, 24);

// 7 days
createUserSession($pdo, $userId, $userType, 168);

// 30 minutes
createUserSession($pdo, $userId, $userType, 0.5);
```

### **Session ID Format**
You can modify the session ID generation in `session_helper.php`:

```php
// Current: 64-character hex string
function generateSessionId() {
    return bin2hex(random_bytes(32));
}

// Alternative: UUID format
function generateSessionId() {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}
```

## 🔒 **Security Considerations**

1. **HTTPS Only**: Always use HTTPS in production
2. **Session Expiration**: Set appropriate expiration times
3. **Session Cleanup**: Regularly clean up expired sessions
4. **Rate Limiting**: Consider adding rate limiting to login endpoints
5. **Input Validation**: All inputs are validated and sanitized

## 🐛 **Troubleshooting**

### **Common Issues:**

1. **Database Connection Error**
   - Check `db_conn.php` configuration
   - Verify database credentials

2. **Session Not Created**
   - Check if `user_sessions` table exists
   - Verify user ID exists in respective tables

3. **Session Not Found**
   - Check if session ID is being passed correctly
   - Verify session hasn't expired

4. **CORS Issues**
   - Ensure CORS headers are set correctly
   - Check if preflight requests are handled

### **Debug Mode:**

Enable debug logging by adding this to your PHP files:

```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
```

## ✅ **Verification Checklist**

- [ ] Database table `user_sessions` created
- [ ] All PHP files uploaded to server
- [ ] Database connection working
- [ ] Consumer login creates session
- [ ] Session check returns correct status
- [ ] Get current user returns user data
- [ ] Clear session removes session
- [ ] Flutter app can use all methods

Your session management system is now ready! 🎉
