import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServiceFormField {
  final int id;
  final int subcategoryId;
  final String fieldName;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final int sortOrder;

  ServiceFormField({
    required this.id,
    required this.subcategoryId,
    required this.fieldName,
    required this.fieldType,
    required this.options,
    required this.isRequired,
    required this.sortOrder,
  });

  factory ServiceFormField.fromJson(Map<String, dynamic> json) {
    return ServiceFormField(
      id: json['id'] ?? 0,
      subcategoryId: json['subcategory_id'] ?? 0,
      fieldName: (json['field_name'] ?? '').toString().trim(),
      fieldType: (json['field_type'] ?? '').toString().toLowerCase(),
      options: (json['options'] as List<dynamic>?)
          ?.map((option) => option.toString().trim())
          .where((option) => option.isNotEmpty)
          .toList() ??
          [],
      isRequired: json['is_required'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

class ServiceFormFieldProvider extends ChangeNotifier {
  List<ServiceFormField> _fields = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _formData = {};

  List<ServiceFormField> get fields => _fields;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get formData => _formData;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchServiceFormFields(int subcategoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$base_url/api/user/moiz/$subcategoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['fields'] != null) {
          _fields = (data['fields'] as List)
              .map((field) => ServiceFormField.fromJson(field))
              .toList();

          // Sort fields by sort_order
          _fields.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          _errorMessage = null;
        } else {
          _fields = [];
          _errorMessage = 'No fields found for this service';
        }
      } else {
        _errorMessage = 'Failed to load form fields: ${response.statusCode}';
        _fields = [];
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _fields = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFormField(String fieldName, dynamic value) {
    if (fieldName.isNotEmpty) {
      _formData[fieldName] = value;
      // Don't notify listeners to prevent rebuilds on every keystroke
    }
  }

  void clearFormData() {
    _formData.clear();
    _fields = [];
    _errorMessage = null;
    notifyListeners();
  }

  bool validateForm() {
    for (var field in _fields) {
      if (field.isRequired) {
        final value = _formData[field.fieldName];
        if (value == null ||
            (value is String && value.isEmpty) ||
            (value is int && value == 0)) {
          return false;
        }
      }
    }
    return true;
  }

  String? getValidationError() {
    for (var field in _fields) {
      if (field.isRequired) {
        final value = _formData[field.fieldName];
        if (value == null ||
            (value is String && value.isEmpty) ||
            (value is int && value == 0)) {
          return 'Please fill ${field.fieldName}';
        }
      }
    }
    return null;
  }
}