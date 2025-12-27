import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// ==================== MODELS ====================

/// Rating Reason Model
class RatingReason {
  final int id;
  final String reason;

  RatingReason({
    required this.id,
    required this.reason,
  });

  factory RatingReason.fromJson(Map<String, dynamic> json) {
    return RatingReason(
      id: json['id'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

/// Rating Response Model
class RatingResponse {
  final bool success;
  final String? message;
  final dynamic data;

  RatingResponse({required this.success, this.message, this.data});

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: json['data'],
    );
  }
}

// ==================== PROVIDER ====================

/// Provider for managing rating reasons
class RatingReasonsProvider extends ChangeNotifier {
  List<RatingReason> _reasons = [];
  bool _isLoading = false;
  String? _error;
  Map<int, List<RatingReason>> _reasonsByRating = {};

  List<RatingReason> get reasons => _reasons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get cached reasons for specific rating
  List<RatingReason> getReasonsForRating(int rating) {
    return _reasonsByRating[rating] ?? [];
  }

  /// Fetch rating reasons from API
  Future<void> fetchRatingReasons(int rating) async {
    // Return cached data if available
    if (_reasonsByRating.containsKey(rating) &&
        _reasonsByRating[rating]!.isNotEmpty) {
      _reasons = _reasonsByRating[rating]!;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 Fetching reasons for rating: $rating');
      final response = await http.get(
        Uri.parse('https://api.moyointernational.com/api/rating/public/$rating'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Reasons response: ${response.statusCode}');
      print('📥 Reasons body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _reasons = data.map((json) => RatingReason.fromJson(json)).toList();
        _reasonsByRating[rating] = _reasons;
        _error = null;
        print('✅ Loaded ${_reasons.length} reasons');
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching reasons: $e');
      _error = e.toString();
      _reasons = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear current reasons
  void clearReasons() {
    _reasons = [];
    _error = null;
    notifyListeners();
  }

  /// Reset all data
  void reset() {
    _reasons = [];
    _reasonsByRating.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

// ==================== API ====================

/// Rating API service
class RatingAPI {
  static const String baseUrl = 'https://api.moyointernational.com';

  /// Get authentication token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// Submit rating to API
  static Future<RatingResponse> submitRating({
    required String serviceId,
    required int rating,
    required String review,
    required String providerId,
  }) async {
    try {
      // Validate inputs
      if (serviceId.isEmpty) {
        throw Exception('Service ID is required');
      }
      if (providerId.isEmpty) {
        throw Exception('Provider ID is required');
      }
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }
      if (review.trim().isEmpty) {
        throw Exception('Review is required');
      }

      // Get auth token
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Prepare request body
      final requestBody = {
        'service_id': serviceId,
        'rating': rating,
        'review': review.trim(),
        'rated_to_provider_id': providerId.toString(),
      };

      print('📤 Submitting to: $baseUrl/bid/api/user/rating/user/create');
      print('📤 Body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http
          .post(
        Uri.parse('$baseUrl/bid/api/user/rating/user/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            if (data.containsKey('success')) {
              return RatingResponse.fromJson(data);
            }
            return RatingResponse(
              success: true,
              message: data['message']?.toString() ?? 'Rating submitted successfully',
              data: data['data'],
            );
          }
          return RatingResponse(
            success: true,
            message: 'Rating submitted successfully',
            data: data,
          );
        } catch (e) {
          return RatingResponse(
            success: true,
            message: 'Rating submitted successfully',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? data['error'] ?? 'Invalid request');
        } catch (e) {
          throw Exception('Invalid request. Please check your input.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Service or provider not found');
      } else if (response.statusCode == 500) {
        try {
          final data = jsonDecode(response.body);
          final errorMsg = data['error'] ?? data['message'] ?? 'Server error';
          throw Exception('Server error: $errorMsg');
        } catch (e) {
          throw Exception('Server error. Please contact support.');
        }
      } else {
        throw Exception('Failed to submit rating (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }
}