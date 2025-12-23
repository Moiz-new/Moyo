import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../widgets/BlockedDialog.dart';
import 'CatehoryModel.dart';

typedef OnAuthErrorCallback = void Function(BuildContext context);

class ProviderCategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories({
    required BuildContext context,
    OnAuthErrorCallback? onAuthError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');
      final response = await http.get(
        Uri.parse('$base_url/api/admin/categories-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(token);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categoryResponse = CategoryResponse.fromJson(jsonData);
        _categories = categoryResponse.categories;
        _errorMessage = null;
      } else if (response.statusCode == 403) {
        // Show modern blocked dialog
        if (context.mounted) {
          await BlockedDialog.show(context);

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
                  (route) => false,
            );
          }
        }
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
    final cleanIcon = icon.startsWith('/') ? icon.substring(1) : icon;
    return '$base_url/$cleanIcon';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
