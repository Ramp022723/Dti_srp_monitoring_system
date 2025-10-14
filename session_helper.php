<?php
/**
 * Session Helper Functions
 * DTI 2025 API - Helper functions for session management
 */

// Function to generate a unique session ID
function generateSessionId() {
    return bin2hex(random_bytes(32));
}

// Function to create a user session
function createUserSession($pdo, $userId, $userType, $expirationHours = 24) {
    try {
        // Generate unique session ID
        $sessionId = generateSessionId();
        
        // Calculate expiration time
        $expiresAt = date('Y-m-d H:i:s', strtotime("+{$expirationHours} hours"));
        
        // Insert session into database
        $query = "INSERT INTO user_sessions (session_id, user_id, user_type, expires_at) VALUES (?, ?, ?, ?)";
        $stmt = $pdo->prepare($query);
        $result = $stmt->execute([$sessionId, $userId, $userType, $expiresAt]);
        
        if ($result) {
            return [
                'success' => true,
                'session_id' => $sessionId,
                'expires_at' => $expiresAt
            ];
        } else {
            return [
                'success' => false,
                'error' => 'Failed to create session'
            ];
        }
    } catch (Exception $e) {
        error_log("Session creation error: " . $e->getMessage());
        return [
            'success' => false,
            'error' => 'Session creation failed: ' . $e->getMessage()
        ];
    }
}

// Function to validate a session
function validateSession($pdo, $sessionId) {
    try {
        $query = "SELECT * FROM user_sessions WHERE session_id = ? AND expires_at > NOW()";
        $stmt = $pdo->prepare($query);
        $stmt->execute([$sessionId]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($session) {
            return [
                'valid' => true,
                'session' => $session
            ];
        } else {
            return [
                'valid' => false,
                'error' => 'Session not found or expired'
            ];
        }
    } catch (Exception $e) {
        error_log("Session validation error: " . $e->getMessage());
        return [
            'valid' => false,
            'error' => 'Session validation failed: ' . $e->getMessage()
        ];
    }
}

// Function to clear a session
function clearSession($pdo, $sessionId) {
    try {
        $query = "DELETE FROM user_sessions WHERE session_id = ?";
        $stmt = $pdo->prepare($query);
        $result = $stmt->execute([$sessionId]);
        
        return [
            'success' => $result,
            'message' => $result ? 'Session cleared successfully' : 'Failed to clear session'
        ];
    } catch (Exception $e) {
        error_log("Session clear error: " . $e->getMessage());
        return [
            'success' => false,
            'error' => 'Session clear failed: ' . $e->getMessage()
        ];
    }
}

// Function to get user data by session
function getUserBySession($pdo, $sessionId) {
    try {
        $query = "SELECT s.*, u.*, u.id as user_id 
                  FROM user_sessions s 
                  JOIN (
                      SELECT id, username, email, first_name, last_name, middle_name, 'consumer' as role, gender, birthdate, age, location_id, created_at
                      FROM consumer
                      UNION ALL
                      SELECT id, username, email, first_name, last_name, middle_name, 'retailer' as role, NULL as gender, NULL as birthdate, NULL as age, location_id, created_at
                      FROM retailer
                      UNION ALL
                      SELECT admin_id as id, username, '' as email, first_name, last_name, middle_name, admin_type as role, NULL as gender, NULL as birthdate, NULL as age, NULL as location_id, NOW() as created_at
                      FROM admin
                  ) u ON s.user_id = u.id
                  WHERE s.session_id = ? AND s.expires_at > NOW()";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute([$sessionId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result) {
            $user = [
                'id' => $result['user_id'],
                'username' => $result['username'],
                'email' => $result['email'] ?? '',
                'first_name' => $result['first_name'],
                'last_name' => $result['last_name'],
                'middle_name' => $result['middle_name'] ?? '',
                'role' => $result['role'],
                'created_at' => $result['created_at']
            ];
            
            // Add role-specific fields
            if ($result['role'] === 'consumer') {
                $user['gender'] = $result['gender'];
                $user['birthdate'] = $result['birthdate'];
                $user['age'] = $result['age'];
                $user['location_id'] = $result['location_id'];
            } elseif ($result['role'] === 'retailer') {
                $user['location_id'] = $result['location_id'];
            }
            
            return [
                'success' => true,
                'user' => $user
            ];
        } else {
            return [
                'success' => false,
                'error' => 'User not found or session expired'
            ];
        }
    } catch (Exception $e) {
        error_log("Get user by session error: " . $e->getMessage());
        return [
            'success' => false,
            'error' => 'Failed to get user: ' . $e->getMessage()
        ];
    }
}
?>
