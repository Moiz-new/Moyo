// api_error_handler.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiErrorHandler {
  static final ApiErrorHandler _instance = ApiErrorHandler._internal();

  factory ApiErrorHandler() {
    return _instance;
  }

  ApiErrorHandler._internal();

  // Global navigation key to access context anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Handle API response and check for 403
  static Future<http.Response> handleApiResponse(http.Response response) async {
    if (response.statusCode == 403) {
      _handle403Error();
      throw Exception('You have been blocked by admin');
    }
    return response;
  }

  // Handle 403 error - blocked by admin
  static void _handle403Error() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Access Blocked'),
            content: const Text('You have been blocked by admin. Please contact support.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Navigate to login and clear all routes
                  navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    '/login',
                        (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Fallback: Navigate directly if context is not available
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    }
  }

  // Show error message
  static void showErrorSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// HTTP Client Wrapper
class ApiClient {
  static Future<http.Response> get(
      String url, {
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      return await ApiErrorHandler.handleApiResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> post(
      String url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body,
      );
      return await ApiErrorHandler.handleApiResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> put(
      String url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body,
      );
      return await ApiErrorHandler.handleApiResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> delete(
      String url, {
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      return await ApiErrorHandler.handleApiResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}