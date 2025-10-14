<?php
/**
 * Consumer Login API Endpoint
 * DTI 2025 API - Consumer Login with Session Management
 */

// Error reporting and output buffering
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ob_start();

// Set headers for API response
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, User-Agent');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database connection and session helper
require_once 'db_conn.php';
require_once 'session_helper.php';

// Function to send JSON response and exit
function sendLoginResponse($data, $httpCode = 200) {
    http_response_code($httpCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendLoginResponse([
        'status' => 'error',
        'message' => 'Method not allowed. Use POST method.',
        'code' => 'METHOD_NOT_ALLOWED'
    ], 405);
}

try {
    // Get raw input
    $input = file_get_contents('php://input');
    
    if (empty($input)) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'No data received',
            'code' => 'NO_DATA'
        ], 400);
    }
    
    // Parse JSON input
    $data = json_decode($input, true);
    
    if (!$data) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'Invalid JSON format',
            'code' => 'INVALID_JSON'
        ], 400);
    }
    
    // Extract and validate input data
    $username = trim($data['username'] ?? '');
    $password = trim($data['password'] ?? '');
    
    // Validation
    if (empty($username) || empty($password)) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'Username and password are required',
            'code' => 'MISSING_CREDENTIALS'
        ], 400);
    }
    
    // Get database connection
    $pdo = getDBConnection();
    
    if (!$pdo) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'Database connection failed',
            'code' => 'DB_CONNECTION_ERROR'
        ], 500);
    }
    
    // Check consumer credentials
    $query = "SELECT * FROM consumer WHERE username = ?";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$username]);
    $consumer = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$consumer) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'Invalid username or password',
            'code' => 'INVALID_CREDENTIALS'
        ], 401);
    }
    
    // Verify password
    if (!password_verify($password, $consumer['password'])) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'Invalid username or password',
            'code' => 'INVALID_CREDENTIALS'
        ], 401);
    }
    
    // Create session
    $sessionResult = createUserSession($pdo, $consumer['id'], 'consumer', 24);
    
    if (!$sessionResult['success']) {
        sendLoginResponse([
            'status' => 'error',
            'message' => 'Failed to create session: ' . $sessionResult['error'],
            'code' => 'SESSION_CREATION_FAILED'
        ], 500);
    }
    
    // Prepare user data for response
    $userData = [
        'id' => $consumer['id'],
        'username' => $consumer['username'],
        'email' => $consumer['email'],
        'first_name' => $consumer['first_name'],
        'last_name' => $consumer['last_name'],
        'middle_name' => $consumer['middle_name'],
        'gender' => $consumer['gender'],
        'birthdate' => $consumer['birthdate'],
        'age' => $consumer['age'],
        'location_id' => $consumer['location_id'],
        'role' => 'consumer',
        'created_at' => $consumer['created_at']
    ];
    
    // Return success response with session
    sendLoginResponse([
        'status' => 'success',
        'message' => 'Consumer login successful',
        'code' => 'CONSUMER_LOGIN_SUCCESS',
        'data' => [
            'user' => $userData,
            'session' => [
                'session_id' => $sessionResult['session_id'],
                'expires_at' => $sessionResult['expires_at']
            ]
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Consumer Login API Error: " . $e->getMessage());
    sendLoginResponse([
        'status' => 'error',
        'message' => 'Internal server error',
        'code' => 'SERVER_ERROR'
    ], 500);
}

// Clean up output buffer
ob_end_clean();
?>
