// providers/ProviderProfileProvider.dart

import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProviderProfileProvider extends ChangeNotifier {
  ProviderProfileModel? _providerProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProviderProfileModel? get providerProfile => _providerProfile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasProfile => _providerProfile != null;

  // Getters for easy access to profile data
  String get fullName => _providerProfile?.fullName ?? 'N/A';

  String get email => _providerProfile?.email ?? 'N/A';

  String get mobile => _providerProfile?.mobile ?? 'N/A';

  String get profileImage => _providerProfile?.image ?? '';

  bool get isRegistered => _providerProfile?.isRegistered ?? false;

  bool get isActive => _providerProfile?.isActive ?? false;

  String get experience => _providerProfile?.experience ?? 'N/A';

  String get education => _providerProfile?.education ?? 'N/A';

  String get service => _providerProfile?.service ?? 'N/A';

  String get keySkills => _providerProfile?.keySkills ?? 'N/A';

  Future<void> loadProviderProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$base_url/api/provider/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isNotEmpty) {
          _providerProfile = ProviderProfileModel.fromJson(jsonData[0]);
          _errorMessage = null;
        } else {
          throw Exception('No provider profile data found');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error loading provider profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await loadProviderProfile();
  }

  void clearProfile() {
    _providerProfile = null;
    _errorMessage = null;
    notifyListeners();
  }
}

// Import the model class
class ProviderProfileModel {
  final int id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? mobile;
  final int? age;
  final String? gender;
  final String? image;
  final String? experience;
  final String? education;
  final String? licenseCertified;
  final String? service;
  final String? keySkills;
  final String? aadhaarPhoto;
  final String? adharNo;
  final bool isActive;
  final bool isRegistered;
  final double? latitude;
  final double? longitude;
  final String providerCreatedAt;

  ProviderProfileModel({
    required this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.mobile,
    this.age,
    this.gender,
    this.image,
    this.experience,
    this.education,
    this.licenseCertified,
    this.service,
    this.keySkills,
    this.aadhaarPhoto,
    this.adharNo,
    required this.isActive,
    required this.isRegistered,
    this.latitude,
    this.longitude,
    required this.providerCreatedAt,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      mobile: json['mobile'],
      age: json['age'],
      gender: json['gender'],
      image: json['image'],
      experience: json['experience'],
      education: json['education'],
      licenseCertified: json['license_certified'],
      service: json['service'],
      keySkills: json['key_skills'],
      aadhaarPhoto: json['aadhaar_photo'],
      adharNo: json['adhar_no'],
      isActive: json['isactive'] ?? false,
      isRegistered: json['isregistered'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      providerCreatedAt: json['provider_created_at'],
    );
  }

  String get fullName {
    if (firstname != null && lastname != null) {
      return '$firstname $lastname';
    } else if (firstname != null) {
      return firstname!;
    } else if (lastname != null) {
      return lastname!;
    }
    return 'N/A';
  }
}
