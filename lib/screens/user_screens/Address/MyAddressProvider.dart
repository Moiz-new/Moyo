import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_flutter/baseControllers/APis.dart';

class AddressModel {
  final int id;
  final String type;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String latitude;
  final String longitude;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.type,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      type: json['type'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? '',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2.isNotEmpty) parts.add(addressLine2);
    if (landmark.isNotEmpty) parts.add(landmark);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    return parts.join(', ');
  }

  AddressModel copyWith({bool? isDefault}) {
    return AddressModel(
      id: id,
      type: type,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      landmark: landmark,
      city: city,
      state: state,
      pincode: pincode,
      country: country,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class MyAddressProvider extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSettingPrimary = false;

  List<AddressModel> get addresses => _addresses;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isSettingPrimary => _isSettingPrimary;

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();

      if (token == null) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$base_url/api/user/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          _addresses = (data['addresses'] as List)
              .map((item) => AddressModel.fromJson(item))
              .toList();
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to load addresses';
        }
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setPrimaryAddress(int addressId) async {
    _isSettingPrimary = true;
    notifyListeners();

    try {
      final token = await _getAuthToken();

      if (token == null) {
        _errorMessage = 'Authentication token not found';
        _isSettingPrimary = false;
        notifyListeners();
        return false;
      }

      final response = await http.put(
        Uri.parse('$base_url/api/user/addresses/$addressId/set-primary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          // Update local state: set all addresses to non-primary, then set selected one as primary
          _addresses = _addresses.map((address) {
            return address.copyWith(isDefault: address.id == addressId);
          }).toList();

          _isSettingPrimary = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage = 'Failed to set primary address';
      _isSettingPrimary = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isSettingPrimary = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
