import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _otpResponse;
  String? get otpResponse => _otpResponse;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  // Send OTP to mobile number
  Future<bool> sendOtp(String mobile, VoidCallback onSuccess) async {
    if (mobile.isEmpty || mobile.length < 10) {
      _errorMessage = "Please enter a valid mobile number";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$base_url/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);

          if (data != null && data['message'] != null) {
            debugPrint("OTP sent successfully: ${data['message']}");
            debugPrint("OTP: ${data['otp']}");

            _otpResponse = data['otp']?.toString();
            notifyListeners();
            onSuccess();
            return true;
          } else {
            _errorMessage = "Invalid response from server";
            notifyListeners();
            return false;
          }
        } else {
          _errorMessage = "Empty response from server";
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = "Failed to send OTP. Status: ${response.statusCode}";
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _errorMessage = errorData['message'] ?? _errorMessage;
          } catch (e) {
            debugPrint("Error parsing error response: $e");
          }
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Network error: ${e.toString()}";
      notifyListeners();
      debugPrint("Error sending OTP: $e");
      return false;
    }
  }

  // Google Sign-In with Firebase - OPTIMIZED VERSION
  Future<void> signInWithGoogle(
      Function(Map<String, dynamic>) onSuccess,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      await _auth.signOut();

      debugPrint("=== Starting Google Sign-In ===");

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        _errorMessage = "Google sign-in cancelled";
        notifyListeners();
        debugPrint("User cancelled Google sign-in");
        return;
      }

      debugPrint("✓ Google user signed in: ${googleUser.email}");

      // Get authentication details from Google
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      debugPrint("✓ Got Google Auth tokens");

      // Validate Google tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _isLoading = false;
        _errorMessage = "Failed to get Google authentication tokens";
        notifyListeners();
        debugPrint("✗ Missing Google tokens");
        return;
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("✓ Created Firebase credential");

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint("✓ Firebase sign-in successful");
      debugPrint("  User UID: ${userCredential.user?.uid}");
      debugPrint("  User Email: ${userCredential.user?.email}");

      // IMPROVED: Get fresh Firebase ID Token with retry mechanism
      String? firebaseIdToken;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries && firebaseIdToken == null) {
        try {
          // Wait before each attempt (increasing delay)
          if (retryCount > 0) {
            await Future.delayed(Duration(seconds: retryCount));
            debugPrint("  Retry attempt $retryCount...");
          }

          // Force refresh to get a fresh token
          firebaseIdToken = await userCredential.user?.getIdToken(true);

          if (firebaseIdToken != null) {
            debugPrint("✓ Firebase ID Token obtained on attempt ${retryCount + 1}");
            break;
          }
        } catch (e) {
          debugPrint("✗ Token retrieval attempt ${retryCount + 1} failed: $e");
          retryCount++;
        }
      }

      if (firebaseIdToken == null) {
        _isLoading = false;
        _errorMessage = "Failed to get Firebase ID token after $maxRetries attempts";
        notifyListeners();
        debugPrint("✗ Could not obtain Firebase token");
        return;
      }

      // Validate token format (JWT should have 3 parts separated by dots)
      final tokenParts = firebaseIdToken.split('.');
      if (tokenParts.length != 3) {
        _isLoading = false;
        _errorMessage = "Invalid token format received";
        notifyListeners();
        debugPrint("✗ Invalid token format: ${tokenParts.length} parts");
        return;
      }

      debugPrint("✓ Token validation passed");
      debugPrint("  Token length: ${firebaseIdToken.length}");
      debugPrint("  Token parts: ${tokenParts.length}");
      debugPrint("  Token preview: ${firebaseIdToken.substring(0, 50)}...");

      // Decode and log token payload for debugging
      try {
        final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1])));
        final payload = jsonDecode(payloadJson);
        debugPrint("  Token project: ${payload['aud']}"); // Should be 'moyo-159ed'
        debugPrint("  Token issuer: ${payload['iss']}");
        debugPrint("  Token email: ${payload['email']}");
      } catch (e) {
        debugPrint("  Could not decode token payload: $e");
      }

      // Prepare request body
      final requestBody = jsonEncode({
        'idToken': firebaseIdToken,
        'email': userCredential.user?.email,
        'displayName': userCredential.user?.displayName,
        'photoURL': userCredential.user?.photoURL,
        'uid': userCredential.user?.uid,
      });

      debugPrint("=== Sending request to backend ===");
      debugPrint("  URL: $base_url/api/auth/google-login");

      // Send Firebase ID Token to backend with timeout
      final response = await http
          .post(
        Uri.parse('$base_url/api/auth/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      )
          .timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Connection timeout - Server took too long to respond',
          );
        },
      );

      debugPrint("=== Backend Response ===");
      debugPrint("  Status: ${response.statusCode}");
      debugPrint("  Body: ${response.body}");

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          _errorMessage = "Empty response from server";
          notifyListeners();
          debugPrint("✗ Empty response body");
          return;
        }

        final data = jsonDecode(response.body);

        if (data == null) {
          _errorMessage = "Invalid response from server";
          notifyListeners();
          debugPrint("✗ Null data in response");
          return;
        }

        debugPrint("✓ Google login successful");

        // Extract token and user data
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (token == null || userData == null) {
          _errorMessage = "Missing token or user data in response";
          notifyListeners();
          debugPrint("✗ Token: $token, User: ${userData != null}");
          return;
        }

        // Save auth data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setInt('user_id', userData['id'] ?? 0);
        await prefs.setString('user_data', jsonEncode(userData));
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setBool('is_registered', userData['isregister'] ?? false);
        await prefs.setString('user_firstname', userData['firstname'] ?? '');
        await prefs.setString('user_lastname', userData['lastname'] ?? '');
        await prefs.setString('referral_code', userData['referral_code'] ?? '');
        await prefs.setBool('is_email_verified', userData['email_verified'] ?? false);

        debugPrint("✓ User data saved to SharedPreferences");

        // Check verification requirements
        final userMobile = userData['mobile'];
        final needsMobileVerification = (userMobile == null || userMobile.toString().isEmpty);
        final needsEmailVerification = !(userData['email_verified'] ?? false);

        debugPrint("  Mobile verification needed: $needsMobileVerification");
        debugPrint("  Email verification needed: $needsEmailVerification");

        // Call success callback
        onSuccess({
          ...data,
          'needsMobileVerification': needsMobileVerification,
          'needsEmailVerification': needsEmailVerification,
        });

        notifyListeners();
        debugPrint("=== Google Sign-In Complete ===");
        return;

      } else {
        // Handle error response
        _errorMessage = "Google login failed. Status: ${response.statusCode}";

        debugPrint("✗ Backend error: ${response.statusCode}");

        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _errorMessage = errorData['message'] ??
                errorData['error']?['message'] ??
                _errorMessage;
            debugPrint("  Error message: $_errorMessage");

            // Log detailed error for debugging
            if (errorData['error'] != null) {
              debugPrint("  Error details: ${errorData['error']}");
            }
          } catch (e) {
            debugPrint("  Error parsing error response: $e");
          }
        }

        notifyListeners();
        return;
      }

    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = "Firebase Auth error: ${e.message}";
      notifyListeners();
      debugPrint("✗ FirebaseAuthException: ${e.code} - ${e.message}");
      return;

    } on http.ClientException catch (e) {
      _isLoading = false;
      _errorMessage = "Network connection error: ${e.message}";
      notifyListeners();
      debugPrint("✗ HTTP ClientException: $e");
      return;

    } catch (e, stackTrace) {
      _isLoading = false;
      _errorMessage = "Google sign-in error: ${e.toString()}";
      notifyListeners();
      debugPrint("✗ Unexpected error: $e");
      debugPrint("Stack trace: $stackTrace");
      return;
    }
  }

  // Sign out from Google and Firebase
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_data');
      await prefs.remove('user_email');
      await prefs.remove('is_registered');
      await prefs.remove('user_firstname');
      await prefs.remove('user_lastname');
      await prefs.remove('referral_code');
      await prefs.remove('is_email_verified');

      debugPrint("✓ Google and Firebase sign-out successful");
      notifyListeners();
    } catch (e) {
      debugPrint("✗ Error signing out: $e");
    }
  }

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}