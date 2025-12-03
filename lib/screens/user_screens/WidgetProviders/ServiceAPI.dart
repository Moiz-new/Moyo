import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AcceptServiceResponse {
  final bool success;
  final String message;
  final ServiceData? data;

  AcceptServiceResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AcceptServiceResponse.fromJson(Map<String, dynamic> json) {
    return AcceptServiceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? ServiceData.fromJson(json['data']) : null,
    );
  }
}

class ServiceData {
  final String? serviceId;
  final String? bidId;
  final Provider? provider;
  final String? acceptedAt;

  ServiceData({this.serviceId, this.bidId, this.provider, this.acceptedAt});

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      serviceId: json['service_id']?.toString(),
      bidId: json['bid_id']?.toString(),
      provider: json['provider'] != null
          ? Provider.fromJson(json['provider'])
          : null,
      acceptedAt: json['accepted_at']?.toString(),
    );
  }
}

class Provider {
  final int? id;

  Provider({this.id});

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(id: json['id'] as int?);
  }
}

class ServiceAPI {
  /// Accept a service with dynamic parameters
  ///
  /// [serviceId] - The ID of the service to accept
  /// [amount] - The bid amount
  /// [notes] - Optional payment notes (defaults to "cash")
  ///
  /// Returns [AcceptServiceResponse] or throws an exception on error
  static Future<AcceptServiceResponse> acceptService({
    required String serviceId,
    required String amount,
    String notes = "cash",
  }) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      // Validate token
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Validate required parameters
      if (serviceId.isEmpty) {
        throw Exception('Service ID cannot be empty');
      }
      if (amount.isEmpty) {
        throw Exception('Amount cannot be empty');
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'service_id': serviceId,
        'amount': amount,
        'notes': notes,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$base_url/bid/api/service/accept-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      print(response.body);
      print(requestBody);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AcceptServiceResponse.fromJson(responseData);
      } else {
        // Handle error response
        final errorMessage =
            responseData['message'] ?? 'Failed to accept service';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with more context
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to accept service: ${e.toString()}');
    }
  }
}

// Example usage in your widget:
/*
void _handleAcceptService() async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final response = await ServiceAPI.acceptService(
      serviceId: "66",  // Replace with actual service ID
      amount: "600",    // Replace with actual amount
      notes: "cash",    // Optional
    );

    // Hide loading indicator
    Navigator.of(context).pop();

    if (response.success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Service accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Handle success - navigate or refresh data
      // Example: Navigator.of(context).pop();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to accept service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // Hide loading indicator if still showing
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }
}
*/
