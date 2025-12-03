import 'dart:convert';
import 'dart:io';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SkillProvider with ChangeNotifier {

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastResponse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastResponse => _lastResponse;

  // Add skill API call
  Future<Map<String, dynamic>?> addSkill({
    required String skillName,
    required String serviceName,
    required String experience,
    File? proofDocument,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$base_url/api/provider/add-skills'),
      );

      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add fields
      request.fields['skill_name'] = skillName;
      request.fields['service_name'] = serviceName;
      request.fields['experience'] = experience;

      // Add file if provided
      if (proofDocument != null) {
        var file = await http.MultipartFile.fromPath(
          'proof_document',
          proofDocument.path,
        );
        request.files.add(file);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lastResponse = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return _lastResponse;
      } else {
        _errorMessage = 'Failed to add skill: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}