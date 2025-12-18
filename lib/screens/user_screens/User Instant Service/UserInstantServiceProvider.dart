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
    print(categoryId);
    try {
      debugPrint("Service Id: $categoryId");
      final response = await http.get(
        Uri.parse('$baseUrl/user/moiz/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(categoryId);
      print(response.body);
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
        debugPrint('Choose required Fields');
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

  // service mode ko non-null rakho
  String _selectedServiceMode = 'hrs';

  // form values
  final Map<String, dynamic> _formValues = {
    'duration_unit': 'hour',
    'tenure': 'one_time',
  };

  // Location data
  double? _latitude;
  double? _longitude;
  String? _location;

  // Schedule data
  DateTime? _startDate;
  DateTime? _endDate;
  int? _serviceDays;
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;

  // map controller
  GoogleMapController? _mapController;

  // Getters
  SubcategoryResponse? get subcategoryResponse => _subcategoryResponse;

  Subcategory? get selectedSubcategory => _selectedSubcategory;

  bool get isLoading => _isLoading;

  bool get isCreatingService => _isCreatingService;

  String? get error => _error;

  String get selectedServiceMode => _selectedServiceMode;

  Map<String, dynamic> get formValues => _formValues;

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  String? get location => _location;

  DateTime? get startDate => _startDate;

  DateTime? get endDate => _endDate;

  int? get serviceDays => _serviceDays;

  DateTime? get scheduleDate => _scheduleDate;

  TimeOfDay? get scheduleTime => _scheduleTime;

  GoogleMapController? get mapController => _mapController;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // ---------- Pricing / Budget ----------

  double? calculateBaseAmount() {
    if (_selectedSubcategory == null) return null;

    int quantity = 1;
    for (var field in _selectedSubcategory!.fields) {
      if (field.isCalculate) {
        final value = _formValues[field.fieldName];
        if (value != null) {
          quantity = int.tryParse(value.toString()) ?? 1;
        }
        break;
      }
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    if (billingType == 'time') {
      if (_selectedServiceMode == 'hrs') {
        final durationValue =
            int.tryParse(_formValues['duration_value']?.toString() ?? '1') ?? 1;
        final hourlyRate =
            double.tryParse(_selectedSubcategory!.hourlyRate) ?? 0.0;
        return quantity * durationValue * hourlyRate;
      } else {
        final dailyRate =
            double.tryParse(_selectedSubcategory!.dailyRate) ?? 0.0;
        return quantity * (_serviceDays ?? 1) * dailyRate;
      }
    } else if (billingType == 'project') {
      final hourlyRate =
          double.tryParse(_selectedSubcategory!.hourlyRate) ?? 0.0;
      return quantity * hourlyRate;
    }

    return null;
  }

  Map<String, double>? getBudgetRange() {
    final baseAmount = calculateBaseAmount();
    if (baseAmount == null) return null;

    return {
      'min': baseAmount * 0.7,
      'max': baseAmount * 2.0,
      'base': baseAmount,
    };
  }

  String? validateBudget(String? budgetStr) {
    if (budgetStr == null || budgetStr.isEmpty) {
      return 'Please enter your budget';
    }

    final budget = double.tryParse(budgetStr);
    if (budget == null) {
      return 'Please enter a valid amount';
    }

    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == 'cash' && budget > 2000) {
      return 'Cash payment is limited to ₹2000';
    }

    final range = getBudgetRange();
    if (range != null) {
      if (budget < range['min']!) {
        return 'Minimum budget should be ₹${range['min']!.toStringAsFixed(0)} (30% down from base rate)';
      }
      if (budget > range['max']!) {
        return 'Maximum budget should be ₹${range['max']!.toStringAsFixed(0)} (100% up from base rate)';
      }
    }

    return null;
  }

  String getBudgetHint() {
    final range = getBudgetRange();
    if (range != null) {
      return 'Budget range: ₹${range['min']!.toStringAsFixed(0)} - ₹${range['max']!.toStringAsFixed(0)} (Base: ₹${range['base']!.toStringAsFixed(0)})';
    }

    if (_selectedSubcategory != null) {
      return 'Minimum Service Price is ₹${_selectedSubcategory!.hourlyRate}';
    }

    return 'Enter your budget';
  }

  // ---------- Location ----------

  Future<void> getCurrentLocation() async {
    try {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await updateLocationFromMap(position.latitude, position.longitude);

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

  Future<void> updateLocationFromMap(double lat, double lon) async {
    try {
      _latitude = lat;
      _longitude = lon;

      final placemarks = await placemarkFromCoordinates(lat, lon);
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

  void setLocation(double lat, double lon, String loc) {
    _latitude = lat;
    _longitude = lon;
    _location = loc;
    notifyListeners();
  }

  // ---------- Subcategories / form ----------

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

  void setSelectedSubcategory(Subcategory? subcategory) {
    _selectedSubcategory = subcategory;

    _formValues
      ..clear()
      ..addAll({'duration_unit': 'hour', 'tenure': 'one_time'});

    if (subcategory != null &&
        subcategory.billingType.toLowerCase() == 'time') {
      _selectedServiceMode = 'hrs';
    }

    notifyListeners();
  }

  // Add this new method after setSelectedSubcategory
  void setSelectedSubcategoryInitial(Subcategory? subcategory) {
    _selectedSubcategory = subcategory;

    _formValues
      ..clear()
      ..addAll({'duration_unit': 'hour', 'tenure': 'one_time'});

    if (subcategory != null &&
        subcategory.billingType.toLowerCase() == 'time') {
      _selectedServiceMode = 'hrs';
    }

    // ✅ DON'T call notifyListeners() here - this is for initial setup only
  }

  void updateFormValue(String fieldName, dynamic value) {
    _formValues[fieldName] = value;
    notifyListeners();
  }

  dynamic getFormValue(String fieldName) => _formValues[fieldName];

  void clearFormValues() {
    _formValues
      ..clear()
      ..addAll({'duration_unit': 'hour', 'tenure': 'one_time'});
    notifyListeners();
  }

  // ---------- Time / date state ----------

  void setServiceMode(String mode) {
    if (_selectedServiceMode != mode) {
      _selectedServiceMode = mode;

      // mode change pe time/date bhi reset kar sakte ho
      if (mode == 'hrs') {
        _serviceDays = null;
        _startDate = null;
        _endDate = null;
      } else {
        _scheduleDate = null;
        _scheduleTime = null;
      }

      notifyListeners();
    }
  }

  void setStartDate(DateTime date) {
    _startDate = DateTime(date.year, date.month, date.day);
    if (_serviceDays != null && _serviceDays! > 0) {
      _endDate = _startDate!.add(Duration(days: _serviceDays!));
    }
    notifyListeners();
  }

  void setScheduleDate(DateTime date) {
    _scheduleDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_endDate != normalized) {
      _endDate = normalized;
      notifyListeners();
    }
  }

  void setServiceDays(int days) {
    if (days > 0 && _serviceDays != days) {
      _serviceDays = days;
      if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: days));
      }
      notifyListeners();
    }
  }

  void setScheduleTime(TimeOfDay time) {
    if (_scheduleTime != time) {
      _scheduleTime = time;
      notifyListeners();
    }
  }

  // ---------- Validation ----------

  bool validateForm({String? serviceType}) {
    if (_selectedSubcategory == null) return false;

    for (var field in _selectedSubcategory!.fields) {
      if (field.isRequired) {
        final value = _formValues[field.fieldName];
        if (value == null || value.toString().isEmpty) {
          return false;
        }
      }
    }

    if (_latitude == null || _longitude == null || _location == null) {
      return false;
    }

    final budget = _formValues['budget'];
    final budgetError = validateBudget(budget?.toString());
    if (budgetError != null) {
      return false;
    }

    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) {
      return false;
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    if (billingType == 'time') {
      if (_selectedServiceMode.isEmpty) return false;

      if (_selectedServiceMode == 'hrs') {
        final durationValue = _formValues['duration_value'];
        if (durationValue == null || durationValue.toString().isEmpty) {
          return false;
        }

        final durationUnit = _formValues['duration_unit'];
        if (durationUnit == null || durationUnit.toString().isEmpty) {
          return false;
        }

        if (serviceType == 'later') {
          if (_scheduleDate == null || _scheduleTime == null) {
            return false;
          }
        }
      } else if (_selectedServiceMode == 'day') {
        if (_serviceDays == null || _serviceDays! <= 0) return false;
        if (_startDate == null || _endDate == null) return false;
      }

      final tenure = _formValues['tenure'];
      if (tenure == null || tenure.toString().isEmpty) return false;
    }

    return true;
  }

  String? getValidationError({String? serviceType}) {
    if (_selectedSubcategory == null) return 'No subcategory selected';

    for (var field in _selectedSubcategory!.fields) {
      if (field.isRequired) {
        final value = _formValues[field.fieldName];
        if (value == null || value.toString().isEmpty) {
          return 'Please fill ${field.fieldName}';
        }
      }
    }

    if (_latitude == null || _longitude == null || _location == null) {
      return 'Please select service location';
    }

    final budget = _formValues['budget'];
    final budgetError = validateBudget(budget?.toString());
    if (budgetError != null) {
      return budgetError;
    }

    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) {
      return 'Please select a payment method';
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    if (billingType == 'time') {
      if (_selectedServiceMode.isEmpty) {
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

        if (serviceType != 'instant') {
          if (_scheduleDate == null) {
            return 'Please select schedule date';
          }
          if (_scheduleTime == null) {
            return 'Please select schedule time';
          }
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

  // ---------- Token ----------

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // ---------- Create service ----------

  Future<bool> createService({
    required String categoryName,
    required String billingtype,
    required String subcategoryName,
    String? serviceType,
  }) async {
    if (!validateForm(serviceType: serviceType)) {
      _error = getValidationError(serviceType: serviceType);
      notifyListeners();
      return false;
    }

    _isCreatingService = true;
    _error = null;
    notifyListeners();

    try {
      final dynamicFields = <String, dynamic>{};
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
      final billingTypeNormalized = billingtype.toLowerCase();

      final serviceData = <String, dynamic>{
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

      if (billingTypeNormalized == 'time') {
        serviceData["tenure"] = _formValues['tenure'] ?? 'one_time';

        if (_selectedServiceMode == 'hrs') {
          final durationValue =
              int.tryParse(_formValues['duration_value'].toString()) ?? 2;

          if (serviceType != 'instant') {
            final scheduleDate =
                '${_scheduleDate!.year}-${_scheduleDate!.month.toString().padLeft(2, '0')}-${_scheduleDate!.day.toString().padLeft(2, '0')}';

            final scheduleTime =
                '${_scheduleTime!.hour.toString().padLeft(2, '0')}:${_scheduleTime!.minute.toString().padLeft(2, '0')}';

            serviceData.addAll({
              "service_mode": "hrs",
              "duration_value": durationValue,
              "duration_unit": _formValues['duration_unit'] ?? 'hour',
              "schedule_date": scheduleDate,
              "schedule_time": scheduleTime,
            });
          } else {
            serviceData.addAll({
              "service_mode": "hrs",
              "duration_value": durationValue,
              "duration_unit": _formValues['duration_unit'] ?? 'hour',
            });
          }
        } else {
          final startDateStr =
              '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';

          final endDateStr =
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
        }
      } else {
        debugPrint('⚠️ NATS not connected, skipping publish');
      }

      final response = await _service.createService(serviceData, token: token);
      final isSuccess = response != null && (response['success'] == true);

      if (isSuccess) {
        final serviceIdDynamic = response['service']?['id'];
        final serviceId = serviceIdDynamic != null
            ? serviceIdDynamic.toString()
            : "unknown";

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
        _error = response?['message']?.toString() ?? 'Fields Are Required';

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

  void reset() {
    _subcategoryResponse = null;
    _selectedSubcategory = null;
    _isLoading = false;
    _isCreatingService = false;
    _error = null;
    _formValues
      ..clear()
      ..addAll({
        //'payment_method': 'online',
        'duration_unit': 'hour',
        'tenure': 'one_time',
      });
    _latitude = null;
    _longitude = null;
    _location = null;
    _scheduleDate = null;
    _scheduleTime = null;
    _startDate = null;
    _endDate = null;
    _serviceDays = null;
    _selectedServiceMode = 'hrs';
    notifyListeners();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
