// splash_screen_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SplashProvider with ChangeNotifier {
  bool _isCheckingSession = true;

  bool get isCheckingSession => _isCheckingSession;

  /// Initialize splash and check login session
  Future<void> initializeSplash(Function(String) onComplete) async {
    _isCheckingSession = true;
    notifyListeners();

    // Minimum splash duration for better UX (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    try {
      final navigationRoute = await _determineNavigationRoute();
      onComplete(navigationRoute);
    } catch (e) {
      print('Error checking session: $e');
      // On error, navigate to login for safety
      onComplete('/login');
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  /// Determine the appropriate navigation route based on session
  Future<String> _determineNavigationRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if customer auth token exists (main token)
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        // No session found, go to login
        return '/login';
      }

      // ADD THIS NEW CHECK - Check email verification status
      final isEmailVerified = prefs.getBool('is_email_verified') ?? false;

      if (!isEmailVerified) {
        // Email not verified, go to login
        print('Email not verified, navigating to login');
        return '/login';
      }

      // Get user role (defaults to customer if not set)
      final userRole = prefs.getString('user_role') ?? 'customer';

      print('Current user role: $userRole');

      if (userRole == 'provider') {
        // User last used provider mode
        final providerToken = prefs.getString('provider_auth_token');

        if (providerToken != null && providerToken.isNotEmpty) {
          // Valid provider session, go to provider dashboard
          print('Navigating to Provider Dashboard');
          return '/ProviderCustomBottomNav';
        } else {
          // Provider token missing, fall back to customer mode
          await prefs.setString('user_role', 'customer');
          print('Provider token missing, falling back to Customer Dashboard');
          return '/UserCustomBottomNav';
        }
      } else {
        // User last used customer mode, go to customer dashboard
        print('Navigating to Customer Dashboard');
        return '/UserCustomBottomNav';
      }
    } catch (e) {
      print('Error in _determineNavigationRoute: $e');
      return '/login';
    }
  }

  /// Clear user session (for logout)
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all session data
      await prefs.remove('auth_token');
      await prefs.remove('provider_auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('provider_id');
      await prefs.remove('is_registered');
      await prefs.remove('is_provider_registered');
      await prefs.remove('user_mobile');
      await prefs.remove('user_firstname');
      await prefs.remove('user_lastname');
      await prefs.remove('user_email');
      await prefs.remove('referral_code');
      await prefs.remove('is_email_verified');

      print('Session cleared successfully');
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  /// Get stored user session (customer data)
  Future<Map<String, dynamic>?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'token': prefs.getString('auth_token'),
        'userId': prefs.getInt('user_id'),
        'mobile': prefs.getString('user_mobile'),
        'isRegistered': prefs.getBool('is_registered'),
        'firstName': prefs.getString('user_firstname'),
        'lastName': prefs.getString('user_lastname'),
        'email': prefs.getString('user_email'),
        'referralCode': prefs.getString('referral_code'),
        'userRole': prefs.getString('user_role'),
        'isEmailVerified': prefs.getBool('is_email_verified'),
      };
    } catch (e) {
      print('Error getting user session: $e');
      return null;
    }
  }

  /// Get stored provider session data
  Future<Map<String, dynamic>?> getProviderSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'providerToken': prefs.getString('provider_auth_token'),
        'providerId': prefs.getInt('provider_id'),
        'isProviderRegistered': prefs.getBool('is_provider_registered'),
        'userRole': prefs.getString('user_role'),
      };
    } catch (e) {
      print('Error getting provider session: $e');
      return null;
    }
  }

  /// Get current user role
  Future<String> getCurrentRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role') ?? 'customer';
    } catch (e) {
      print('Error getting current role: $e');
      return 'customer';
    }
  }

  /// Check if user is currently in provider mode
  Future<bool> isProviderMode() async {
    try {
      final role = await getCurrentRole();
      return role == 'provider';
    } catch (e) {
      return false;
    }
  }
}
