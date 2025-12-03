import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../NATS Service/NatsService.dart';
import '../../SubCategory/SubcategoryResponse.dart';

class SubcategoryService {
  static const String baseUrl = 'https://api.moyointernational.com/api';

  Future<SubcategoryResponse?> fetchSubcategories(int categoryId) async {
    try {
      debugPrint("Service Id: $categoryId");
      final response = await http.get(
        Uri.parse('$baseUrl/user/moiz/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Fetch Subcategories Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SubcategoryResponse.fromJson(jsonData);
      } else {
        debugPrint(
          'Failed to load subcategories. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createService(
      Map<String, dynamic> serviceData, {
        required String token,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$base_url/bid/api/service/create-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(serviceData),
      );

      debugPrint('Create Service Response: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return jsonData as Map<String, dynamic>;
      } else {
        debugPrint('Failed to create service. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating service: $e');
      return null;
    }
  }
}

class UserInstantServiceProvider with ChangeNotifier {
  final SubcategoryService _service = SubcategoryService();
  final NatsService _natsService = NatsService();

  SubcategoryResponse? _subcategoryResponse;
  Subcategory? _selectedSubcategory;
  bool _isLoading = false;
  bool _isCreatingService = false;
  String? _error;

  String? _selectedServiceMode;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _serviceDays;

  // Getters
  String? get selectedServiceMode => _selectedServiceMode;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get serviceDays => _serviceDays;

  // Form field values
  Map<String, dynamic> _formValues = {};

  // Location data
  double? _latitude;
  double? _longitude;
  String? _location;

  // Schedule data
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;

  // Getters
  SubcategoryResponse? get subcategoryResponse => _subcategoryResponse;
  Subcategory? get selectedSubcategory => _selectedSubcategory;
  bool get isLoading => _isLoading;
  bool get isCreatingService => _isCreatingService;
  String? get error => _error;
  Map<String, dynamic> get formValues => _formValues;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get location => _location;
  DateTime? get scheduleDate => _scheduleDate;
  TimeOfDay? get scheduleTime => _scheduleTime;

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // ❌ REMOVED: Don't initialize NATS here - it's already initialized in main()
  // NATS connection is managed globally, just use it

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied';
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await updateLocationFromMap(position.latitude, position.longitude);

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }
    } catch (e) {
      _error = 'Error getting location: $e';
      debugPrint('Error getting current location: $e');
      notifyListeners();
    }
  }

  // Update location from map tap
  Future<void> updateLocationFromMap(double lat, double lon) async {
    try {
      _latitude = lat;
      _longitude = lon;

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _location =
        '${place.street}, ${place.locality}, ${place.administrativeArea}';
      } else {
        _location =
        'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting address: $e');
      _location =
      'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
      notifyListeners();
    }
  }

  // Fetch subcategories from API
  Future<void> fetchSubcategories(int categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchSubcategories(categoryId);

      if (response != null) {
        _subcategoryResponse = response;
        _error = null;
      } else {
        _error = 'Failed to load subcategories';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set selected subcategory
  void setSelectedSubcategory(Subcategory? subcategory) {
    _selectedSubcategory = subcategory;
    _formValues.clear();
    _formValues['payment_method'] = 'postpaid';
    _formValues['duration_unit'] = 'hour';
    _formValues['tenure'] = 'one_time';

    // Initialize service mode based on billing type
    if (subcategory != null &&
        subcategory.billingType.toLowerCase() == 'time') {
      _selectedServiceMode = 'hrs'; // Set default mode for time billing
    }

    notifyListeners();
  }

  // Update form field value
  void updateFormValue(String fieldName, dynamic value) {
    _formValues[fieldName] = value;
    notifyListeners();
  }

  // Get form field value
  dynamic getFormValue(String fieldName) {
    return _formValues[fieldName];
  }

  // Set location data
  void setLocation(double lat, double lon, String loc) {
    _latitude = lat;
    _longitude = lon;
    _location = loc;
    notifyListeners();
  }

  // Set schedule date
  void setScheduleDate(DateTime date) {
    _scheduleDate = date;
    notifyListeners();
  }

  // Set schedule time
  void setScheduleTime(TimeOfDay time) {
    _scheduleTime = time;
    notifyListeners();
  }

  // Clear all form values
  void clearFormValues() {
    _formValues.clear();
    notifyListeners();
  }

  void setServiceMode(String mode) {
    _selectedServiceMode = mode;
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    // Auto calculate end date if service days is set
    if (_serviceDays != null) {
      _endDate = date.add(Duration(days: _serviceDays!));
    }
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setServiceDays(int days) {
    _serviceDays = days;
    // Auto calculate end date if start date is set
    if (_startDate != null) {
      _endDate = _startDate!.add(Duration(days: days));
    }
    notifyListeners();
  }

  // Validate form
  bool validateForm() {
    if (_selectedSubcategory == null) return false;

    // Validate required fields from API
    for (var field in _selectedSubcategory!.fields) {
      if (field.isRequired) {
        final value = _formValues[field.fieldName];
        if (value == null || value.toString().isEmpty) {
          return false;
        }
      }
    }

    // Validate budget
    final budget = _formValues['budget'];
    if (budget == null || budget.toString().isEmpty) {
      return false;
    }

    // Validate payment method
    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) {
      return false;
    }

    // Validate cash payment limit
    if (paymentMethod == 'cash') {
      final budgetValue = double.tryParse(budget.toString()) ?? 0.0;
      if (budgetValue > 2000) {
        return false;
      }
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    // Validation based on billing type
    if (billingType == 'time') {
      if (_selectedServiceMode == null) return false;

      if (_selectedServiceMode == 'hrs') {
        final durationValue = _formValues['duration_value'];
        if (durationValue == null || durationValue.toString().isEmpty) {
          return false;
        }

        final durationUnit = _formValues['duration_unit'];
        if (durationUnit == null || durationUnit.toString().isEmpty) {
          return false;
        }

        if (_scheduleDate == null || _scheduleTime == null) {
          return false;
        }
      } else if (_selectedServiceMode == 'day') {
        if (_serviceDays == null || _serviceDays! <= 0) {
          return false;
        }
        if (_startDate == null || _endDate == null) {
          return false;
        }
      }

      final tenure = _formValues['tenure'];
      if (tenure == null || tenure.toString().isEmpty) {
        return false;
      }
    }

    return true;
  }

  // Get validation error message
  String? getValidationError() {
    if (_selectedSubcategory == null) return 'No subcategory selected';

    for (var field in _selectedSubcategory!.fields) {
      if (field.isRequired) {
        final value = _formValues[field.fieldName];
        if (value == null || value.toString().isEmpty) {
          return 'Please fill ${field.fieldName}';
        }
      }
    }

    final budget = _formValues['budget'];
    if (budget == null || budget.toString().isEmpty) {
      return 'Please enter your budget';
    }

    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) {
      return 'Please select a payment method';
    }

    if (paymentMethod == 'cash') {
      final budgetValue = double.tryParse(budget.toString()) ?? 0.0;
      if (budgetValue > 2000) {
        return 'Cash payment is limited to ₹2000. Please choose online payment or reduce the budget.';
      }
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    if (billingType == 'time') {
      if (_selectedServiceMode == null) {
        return 'Please select service mode (Hourly or Daily)';
      }

      if (_selectedServiceMode == 'hrs') {
        final durationValue = _formValues['duration_value'];
        if (durationValue == null || durationValue.toString().isEmpty) {
          return 'Please enter duration value';
        }

        final durationUnit = _formValues['duration_unit'];
        if (durationUnit == null || durationUnit.toString().isEmpty) {
          return 'Please select duration unit';
        }

        if (_scheduleDate == null) {
          return 'Please select schedule date';
        }

        if (_scheduleTime == null) {
          return 'Please select schedule time';
        }
      } else if (_selectedServiceMode == 'day') {
        if (_serviceDays == null || _serviceDays! <= 0) {
          return 'Please enter number of days';
        }

        if (_startDate == null) {
          return 'Please select start date';
        }

        if (_endDate == null) {
          return 'Please select end date';
        }
      }

      final tenure = _formValues['tenure'];
      if (tenure == null || tenure.toString().isEmpty) {
        return 'Please select tenure';
      }
    }

    return null;
  }

  // Get authentication token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Create service with NATS integration
  Future<bool> createService({
    required String categoryName,
    required String billingtype,
    required String subcategoryName,
  }) async {
    if (!validateForm()) {
      _error = getValidationError();
      notifyListeners();
      return false;
    }

    _isCreatingService = true;
    _error = null;
    notifyListeners();

    try {
      // Prepare dynamic fields
      final Map<String, dynamic> dynamicFields = {};
      for (var field in _selectedSubcategory!.fields) {
        final value = _formValues[field.fieldName];
        if (value != null && value.toString().isNotEmpty) {
          if (field.fieldType == 'number') {
            dynamicFields[field.fieldName] =
                int.tryParse(value.toString()) ??
                    double.tryParse(value.toString()) ??
                    value;
          } else {
            dynamicFields[field.fieldName] = value.toString();
          }
        }
      }

      // Get user data
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = await getToken();

      if (token == null || token.isEmpty) {
        _error = 'Authentication token not found. Please login again.';
        _isCreatingService = false;
        notifyListeners();
        return false;
      }

      final double budgetValue =
          double.tryParse(_formValues['budget'].toString()) ?? 0.0;
      final String billingTypeNormalized = billingtype.toLowerCase();

      // Build service data
      Map<String, dynamic> serviceData = {
        "title": "$subcategoryName Service",
        "category": categoryName,
        "description": "Service request for $subcategoryName",
        "service": subcategoryName,
        "budget": budgetValue.toInt(),
        "max_budget": (budgetValue * 1.2).toInt(),
        "service_type": "instant",
        "payment_method": 'postpaid',
        "payment_type": _formValues['payment_method'] ?? 'online',
        "latitude": _latitude ?? 22.7196,
        "longitude": _longitude ?? 75.8577,
        "location": _location ?? "Indore, Madhya Pradesh",
        "dynamic_fields": dynamicFields,
      };

      // Add fields based on billing type
      if (billingTypeNormalized == 'time') {
        serviceData["tenure"] = _formValues['tenure'] ?? 'one_time';

        if (_selectedServiceMode == 'hrs') {
          final int durationValue =
              int.tryParse(_formValues['duration_value'].toString()) ?? 2;

          final String scheduleDate =
              '${_scheduleDate!.year}-${_scheduleDate!.month.toString().padLeft(2, '0')}-${_scheduleDate!.day.toString().padLeft(2, '0')}';

          final String scheduleTime =
              '${_scheduleTime!.hour.toString().padLeft(2, '0')}:${_scheduleTime!.minute.toString().padLeft(2, '0')}';

          serviceData.addAll({
            "service_mode": "hrs",
            "duration_value": durationValue,
            "duration_unit": _formValues['duration_unit'] ?? 'hour',
            "schedule_date": scheduleDate,
            "schedule_time": scheduleTime,
          });
        } else if (_selectedServiceMode == 'day') {
          final String startDateStr =
              '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';

          final String endDateStr =
              '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';

          serviceData.addAll({
            "service_mode": "day",
            "service_days": _serviceDays,
            "start_date": startDateStr,
            "end_date": endDateStr,
            "duration_value": null,
            "duration_unit": null,
          });
        }
      } else if (billingTypeNormalized == 'project') {
        serviceData.addAll({
          "service_mode": "task",
          "tenure": "task",
          "duration_value": null,
          "duration_unit": null,
          "service_days": null,
          "start_date": null,
          "end_date": null,
        });
      }

      debugPrint('Service Data: ${json.encode(serviceData)}');

      // ✅ FIXED: Only publish to NATS if connected (don't try to connect here)
      if (_natsService.isConnected) {
        try {
          final natsRequestPayload = {
            "user_id": userId ?? "unknown",
            "service_data": serviceData,
            "timestamp": DateTime.now().toIso8601String(),
          };

          _natsService.publish(
            'service.create.request',
            json.encode(natsRequestPayload),
          );
          debugPrint('📤 Published service creation request to NATS');
        } catch (e) {
          debugPrint('⚠️ Error publishing to NATS: $e');
          // Don't fail the entire operation if NATS publish fails
        }
      } else {
        debugPrint('⚠️ NATS not connected, skipping publish');
      }

      // Create service via API
      final response = await _service.createService(serviceData, token: token);
      final bool isSuccess = response != null && (response['success'] == true);

      if (isSuccess) {
        final dynamic serviceIdDynamic = response['service']?['id'];
        final String serviceId = serviceIdDynamic != null
            ? serviceIdDynamic.toString()
            : "unknown";

        // ✅ FIXED: Publish success only if connected
        if (_natsService.isConnected) {
          try {
            final successPayload = {
              "service_id": serviceId,
              "user_id": userId ?? "unknown",
              "timestamp": DateTime.now().toIso8601String(),
            };

            _natsService.publish(
              'service.created.success',
              json.encode(successPayload),
            );
            debugPrint('✅ Published success to NATS');
          } catch (e) {
            debugPrint('⚠️ Error publishing success to NATS: $e');
          }
        }

        _isCreatingService = false;
        notifyListeners();
        return true;
      } else {
        _error = response?['message']?.toString() ?? 'Failed to create service';

        // ✅ FIXED: Publish failure only if connected
        if (_natsService.isConnected) {
          try {
            final failurePayload = {
              "user_id": userId ?? "unknown",
              "error": _error,
              "timestamp": DateTime.now().toIso8601String(),
            };

            _natsService.publish(
              'service.created.failure',
              json.encode(failurePayload),
            );
          } catch (e) {
            debugPrint('⚠️ Error publishing failure to NATS: $e');
          }
        }

        _isCreatingService = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An error occurred: $e';
      debugPrint('❌ Error creating service: $e');

      // ✅ FIXED: Publish error only if connected
      if (_natsService.isConnected) {
        try {
          final errorPayload = {
            "error": e.toString(),
            "timestamp": DateTime.now().toIso8601String(),
          };

          _natsService.publish(
            'service.created.error',
            json.encode(errorPayload),
          );
        } catch (natsError) {
          debugPrint('⚠️ Error publishing error to NATS: $natsError');
        }
      }

      _isCreatingService = false;
      notifyListeners();
      return false;
    }
  }

  // Reset provider state
  void reset() {
    _subcategoryResponse = null;
    _selectedSubcategory = null;
    _isLoading = false;
    _isCreatingService = false;
    _error = null;
    _formValues.clear();
    _latitude = null;
    _longitude = null;
    _location = null;
    _scheduleDate = null;
    _scheduleTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // ❌ REMOVED: Don't disconnect NATS here - it's shared across the app
    // The global NATS connection should remain active
    super.dispose();
  }
}