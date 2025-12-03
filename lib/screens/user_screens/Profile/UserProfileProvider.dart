// providers/user_profile_provider.dart

import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'UserProfileModel.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfileModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserProfileModel? get userProfile => _userProfile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasProfile => _userProfile != null;

  // Getters with null safety
  String get fullName => _userProfile?.fullName ?? 'User';

  String get email => _userProfile?.displayEmail ?? 'Not provided';

  String get mobile => _userProfile?.mobile ?? 'Not provided';

  String get address => _userProfile?.displayAddress ?? 'Not provided';

  String get profileImage => _userProfile?.displayImage ?? '';

  String get referralCode => _userProfile?.referralCode ?? '';

  double get walletBalance => _userProfile?.wallet ?? 0.0;

  bool get isRegistered => _userProfile?.isRegister ?? false;

  // Get auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Fetch user profile from API
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('$base_url/api/auth/profile');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['profile'] != null) {
          _userProfile = UserProfileModel.fromJson(data['profile']);
          _errorMessage = null;
        } else {
          throw Exception('Profile data not found in response');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Profile not found');
      } else {
        throw Exception(
          'Failed to load profile. Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _userProfile = null;
      print('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('$base_url/api/auth/profile');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        // Reload profile after successful update
        await loadUserProfile();
        return true;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear profile data (useful for logout)
  void clearProfile() {
    _userProfile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Refresh profile (same as loadUserProfile but can be called from UI)
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }
}
