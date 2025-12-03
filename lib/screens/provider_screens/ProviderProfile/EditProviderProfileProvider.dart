import 'dart:convert';
import 'dart:io';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class EditProviderProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> updateProviderProfile({
    required String adharNo,
    required String panNo,
    required bool isActive,
    required bool isRegistered,
    File? aadhaarPhoto,
    File? panPhoto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$base_url/api/provider/update-profile'),
      );

      // Add headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add text fields
      request.fields['adhar_no'] = adharNo;
      request.fields['pan_no'] = panNo;
      request.fields['isactive'] = isActive.toString();
      request.fields['isregistered'] = isRegistered.toString();

      // Add aadhaar photo if provided
      if (aadhaarPhoto != null && await aadhaarPhoto.exists()) {
        try {
          // Get the original filename and extension
          String fileName = path.basename(aadhaarPhoto.path);
          String extension = path.extension(aadhaarPhoto.path).toLowerCase();

          // Determine MIME type based on extension
          MediaType? contentType;
          if (extension == '.jpg' || extension == '.jpeg') {
            contentType = MediaType('image', 'jpeg');
          } else if (extension == '.png') {
            contentType = MediaType('image', 'png');
          } else if (extension == '.gif') {
            contentType = MediaType('image', 'gif');
          } else if (extension == '.webp') {
            contentType = MediaType('image', 'webp');
          }

          // Read file as bytes
          var aadhaarBytes = await aadhaarPhoto.readAsBytes();

          var aadhaarFile = http.MultipartFile.fromBytes(
            'aadhaar_photo',
            aadhaarBytes,
            filename: fileName,
            contentType: contentType,
          );
          request.files.add(aadhaarFile);
        } catch (e) {
          print('Error reading aadhaar photo: $e');
          throw Exception('Failed to read Aadhaar photo');
        }
      }

      // Add PAN photo if provided
      if (panPhoto != null && await panPhoto.exists()) {
        try {
          // Get the original filename and extension
          String fileName = path.basename(panPhoto.path);
          String extension = path.extension(panPhoto.path).toLowerCase();

          // Determine MIME type based on extension
          MediaType? contentType;
          if (extension == '.jpg' || extension == '.jpeg') {
            contentType = MediaType('image', 'jpeg');
          } else if (extension == '.png') {
            contentType = MediaType('image', 'png');
          } else if (extension == '.gif') {
            contentType = MediaType('image', 'gif');
          } else if (extension == '.webp') {
            contentType = MediaType('image', 'webp');
          }

          // Read file as bytes
          var panBytes = await panPhoto.readAsBytes();

          var panFile = http.MultipartFile.fromBytes(
            'pan_photo',
            panBytes,
            filename: fileName,
            contentType: contentType,
          );
          request.files.add(panFile);
        } catch (e) {
          print('Error reading pan photo: $e');
          throw Exception('Failed to read PAN photo');
        }
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['message'] != null) {
          print('Profile updated: ${jsonData['message']}');
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error updating provider profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class UpdateProfileResponse {
  final String message;
  final UpdateProfileResult result;

  UpdateProfileResponse({required this.message, required this.result});

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      message: json['message'] ?? '',
      result: UpdateProfileResult.fromJson(json['result'] ?? {}),
    );
  }
}

class UpdateProfileResult {
  final String? adharNo;
  final String? isActive;
  final String? isRegistered;
  final String? panNo;

  UpdateProfileResult({
    this.adharNo,
    this.isActive,
    this.isRegistered,
    this.panNo,
  });

  factory UpdateProfileResult.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResult(
      adharNo: json['adhar_no'],
      isActive: json['isactive'],
      isRegistered: json['isregistered'],
      panNo: json['pan_no'],
    );
  }
}
