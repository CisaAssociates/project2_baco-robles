<?php
session_start();
require_once 'db_connect.php';

// Check if user is logged in
function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

// Check if user has admin role
function isAdmin() {
    return isset($_SESSION['role']) && $_SESSION['role'] === 'admin';
}

// Authenticate user
function authenticate() {
    if (!isLoggedIn()) {
        header('Location: ../auth/login.php');
        exit();
    }
}

// Log out user
function logout() {

    if (!isLoggedIn()) {
        return false;
    }

    session_destroy();
    session_regenerate_id();
    session_unset();
    header('Location: ../auth/login.php');
    exit();
}

// Get current user
function getCurrentUser() {
    if (!isLoggedIn()) {
        return null;
    }
    
    try {
        global $db;
        $stmt = $db->prepare("SELECT id, username, role FROM users WHERE id = ?");
        $stmt->execute([$_SESSION['user_id']]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error getting current user: " . $e->getMessage());
        return null;
    }
}

// Check if user has permission for a route
function hasPermission($route) {
    $user = getCurrentUser();
    if (!$user) {
        return false;
    }
    
    // Admin has access to all routes
    if ($user['role'] === 'admin') {
        return true;
    }
    
    // Define route permissions
    $permissions = [
        'dashboard' => ['user', 'admin'],
        'devices' => ['user', 'admin'],
        'species' => ['user', 'admin'],
        'users' => ['admin'],
        'settings' => ['admin']
    ];
    
    return in_array($user['role'], $permissions[$route] ?? []);
}

// Add authentication middleware to routes
function protectRoute($route) {
    authenticate();
    
    if (!hasPermission($route)) {
        header('Location: dashboard/index.php');
        exit();
    }
}
?>
