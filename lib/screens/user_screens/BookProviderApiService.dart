import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookProviderApiService {
  static const String baseUrl = 'https://api.moyointernational.com/bid/api';

  /// Confirm/Book a provider for a service
  Future<Map<String, dynamic>> confirmProvider({
    required String serviceId,
    required String providerId,
  }) async {
    try {
      // Get auth token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse('$baseUrl/service/confirm-provider');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'service_id': serviceId, 'provider_id': providerId}),
      );
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to confirm provider. Please try again.',
        );
      }
    } catch (e) {
      throw Exception('Error confirming provider: ${e.toString()}');
    }
  }
}

class BookProviderResponse {
  final bool success;
  final String message;
  final BookProviderData? data;

  BookProviderResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BookProviderResponse.fromJson(Map<String, dynamic> json) {
    return BookProviderResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? BookProviderData.fromJson(json['data'])
          : null,
    );
  }
}

class BookProviderData {
  final String serviceId;
  final String providerId;
  final String startOtp;
  final String endOtp;

  BookProviderData({
    required this.serviceId,
    required this.providerId,
    required this.startOtp,
    required this.endOtp,
  });

  factory BookProviderData.fromJson(Map<String, dynamic> json) {
    return BookProviderData(
      serviceId: json['service_id']?.toString() ?? '',
      providerId: json['provider_id']?.toString() ?? '',
      startOtp: json['start_otp']?.toString() ?? '',
      endOtp: json['end_otp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'provider_id': providerId,
      'start_otp': startOtp,
      'end_otp': endOtp,
    };
  }
}
