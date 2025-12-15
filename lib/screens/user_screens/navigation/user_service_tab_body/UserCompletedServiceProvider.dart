import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CompletedServiceProvider extends ChangeNotifier {
  List<ServiceItem> _services = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceItem> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCompletedServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _error = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.moyointernational.com/bid/api/service/user-service-complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final serviceResponse = CompletedServiceResponse.fromJson(jsonData);

        if (serviceResponse.success) {
          _services = serviceResponse.services;
          _error = null;
        } else {
          _error = 'Failed to load services';
        }
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized. Please login again';
      } else {
        _error = 'Failed to load services. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}