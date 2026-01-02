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
  final TextEditingController mobileController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isFetchingProfile = false;
  String? _errorMessage;
  String? _successMessage;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _imageRemoved = false;
  String _selectedGender = 'male';

  // Email verification states
  bool _isEmailOtpLoading = false;
  bool _isEmailOtpVerifying = false;
  bool _emailOtpSent = false;
  String? _emailErrorMessage;
  bool _isEmailVerified = false;
  String? _originalEmail;

  // Mobile verification states
  bool _isMobileOtpLoading = false;
  bool _isMobileOtpVerifying = false;
  bool _mobileOtpSent = false;
  String? _mobileErrorMessage;
  bool _isMobileVerified = false;
  String? _originalMobile;

  // Track if username and mobile are already set
  bool _isUsernameSet = false;
  bool _isMobileSet = false;
  bool _isEmailLocked = false;

  // Getters
  bool get isLoading => _isLoading;

  bool get isFetchingProfile => _isFetchingProfile;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  File? get selectedImage => _selectedImage;

  String? get currentImageUrl => _currentImageUrl;

  bool get imageRemoved => _imageRemoved;

  String get selectedGender => _selectedGender;

  bool get isEmailOtpLoading => _isEmailOtpLoading;

  bool get isEmailOtpVerifying => _isEmailOtpVerifying;

  bool get emailOtpSent => _emailOtpSent;

  String? get emailErrorMessage => _emailErrorMessage;

  bool get isEmailVerified => _isEmailVerified;

  bool get isUsernameSet => _isUsernameSet;

  bool get isMobileSet => _isMobileSet;

  bool get isEmailLocked => _isEmailLocked;

  // Mobile verification getters
  bool get isMobileOtpLoading => _isMobileOtpLoading;

  bool get isMobileOtpVerifying => _isMobileOtpVerifying;

  bool get mobileOtpSent => _mobileOtpSent;

  String? get mobileErrorMessage => _mobileErrorMessage;

  bool get isMobileVerified => _isMobileVerified;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Fetch profile from API
  Future<bool> fetchProfileFromApi() async {
    _isFetchingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isFetchingProfile = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/profile');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch profile response status: ${response.statusCode}');
      print('Fetch profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['profile'] != null) {
          final profile = data['profile'];

          // Initialize form with API data
          firstnameController.text = profile['firstname'] ?? '';
          lastnameController.text = profile['lastname'] ?? '';
          emailController.text = profile['email'] ?? '';
          usernameController.text = profile['username'] ?? '';
          ageController.text = profile['age']?.toString() ?? '';
          mobileController.text = profile['mobile'] ?? '';
          _selectedGender = profile['gender'] ?? 'male';
          _currentImageUrl = profile['image'];
          _imageRemoved = false;
          _originalEmail = profile['email'] ?? '';
          _originalMobile = profile['mobile'] ?? '';
          _isEmailVerified = profile['email_verified'] ?? false;
          _isMobileVerified = profile['mobile_verified'] ?? false;

          // Set locked states based on existing data
          _isUsernameSet =
              profile['username'] != null &&
              (profile['username'] as String).isNotEmpty;
          _isMobileSet =
              profile['mobile'] != null &&
              (profile['mobile'] as String).isNotEmpty &&
              (profile['mobile'] as String).length == 10;
          _isEmailLocked =
              (profile['email_verified'] ?? false) &&
              profile['email'] != null &&
              (profile['email'] as String).isNotEmpty;

          _isFetchingProfile = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else {
          throw Exception('Profile data not found in response');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Profile not found');
      } else {
        throw Exception(
          'Failed to load profile. Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isFetchingProfile = false;
      print('Error fetching profile: $e');
      notifyListeners();
      return false;
    }
  }

  // Initialize with current profile data
  void initializeProfile({
    required String firstname,
    required String lastname,
    required String email,
    String? username,
    int? age,
    String? gender,
    String? imageUrl,
    bool? emailVerified,
    String? mobile,
    bool? mobileVerified,
  }) {
    firstnameController.text = firstname;
    lastnameController.text = lastname;
    emailController.text = email;
    usernameController.text = username ?? '';
    ageController.text = age?.toString() ?? '';
    mobileController.text = mobile ?? '';
    _selectedGender = gender ?? 'male';
    _currentImageUrl = imageUrl;
    _imageRemoved = false;
    _originalEmail = email.isNotEmpty ? email : null;
    _originalMobile = mobile ?? '';
    _isEmailVerified = emailVerified ?? false;
    _isMobileVerified = mobileVerified ?? false;

    _isUsernameSet = username != null && username.isNotEmpty;
    _isMobileSet = mobile != null && mobile.isNotEmpty && mobile.length == 10;
    _isEmailLocked = (emailVerified ?? false) && email.isNotEmpty;

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
        _imageRemoved = false;
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
        _imageRemoved = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to take picture: $e';
      notifyListeners();
    }
  }

  // Remove selected image or current image
  void removeImage() {
    _selectedImage = null;
    _imageRemoved = true;
    notifyListeners();
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate mobile format
  bool _isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^[6-9]\d{9}$');
    return mobileRegex.hasMatch(mobile);
  }

  // Check if email has changed
  bool hasEmailChanged() {
    final currentEmail = emailController.text.trim();
    if (currentEmail.isEmpty) {
      return false;
    }
    if (_originalEmail == null || _originalEmail!.isEmpty) {
      return true;
    }
    return currentEmail != _originalEmail;
  }

  // Check if mobile has changed
  bool hasMobileChanged() {
    final currentMobile = mobileController.text.trim();
    if (currentMobile.isEmpty) {
      return false;
    }
    if (_originalMobile == null || _originalMobile!.isEmpty) {
      return true;
    }
    return currentMobile != _originalMobile;
  }

  // Validate form
  String? validateForm() {
    if (firstnameController.text.trim().isNotEmpty) {}
    if (lastnameController.text.trim().isNotEmpty) {}

    if (!_isUsernameSet && usernameController.text.trim().isNotEmpty) {
      if (usernameController.text.trim().length < 3) {
        return 'Username must be at least 3 characters';
      }
    }

    if (!_isEmailLocked && emailController.text.trim().isNotEmpty) {
      if (!_isValidEmail(emailController.text.trim())) {
        return 'Please enter a valid email address';
      }
      if (hasEmailChanged() && !_isEmailVerified) {
        return 'Please verify your new email address';
      }
    }

    if (!_isMobileSet && mobileController.text.trim().isNotEmpty) {
      if (!_isValidMobile(mobileController.text.trim())) {
        return 'Please enter a valid 10-digit mobile number';
      }
      if (hasMobileChanged() && !_isMobileVerified) {
        return 'Please verify your new mobile number';
      }
    }

    if (ageController.text.trim().isNotEmpty) {
      final age = int.tryParse(ageController.text.trim());
      if (age == null) {
        return 'Please enter a valid age';
      }
      if (age < 18) {
        return 'You must be at least 18 years old';
      }
      if (age > 120) {
        return 'Please enter a valid age';
      }
    }
    return null;
  }

  // Send OTP to email for verification
  Future<bool> sendEmailOtp() async {
    final email = emailController.text.trim();

    if (_isEmailLocked) {
      _emailErrorMessage = "Email is already verified and cannot be changed";
      notifyListeners();
      return false;
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      _emailErrorMessage = "Please enter a valid email address";
      notifyListeners();
      return false;
    }

    _isEmailOtpLoading = true;
    _emailErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _emailErrorMessage =
            "Authentication token not found. Please login again.";
        _isEmailOtpLoading = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/send-email-otp');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] == 'OTP sent to email') {
          _emailOtpSent = true;
          _isEmailOtpLoading = false;
          _emailErrorMessage = null;
          notifyListeners();
          return true;
        } else {
          _emailErrorMessage =
              responseData['message'] ?? "Unexpected response from server";
          _isEmailOtpLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _emailErrorMessage = errorData['message'] ?? "Failed to send email OTP";
        _isEmailOtpLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _emailErrorMessage = "Network error. Please check your connection.";
      _isEmailOtpLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify email OTP
  Future<bool> verifyEmailOtp({required String otp}) async {
    final email = emailController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      _emailErrorMessage = "Please enter a valid 6-digit OTP";
      notifyListeners();
      return false;
    }

    _isEmailOtpVerifying = true;
    _emailErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _emailErrorMessage =
            "Authentication token not found. Please login again.";
        _isEmailOtpVerifying = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/verify-email-otp');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] == 'Email verified successfully') {
          _isEmailVerified = true;
          _originalEmail = email;
          _isEmailLocked = true;

          await prefs.setBool('is_email_verified', true);
          await prefs.setString('user_email', email);

          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            userData['is_email_verified'] = true;
            userData['email'] = email;
            await prefs.setString('user_data', jsonEncode(userData));
          }

          _isEmailOtpVerifying = false;
          _emailOtpSent = false;
          _emailErrorMessage = null;
          notifyListeners();
          return true;
        } else {
          _emailErrorMessage =
              responseData['message'] ?? "Unexpected response from server";
          _isEmailOtpVerifying = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _emailErrorMessage =
            errorData['message'] ?? "Invalid OTP. Please try again.";
        _isEmailOtpVerifying = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _emailErrorMessage = "Network error. Please check your connection.";
      _isEmailOtpVerifying = false;
      notifyListeners();
      return false;
    }
  }

  // Send OTP to mobile for verification
  Future<bool> sendMobileOtp() async {
    final mobile = mobileController.text.trim();

    if (_isMobileSet) {
      _mobileErrorMessage =
          "Mobile number is already set and cannot be changed";
      notifyListeners();
      return false;
    }

    if (mobile.isEmpty || !_isValidMobile(mobile)) {
      _mobileErrorMessage = "Please enter a valid 10-digit mobile number";
      notifyListeners();
      return false;
    }

    _isMobileOtpLoading = true;
    _mobileErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _mobileErrorMessage =
            "Authentication token not found. Please login again.";
        _isMobileOtpLoading = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/number-otp');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'mobile': mobile}),
      );

      print('Send mobile OTP response status: ${response.statusCode}');
      print('Send mobile OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] == 'OTP sent successfully') {
          _mobileOtpSent = true;
          _isMobileOtpLoading = false;
          _mobileErrorMessage = null;
          notifyListeners();
          return true;
        } else {
          _mobileErrorMessage =
              responseData['message'] ?? "Unexpected response from server";
          _isMobileOtpLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _mobileErrorMessage =
            errorData['message'] ?? "Failed to send mobile OTP";
        _isMobileOtpLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mobileErrorMessage = "Network error. Please check your connection.";
      _isMobileOtpLoading = false;
      print('Error sending mobile OTP: $e');
      notifyListeners();
      return false;
    }
  }

  // Verify mobile OTP
  // Verify mobile OTP
  Future<bool> verifyMobileOtp({required String otp}) async {
    final mobile = mobileController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      _mobileErrorMessage = "Please enter a valid 6-digit OTP";
      notifyListeners();
      return false;
    }

    _isMobileOtpVerifying = true;
    _mobileErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _mobileErrorMessage =
            "Authentication token not found. Please login again.";
        _isMobileOtpVerifying = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/auth/number-verify');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );

      print('Verify mobile OTP response status: ${response.statusCode}');
      print('Verify mobile OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['message'] != null ||
            responseData['success'] == true) {
          _isMobileVerified = true;
          _originalMobile = mobile;
          _isMobileSet = true;

          // ✅ ADD THESE LINES - Save mobile to SharedPreferences
          await prefs.setString('user_mobile', mobile);
          await prefs.setBool('is_mobile_verified', true);

          // Update user_data if it exists
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            userData['mobile'] = mobile;
            userData['mobile_verified'] = true;
            await prefs.setString('user_data', jsonEncode(userData));
          }

          _isMobileOtpVerifying = false;
          _mobileOtpSent = false;
          _mobileErrorMessage = null;
          notifyListeners();
          return true;
        } else {
          _mobileErrorMessage =
              responseData['message'] ?? "Unexpected response from server";
          _isMobileOtpVerifying = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _mobileErrorMessage =
            errorData['message'] ?? "Invalid OTP. Please try again.";
        _isMobileOtpVerifying = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mobileErrorMessage = "Network error. Please check your connection.";
      _isMobileOtpVerifying = false;
      print('Error verifying mobile OTP: $e');
      notifyListeners();
      return false;
    }
  }

  // Resend Email OTP
  Future<void> resendEmailOtp() async {
    await sendEmailOtp();
  }

  // Resend Mobile OTP
  Future<void> resendMobileOtp() async {
    await sendMobileOtp();
  }

  // Update profile
  Future<bool> updateProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final validationError = validateForm();
      if (validationError != null) {
        _errorMessage = validationError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$base_url/api/auth/update-user-profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (firstnameController.text.trim().isNotEmpty) {
        request.fields['firstname'] = firstnameController.text.trim();
      }
      if (lastnameController.text.trim().isNotEmpty) {
        request.fields['lastname'] = lastnameController.text.trim();
      }

      if (!_isUsernameSet && usernameController.text.trim().isNotEmpty) {
        request.fields['username'] = usernameController.text.trim();
      }

      if (!_isEmailLocked && emailController.text.trim().isNotEmpty) {
        request.fields['email'] = emailController.text.trim();
      }

      if (ageController.text.trim().isNotEmpty) {
        request.fields['age'] = ageController.text.trim();
      }
      request.fields['gender'] = _selectedGender;

      if (!_isMobileSet && mobileController.text.trim().isNotEmpty) {
        request.fields['mobile'] = mobileController.text.trim();
      }

      if (_imageRemoved) {
        request.fields['image'] = 'null';
      } else if (_selectedImage != null) {
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _successMessage =
              responseData['message'] ?? 'Profile updated successfully';

          _selectedImage = null;
          _imageRemoved = false;

          if (!_isUsernameSet && usernameController.text.trim().isNotEmpty) {
            _isUsernameSet = true;
          }
          if (!_isMobileSet && mobileController.text.trim().isNotEmpty) {
            _isMobileSet = true;
          }
          if (_isMobileVerified) {
            await prefs.setString('user_mobile', mobileController.text.trim());
          }

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

  void setEmailError(String? error) {
    _emailErrorMessage = error;
    notifyListeners();
  }

  void clearEmailError() {
    _emailErrorMessage = null;
    notifyListeners();
  }

  void resetEmailVerificationState() {
    _emailOtpSent = false;
    _isEmailOtpLoading = false;
    _isEmailOtpVerifying = false;
    _emailErrorMessage = null;
    notifyListeners();
  }

  void setMobileError(String? error) {
    _mobileErrorMessage = error;
    notifyListeners();
  }

  void clearMobileError() {
    _mobileErrorMessage = null;
    notifyListeners();
  }

  void resetMobileVerificationState() {
    _mobileOtpSent = false;
    _isMobileOtpLoading = false;
    _isMobileOtpVerifying = false;
    _mobileErrorMessage = null;
    notifyListeners();
  }

  @override
  dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    ageController.dispose();
    mobileController.dispose();
    super.dispose();
  }
}
