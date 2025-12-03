// providers/EditProfileProvider.dart

import 'dart:io';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileProvider with ChangeNotifier {
  // Form controllers
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _selectedImage;
  String? _currentImageUrl;
  String _selectedGender = 'male';

  // Getters
  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  File? get selectedImage => _selectedImage;

  String? get currentImageUrl => _currentImageUrl;

  String get selectedGender => _selectedGender;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Initialize with current profile data
  void initializeProfile({
    required String firstname,
    required String lastname,
    required String email,
    String? username,
    int? age,
    String? gender,
    String? imageUrl,
  }) {
    firstnameController.text = firstname;
    lastnameController.text = lastname;
    emailController.text = email;
    usernameController.text = username ?? '';
    ageController.text = age?.toString() ?? '';
    _selectedGender = gender ?? 'male';
    _currentImageUrl = imageUrl;
    notifyListeners();
  }

  // Set selected gender
  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to take picture: $e';
      notifyListeners();
    }
  }

  // Remove selected image
  void removeImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Validate form
  String? validateForm() {
    if (firstnameController.text.trim().isEmpty) {
      return 'First name is required';
    }
    if (lastnameController.text.trim().isEmpty) {
      return 'Last name is required';
    }
    if (usernameController.text.trim().isEmpty) {
      return 'Username is required';
    }
    if (usernameController.text.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (ageController.text.trim().isNotEmpty) {
      final age = int.tryParse(ageController.text.trim());
      if (age == null || age < 1 || age > 120) {
        return 'Please enter a valid age';
      }
    }
    return null;
  }

  // Update profile
  // Update profile method with fixed image upload
  Future<bool> updateProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Validate form
      final validationError = validateForm();
      if (validationError != null) {
        _errorMessage = validationError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$base_url/api/auth/update-profile'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields['firstname'] = firstnameController.text.trim();
      request.fields['lastname'] = lastnameController.text.trim();
      request.fields['username'] = usernameController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['gender'] = _selectedGender;

      if (ageController.text.trim().isNotEmpty) {
        request.fields['age'] = ageController.text.trim();
      }

      // Add image if selected - WITH PROPER CONTENT TYPE
      if (_selectedImage != null) {
        // Determine the content type based on file extension
        String? mimeType;
        String filePath = _selectedImage!.path.toLowerCase();

        if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (filePath.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (filePath.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (filePath.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else {
          mimeType = 'image/jpeg';
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
            contentType: MediaType('image', mimeType.split('/')[1]),
          ),
        );
      }

      print('Image path: ${_selectedImage?.path}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _successMessage =
              responseData['message'] ?? 'Profile updated successfully';
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to update profile';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? 'Server error occurred';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    ageController.dispose();
    super.dispose();
  }
}
