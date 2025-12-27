import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../constants/colorConstant/color_constant.dart';
import '../User Instant Service/UserLocationPickerScreen.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Address type
  String _addressType = 'home';
  bool _isDefault = false;
  bool _isLoading = false;

  // Store selected location
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Track if location validation error should be shown
  bool _showLocationError = false;

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Validation Methods
  String? _validateAddressLine1(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address line 1 is required';
    }
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    if (value.trim().length > 200) {
      return 'Address must not exceed 200 characters';
    }
    // Check for valid characters (alphanumeric, spaces, common punctuation)
    final addressRegex = RegExp(r"^[a-zA-Z0-9\s,./\-#()]+$");
    if (!addressRegex.hasMatch(value.trim())) {
      return 'Address contains invalid characters';
    }
    return null;
  }

  String? _validateAddressLine2(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 200) {
        return 'Address must not exceed 200 characters';
      }
      // Check for valid characters
      final addressRegex = RegExp(r"^[a-zA-Z0-9\s,./\-#()]+$");
      if (!addressRegex.hasMatch(value.trim())) {
        return 'Address contains invalid characters';
      }
    }
    return null;
  }

  String? _validateLandmark(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length < 2) {
        return 'Landmark must be at least 2 characters';
      }
      if (value.trim().length > 100) {
        return 'Landmark must not exceed 100 characters';
      }
      // Check for valid characters
      final landmarkRegex = RegExp(r"^[a-zA-Z0-9\s,./\-#()]+$");
      if (!landmarkRegex.hasMatch(value.trim())) {
        return 'Landmark contains invalid characters';
      }
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'City name must not exceed 50 characters';
    }
    // Check if city contains only letters, spaces, hyphens, apostrophes, and periods
    final cityRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!cityRegex.hasMatch(value.trim())) {
      return 'City name can only contain letters';
    }
    // Check for consecutive spaces or special characters
    if (value.trim().contains(RegExp(r'\s{2,}'))) {
      return 'City name has invalid spacing';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length < 2) {
      return 'State name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'State name must not exceed 50 characters';
    }
    // Check if state contains only letters, spaces, hyphens, apostrophes, and periods
    final stateRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!stateRegex.hasMatch(value.trim())) {
      return 'State name can only contain letters';
    }
    // Check for consecutive spaces
    if (value.trim().contains(RegExp(r'\s{2,}'))) {
      return 'State name has invalid spacing';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    // Remove any spaces
    final cleanedValue = value.trim().replaceAll(' ', '');

    // Check if pincode contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
      return 'Pincode must contain only numbers';
    }

    // Check pincode length (flexible for different countries)
    if (cleanedValue.length < 4) {
      return 'Pincode must be at least 4 digits';
    }
    if (cleanedValue.length > 10) {
      return 'Pincode must not exceed 10 digits';
    }

    // Check for invalid patterns (all zeros, all same digit)
    if (RegExp(r'^0+$').hasMatch(cleanedValue)) {
      return 'Invalid pincode';
    }
    if (RegExp(r'^(\d)\1+$').hasMatch(cleanedValue)) {
      return 'Pincode cannot have all same digits';
    }

    return null;
  }

  String? _validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    if (value.trim().length < 2) {
      return 'Country name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Country name must not exceed 50 characters';
    }
    // Check if country contains only letters, spaces, hyphens, apostrophes, and periods
    final countryRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");
    if (!countryRegex.hasMatch(value.trim())) {
      return 'Country name can only contain letters';
    }
    // Check for consecutive spaces
    if (value.trim().contains(RegExp(r'\s{2,}'))) {
      return 'Country name has invalid spacing';
    }
    return null;
  }

  bool _validateLocation() {
    return _selectedLatitude != null && _selectedLongitude != null;
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Open map to select location
  Future<void> _openMapPicker() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserLocationPickerScreen(
            initialLatitude: _selectedLatitude,
            initialLongitude: _selectedLongitude,
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _selectedLatitude = result['latitude'] as double?;
          _selectedLongitude = result['longitude'] as double?;
          _showLocationError = false; // Reset error state

          // Update latitude/longitude fields
          if (_selectedLatitude != null) {
            _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
          }
          if (_selectedLongitude != null) {
            _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
          }

          // Optionally update address line 1 with the returned address
          final address = result['address'] as String?;
          if (address != null && address.isNotEmpty) {
            if (_addressLine1Controller.text.isEmpty) {
              _addressLine1Controller.text = address;
            }
          }
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location selected successfully'),
              backgroundColor: ColorConstant.moyoGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening map picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening map: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitAddress() async {
    // Show location error if not selected
    if (!_validateLocation()) {
      setState(() {
        _showLocationError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select location on map'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix all errors before submitting'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final token = await _getAuthToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication required. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$base_url/api/user/addresses');

      // Parse latitude and longitude with null checks
      double latitude = _selectedLatitude ?? 0.0;
      double longitude = _selectedLongitude ?? 0.0;

      final body = {
        'type': _addressType,
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim().replaceAll(' ', ''),
        'country': _countryController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'is_default': _isDefault,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          // Success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['message'] ?? 'Address added successfully',
                ),
                backgroundColor: ColorConstant.moyoGreen,
              ),
            );
            Navigator.pop(context, responseData['address_id']?[0]);
          }
        } else {
          throw Exception(responseData['message'] ?? 'Failed to add address');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ColorConstant.moyoOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstant.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add new Address',
          style: TextStyle(
            color: ColorConstant.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Home'),
                      value: 'home',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value ?? 'home';
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Office'),
                      value: 'office',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value ?? 'office';
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Other'),
                      value: 'other',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value ?? 'other';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Map Location Button with Error State
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstant.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showLocationError && !_validateLocation()
                        ? Colors.red
                        : (_validateLocation()
                        ? ColorConstant.moyoOrange.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3)),
                    width: _showLocationError && !_validateLocation() ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _showLocationError && !_validateLocation()
                              ? Colors.red
                              : (_validateLocation()
                              ? ColorConstant.moyoOrange
                              : Colors.grey),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validateLocation()
                                ? 'Location Selected ✓'
                                : 'Select Location on Map *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _showLocationError && !_validateLocation()
                                  ? Colors.red
                                  : (_validateLocation()
                                  ? ColorConstant.moyoGreen
                                  : ColorConstant.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_validateLocation()) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, '
                            'Long: ${_selectedLongitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    if (_showLocationError && !_validateLocation()) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Location is required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: Icon(
                          _validateLocation()
                              ? Icons.edit_location
                              : Icons.map,
                          size: 20,
                        ),
                        label: Text(
                          _validateLocation()
                              ? 'Change Location'
                              : 'Open Map',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstant.moyoOrange,
                          side: BorderSide(color: ColorConstant.moyoOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Address Line 1 *',
                controller: _addressLine1Controller,
                hint: 'Enter address line 1',
                validator: _validateAddressLine1,
                maxLength: 200,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Address Line 2',
                controller: _addressLine2Controller,
                hint: 'Enter address line 2 (Optional)',
                validator: _validateAddressLine2,
                maxLength: 200,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Landmark',
                controller: _landmarkController,
                hint: 'Enter landmark (Optional)',
                validator: _validateLandmark,
                maxLength: 100,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'City *',
                      controller: _cityController,
                      hint: 'Enter city',
                      validator: _validateCity,
                      maxLength: 50,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'State *',
                      controller: _stateController,
                      hint: 'Enter state',
                      validator: _validateState,
                      maxLength: 50,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Pincode *',
                      controller: _pincodeController,
                      hint: 'Enter pincode',
                      keyboardType: TextInputType.number,
                      validator: _validatePincode,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Country *',
                      controller: _countryController,
                      hint: 'Enter country',
                      validator: _validateCountry,
                      maxLength: 50,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Latitude',
                      controller: _latitudeController,
                      hint: 'Auto-filled from map',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Longitude',
                      controller: _longitudeController,
                      hint: 'Auto-filled from map',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                activeColor: ColorConstant.moyoOrange,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.moyoOrange,
                    disabledBackgroundColor: ColorConstant.moyoOrange
                        .withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: ColorConstant.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Save Address',
                    style: TextStyle(
                      color: ColorConstant.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstant.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : ColorConstant.white,
            counterText: maxLength != null ? '' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: ColorConstant.moyoOrange,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}