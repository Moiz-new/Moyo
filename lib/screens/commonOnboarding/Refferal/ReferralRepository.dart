// lib/repositories/referral_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ReferralResponseModel.dart';

class ReferralRepository {
  final String baseUrl = 'https://api.moyointernational.com/api';

  // SharedPreferences se token fetch karein
  Future<String> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      print('Retrieved Token: $token'); // Debug ke liye
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return '';
    }
  }

  Future<ReferralResponseModel> applyReferralCode(String referralCode) async {
    try {
      final token = await _getAuthToken();

      if (token.isEmpty) {
        return ReferralResponseModel(
          message: 'Authentication token not found. Please login again.',
        );
      }

      print('Making API call to: $baseUrl/referral/apply');
      print('Referral Code: $referralCode');

      final response = await http.post(
        Uri.parse('$baseUrl/referral/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'referral_code': referralCode,
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ReferralResponseModel.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        // Bad request - Invalid referral code
        try {
          final jsonData = jsonDecode(response.body);
          return ReferralResponseModel(
            message: jsonData['message'] ?? 'Invalid referral code',
          );
        } catch (e) {
          return ReferralResponseModel(
            message: 'Invalid referral code',
          );
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - Token expired
        return ReferralResponseModel(
          message: 'Session expired. Please login again.',
        );
      } else if (response.statusCode == 409) {
        // Conflict - Already used referral code
        try {
          final jsonData = jsonDecode(response.body);
          return ReferralResponseModel(
            message: jsonData['message'] ?? 'Referral code already used',
          );
        } catch (e) {
          return ReferralResponseModel(
            message: 'Referral code already used',
          );
        }
      } else {
        // Other errors
        try {
          final jsonData = jsonDecode(response.body);
          return ReferralResponseModel(
            message: jsonData['message'] ?? 'Failed to apply referral code',
          );
        } catch (e) {
          return ReferralResponseModel(
            message: 'Server error: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('Error in applyReferralCode: $e');
      return ReferralResponseModel(
        message: 'Network error. Please check your internet connection.',
      );
    }
  }
}