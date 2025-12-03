import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../constants/colorConstant/color_constant.dart';

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

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final token = await _getAuthToken();

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$base_url/api/user/addresses');

      final body = {
        'type': _addressType,
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'country': _countryController.text.trim(),
        'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
        'is_default': _isDefault,
      };

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
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
                          _addressType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('office'),
                      value: 'office',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value!;
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
                          _addressType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Address Line 1',
                controller: _addressLine1Controller,
                hint: 'Enter address line 1',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address line 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Address Line 2',
                controller: _addressLine2Controller,
                hint: 'Enter address line 2',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Landmark',
                controller: _landmarkController,
                hint: 'Enter landmark',
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'City',
                      controller: _cityController,
                      hint: 'Enter city',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'State',
                      controller: _stateController,
                      hint: 'Enter state',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Pincode',
                      controller: _pincodeController,
                      hint: 'Enter pincode',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Country',
                      controller: _countryController,
                      hint: 'Enter country',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
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
                      hint: 'Enter latitude',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Longitude',
                      controller: _longitudeController,
                      hint: 'Enter longitude',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: ColorConstant.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
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
