import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'SubcategoryResponse.dart';

class SubcategoryProvider with ChangeNotifier {
  List<Subcategory> _subcategories = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentCategoryId;
  bool _isUnchecking = false;

  List<Subcategory> get subcategories => _subcategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentCategoryId => _currentCategoryId;
  bool get isUnchecking => _isUnchecking;

  Future<void> fetchSubcategories(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentCategoryId = categoryId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _subcategories = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$base_url/api/admin/getsubcategories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(categoryId);
      print(response.body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final subcategoryResponse = SubcategoryResponse.fromJson(jsonData);
        _subcategories = subcategoryResponse.subcategories;
        _errorMessage = null;
      } else {
        _errorMessage =
        'Failed to load subcategories. Status: ${response.statusCode}';
        _subcategories = [];
      }
    } catch (e) {
      _errorMessage = 'Error fetching subcategories: ${e.toString()}';
      _subcategories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uncheckSkill(int skillId) async {
    _isUnchecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isUnchecking = false;
        notifyListeners();
        return false;
      }

      final response = await http.put(
        Uri.parse('$base_url/api/admin/skills/$skillId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'is_checked': false,
        }),
      );


      print('Uncheck response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          // Refresh subcategories to get updated is_checked status
          if (_currentCategoryId != null) {
            await fetchSubcategories(_currentCategoryId!);
          }
          _isUnchecking = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = jsonData['message'] ?? 'Failed to uncheck skill';
          _isUnchecking = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Failed to uncheck skill. Status: ${response.statusCode}';
        _isUnchecking = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error unchecking skill: ${e.toString()}';
      _isUnchecking = false;
      notifyListeners();
      return false;
    }
  }

  String getFullImageUrl(String? icon) {
    if (icon == null || icon.isEmpty) {
      return '';
    }

    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return icon;
    }

    final cleanIcon = icon.startsWith('/') ? icon.substring(1) : icon;
    return '$base_url/$cleanIcon';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSubcategories() {
    _subcategories = [];
    _currentCategoryId = null;
    notifyListeners();
  }
}