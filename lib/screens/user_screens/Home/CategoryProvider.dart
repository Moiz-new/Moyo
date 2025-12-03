import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'CatehoryModel.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Replace with your actual base URL

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$base_url/api/admin/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categoryResponse = CategoryResponse.fromJson(jsonData);
        _categories = categoryResponse.categories;
        _errorMessage = null;
      } else {
        _errorMessage =
            'Failed to load categories. Status: ${response.statusCode}';
        _categories = [];
      }
    } catch (e) {
      _errorMessage = 'Error fetching categories: ${e.toString()}';
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getFullImageUrl(String icon) {
    if (icon.isEmpty) {
      return '';
    }
    // Remove leading slash if present
    final cleanIcon = icon.startsWith('/') ? icon.substring(1) : icon;
    return '$base_url/$cleanIcon';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
