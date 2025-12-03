import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL (mutable)
  static String baseUrl = 'https://your-api-base-url.com/api';

  // Default headers
  static Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Optional global token
  static String? authToken;

  /// Set global auth token
  static void setAuthToken(String token) {
    authToken = token;
  }

  /// Build headers (merges defaults, optional custom headers, and auth token)
  static Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final merged = {...defaultHeaders, ...?headers};
    if (authToken != null) merged['Authorization'] = 'Bearer $authToken';
    return merged;
  }

  /// GET Request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));
      if (kDebugMode) debugPrint('[API GET] $uri');
      final response = await http.get(uri, headers: _buildHeaders(headers));
      return _handleResponse(response);
    } catch (e) {
      return _handleError('GET', e.toString());
    }
  }

  /// POST Request
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint);
      if (kDebugMode) debugPrint('[API POST] $uri\nBody: $body');
      final response = await http.post(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError('POST', e.toString());
    }
  }

  /// PUT Request
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint);
      if (kDebugMode) debugPrint('[API PUT] $uri\nBody: $body');
      final response = await http.put(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError('PUT', e.toString());
    }
  }

  /// DELETE Request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint);
      if (kDebugMode) debugPrint('[API DELETE] $uri');
      final response = await http.delete(uri, headers: _buildHeaders(headers));
      return _handleResponse(response);
    } catch (e) {
      return _handleError('DELETE', e.toString());
    }
  }

  /// Handle HTTP Response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'Request completed',
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'data': null,
        'message': 'Failed to parse response: ${e.toString()}',
      };
    }
  }

  /// Handle errors
  static Map<String, dynamic> _handleError(String method, String error) {
    if (kDebugMode) debugPrint('[API ERROR] $method: $error');
    return {
      'success': false,
      'statusCode': 0,
      'data': null,
      'message': '$method request failed: $error',
    };
  }
}
