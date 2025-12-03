import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubCategory {
  final int id;
  final String name;
  final String icon;
  final String hourlyRate;
  final String dailyRate;
  final String weeklyRate;
  final String monthlyRate;

  SubCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.hourlyRate,
    required this.dailyRate,
    required this.weeklyRate,
    required this.monthlyRate,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      hourlyRate: json['hourly_rate'] ?? '0.00',
      dailyRate: json['daily_rate'] ?? '0.00',
      weeklyRate: json['weekly_rate'] ?? '0.00',
      monthlyRate: json['monthly_rate'] ?? '0.00',
    );
  }
}

class SubCategoryProvider extends ChangeNotifier {
  List<SubCategory> _subcategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubCategory> get subcategories => _subcategories;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchSubcategories(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$base_url/api/user/subcategories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _subcategories = (data['subcategories'] as List)
            .map((subcategory) => SubCategory.fromJson(subcategory))
            .toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load subcategories: ${response.statusCode}';
        _subcategories = [];
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _subcategories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSubcategories() {
    _subcategories = [];
    _errorMessage = null;
    notifyListeners();
  }
}
