// otp_screen_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpScreenProvider extends ChangeNotifier {
  bool isLoading = false;
  String otp = "";
  String? errorMessage;
  int _secondsRemaining = 30;
  Timer? _timer;

  // Email verification states
  bool isEmailOtpLoading = false;
  bool isEmailOtpVerifying = false;
  bool emailOtpSent = false;
  String? emailErrorMessage;

  // Device token state
  bool isUpdatingDeviceToken = false;

  int get secondsRemaining => _secondsRemaining;

  bool get canResend => _secondsRemaining == 0 && !isLoading;

  void setOtp(String value) {
    otp = value;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  /// Start or restart 30s timer
  void startTimer() {
    _secondsRemaining = 30;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        notifyListeners();
      }
    });
  }

  /// API call to verify OTP
  Future<Map<String, dynamic>?> _verifyOtpApi({
    required String mobile,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('$base_url/api/auth/verify-otp');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Verify mobile OTP for Google login users (only updates mobile, doesn't replace token)
  Future<Map<String, dynamic>?> verifyMobileOnly({
    required String mobile,
    required String otp,
    required BuildContext context,
  }) async {
    if (otp.isEmpty || otp.length != 6) {
      errorMessage = "Please enter a valid 6-digit OTP";
      notifyListeners();
      return null;
    }

    if (mobile.isEmpty) {
      errorMessage = "Mobile number is required";
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Call verify OTP API
      final url = Uri.parse('$base_url/api/auth/verify-otp');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );

      print('Verify mobile OTP response status: ${response.statusCode}');
      print('Verify mobile OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['user'] as Map<String, dynamic>?;

        if (userData != null) {
          // Get existing token from SharedPreferences (Google login token)
          final prefs = await SharedPreferences.getInstance();
          final existingToken = prefs.getString('auth_token');

          if (existingToken == null || existingToken.isEmpty) {
            errorMessage =
                "Authentication token not found. Please login again.";
            isLoading = false;
            notifyListeners();
            return null;
          }

          print("Existing token found: ${existingToken.substring(0, 20)}...");
          print("Updating mobile in user data...");

          // Update only mobile-related data, keep the existing Google token
          await prefs.setString('user_mobile', mobile);

          // Update user_data with new mobile info
          final userDataString = prefs.getString('user_data');
          Map<String, dynamic> existingUserData = {};

          if (userDataString != null && userDataString.isNotEmpty) {
            existingUserData =
                jsonDecode(userDataString) as Map<String, dynamic>;
          }

          // Merge new mobile data with existing user data
          existingUserData['mobile'] = mobile;

          // Save is_referred status from response
          if (userData['is_referred'] != null) {
            existingUserData['is_referred'] = userData['is_referred'];
            await prefs.setBool(
              'is_referred',
              userData['is_referred'] ?? false,
            );
          }

          // Also update email verification status from response
          if (userData['email_verified'] != null) {
            existingUserData['email_verified'] = userData['email_verified'];
            await prefs.setBool(
              'is_email_verified',
              userData['email_verified'] ?? false,
            );
          }

          if (userData['email'] != null) {
            existingUserData['email'] = userData['email'];
            await prefs.setString('user_email', userData['email']);
          }

          // Save updated user data
          await prefs.setString('user_data', jsonEncode(existingUserData));

          print("Mobile verified and updated successfully");
          print("Updated user data: $existingUserData");

          isLoading = false;
          notifyListeners();

          // Check if email verification is needed
          final isEmailVerified = userData['email_verified'] ?? false;
          final isReferred = userData['is_referred'] ?? false;

          return {
            'success': true,
            'needsEmailVerification': !isEmailVerified,
            'needsReferralCode': !isReferred,
            'userEmail': userData['email'],
          };
        } else {
          errorMessage = "Invalid response from server";
          isLoading = false;
          notifyListeners();
          return null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? 'OTP verification failed';
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      print('Error verifying mobile OTP: $e');
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Save authentication data to SharedPreferences
  Future<bool> _saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', token);
      await prefs.setInt('user_id', userData['id'] ?? 0);
      await prefs.setString('user_data', jsonEncode(userData));
      await prefs.setString('user_mobile', userData['mobile'] ?? '');
      await prefs.setBool('is_registered', userData['isregister'] ?? false);
      await prefs.setString('user_firstname', userData['firstname'] ?? '');
      await prefs.setString('user_lastname', userData['lastname'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('referral_code', userData['referral_code'] ?? '');
      await prefs.setBool(
        'is_email_verified',
        userData['is_email_verified'] ?? false,
      );
      await prefs.setBool('is_referred', userData['is_referred'] ?? false);

      return true;
    } catch (e) {
      print('Error saving auth data: $e');
      return false;
    }
  }

  /// Update user device token
  Future<bool> updateDeviceToken({required String deviceToken}) async {
    if (deviceToken.isEmpty) {
      print('Device token is empty');
      return false;
    }

    isUpdatingDeviceToken = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print('Authentication token not found');
        isUpdatingDeviceToken = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/user-device-token');

      print('Updating device token...');
      print('Using token: ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'deviceToken': deviceToken}),
      );

      print('Update device token response status: ${response.statusCode}');
      print('Update device token response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] ==
            'User device token updated successfully') {
          // Save device token to SharedPreferences
          await prefs.setString('device_token', deviceToken);

          isUpdatingDeviceToken = false;
          notifyListeners();
          print('Device token updated successfully');
          return true;
        } else {
          print('Unexpected response: ${responseData['message']}');
          isUpdatingDeviceToken = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Failed to update device token: ${errorData['message']}');
        isUpdatingDeviceToken = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error updating device token: $e');
      isUpdatingDeviceToken = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP with API and save data
  /// Returns a map with success status, needsEmailVerification, and needsReferralCode flags
  Future<Map<String, dynamic>?> verifyOtp({
    required String mobile,
    required String otp,
    required BuildContext context,
  }) async {
    if (otp.isEmpty || otp.length != 6) {
      errorMessage = "Please enter a valid 6-digit OTP";
      notifyListeners();
      return null;
    }

    if (mobile.isEmpty) {
      errorMessage = "Mobile number is required";
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _verifyOtpApi(mobile: mobile, otp: otp);

      if (response != null) {
        final token = response['token'] as String?;
        final userData = response['user'] as Map<String, dynamic>?;

        if (token != null && token.isNotEmpty && userData != null) {
          final saved = await _saveAuthData(token: token, userData: userData);

          if (saved) {
            isLoading = false;
            notifyListeners();

            // Check if email verification is needed
            final isEmailVerified = userData['is_email_verified'] ?? false;
            // Check if referral code is needed
            final isReferred = userData['is_referred'] ?? false;

            return {
              'success': true,
              'needsEmailVerification': !isEmailVerified,
              'needsReferralCode': !isReferred,
              'userEmail': userData['email'],
            };
          } else {
            errorMessage = "Failed to save user data";
            isLoading = false;
            notifyListeners();
            return null;
          }
        } else {
          errorMessage = "Invalid response from server";
          isLoading = false;
          notifyListeners();
          return null;
        }
      } else {
        errorMessage = "Failed to verify OTP";
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Send OTP to email for verification
  Future<bool> sendEmailOtp({required String email}) async {
    if (email.isEmpty || !email.contains('@')) {
      emailErrorMessage = "Please enter a valid email address";
      notifyListeners();
      return false;
    }

    isEmailOtpLoading = true;
    emailErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        emailErrorMessage =
            "Authentication token not found. Please login again.";
        isEmailOtpLoading = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/send-email-otp');

      print('Sending email OTP to: $email');
      print('Using token: ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      );

      print('Send email OTP response status: ${response.statusCode}');
      print('Send email OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] == 'OTP sent to email') {
          emailOtpSent = true;
          isEmailOtpLoading = false;
          notifyListeners();
          return true;
        } else {
          emailErrorMessage =
              responseData['message'] ?? "Unexpected response from server";
          isEmailOtpLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        emailErrorMessage = errorData['message'] ?? "Failed to send email OTP";
        isEmailOtpLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error sending email OTP: $e');
      emailErrorMessage = "Network error. Please check your connection.";
      isEmailOtpLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify email OTP
  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    if (otp.isEmpty || otp.length != 6) {
      emailErrorMessage = "Please enter a valid 6-digit OTP";
      notifyListeners();
      return false;
    }

    if (email.isEmpty || !email.contains('@')) {
      emailErrorMessage = "Please enter a valid email address";
      notifyListeners();
      return false;
    }

    isEmailOtpVerifying = true;
    emailErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        emailErrorMessage =
            "Authentication token not found. Please login again.";
        isEmailOtpVerifying = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/verify-email-otp');

      print('Verifying email OTP for: $email');
      print('OTP: $otp');
      print('Using token: ${token.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('Verify email OTP response status: ${response.statusCode}');
      print('Verify email OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] == 'Email verified successfully') {
          // Update email verification status in SharedPreferences
          await prefs.setBool('is_email_verified', true);
          await prefs.setString('user_email', email);

          // Update user data if stored
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            userData['is_email_verified'] = true;
            userData['email'] = email;
            await prefs.setString('user_data', jsonEncode(userData));
          }

          isEmailOtpVerifying = false;
          emailOtpSent = false;
          notifyListeners();
          return true;
        } else {
          emailErrorMessage =
              responseData['message'] ?? "Unexpected response from server";
          isEmailOtpVerifying = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        emailErrorMessage =
            errorData['message'] ?? "Invalid OTP. Please try again.";
        isEmailOtpVerifying = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error verifying email OTP: $e');
      emailErrorMessage = "Network error. Please check your connection.";
      isEmailOtpVerifying = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend OTP
  Future<void> resendOtp({String? mobile}) async {
    if (!canResend) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$base_url/api/auth/send-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );

      if (response.statusCode == 200) {
        isLoading = false;
        notifyListeners();
        startTimer();
      } else {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? "Failed to resend OTP";
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Failed to resend OTP";
      isLoading = false;
      notifyListeners();
    }
  }

  /// Resend Email OTP
  Future<void> resendEmailOtp({required String email}) async {
    await sendEmailOtp(email: email);
  }

  /// Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  /// Get stored user ID
  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_id');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null && userDataString.isNotEmpty) {
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Check if user is registered
  Future<bool> isUserRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_registered') ?? false;
    } catch (e) {
      print('Error checking registration: $e');
      return false;
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_email_verified') ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  /// Check if user has entered referral code
  Future<bool> isReferred() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_referred') ?? false;
    } catch (e) {
      print('Error checking referral status: $e');
      return false;
    }
  }

  /// Clear all stored data (for logout)
  Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_data');
      await prefs.remove('user_mobile');
      await prefs.remove('is_registered');
      await prefs.remove('user_firstname');
      await prefs.remove('user_lastname');
      await prefs.remove('user_email');
      await prefs.remove('referral_code');
      await prefs.remove('is_email_verified');
      await prefs.remove('is_referred');
      await prefs.remove('device_token');
      return true;
    } catch (e) {
      print('Error clearing auth data: $e');
      return false;
    }
  }

  /// Reset email verification state
  void resetEmailVerificationState() {
    emailOtpSent = false;
    isEmailOtpLoading = false;
    isEmailOtpVerifying = false;
    emailErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
