import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/ServiceApiService.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/ServiceModel.dart';
import 'package:flutter/material.dart';
import 'dart:convert';


import 'BookProviderApiService.dart';

class BookProviderProvider with ChangeNotifier {
  final ServiceApiService _apiService = ServiceApiService();
  final BookProviderApiService _bookProviderApiService = BookProviderApiService();

  List<ServiceModel> _allServices = [];
  bool _isLoading = false;
  String? _error;

  // Book provider state
  bool _isBooking = false;
  String? _bookingError;
  BookProviderData? _bookingData;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBooking => _isBooking;
  String? get bookingError => _bookingError;
  BookProviderData? get bookingData => _bookingData;

  // Only return closed and pending services
  List<ServiceModel> get filteredServices {
    return _allServices.where((service) =>
    service.status == 'closed' || service.status == 'open'
    ).toList();
  }

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getServiceHistory();
      final serviceResponse = ServiceResponse.fromJson(response);
      _allServices = serviceResponse.services;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _allServices = [];
      notifyListeners();
    }
  }

  Future<void> refreshServices() async {
    await fetchServices();
  }

  /// ✅ Book Provider Method - Only API Call
  Future<bool> bookProvider({
    required String serviceId,
    required String providerId,
  }) async {
    _isBooking = true;
    _bookingError = null;
    _bookingData = null;
    notifyListeners();

    try {
      debugPrint('📞 Booking provider...');
      debugPrint('   Service ID: $serviceId');
      debugPrint('   Provider ID: $providerId');

      final response = await _bookProviderApiService.confirmProvider(
        serviceId: serviceId,
        providerId: providerId,
      );

      final bookingResponse = BookProviderResponse.fromJson(response);

      if (bookingResponse.success) {
        _bookingData = bookingResponse.data;
        _isBooking = false;
        _bookingError = null;

        debugPrint('✅ Provider booked successfully!');
        debugPrint('   Start OTP: ${_bookingData?.startOtp}');
        debugPrint('   End OTP: ${_bookingData?.endOtp}');

        notifyListeners();
        return true; // ✅ Return true for success
      } else {
        _bookingError = bookingResponse.message;
        _isBooking = false;
        debugPrint('❌ Booking failed: ${bookingResponse.message}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _bookingError = e.toString();
      _isBooking = false;
      debugPrint('❌ Booking error: $e');
      notifyListeners();
      return false;
    }
  }
  /// Clear booking data
  void clearBookingData() {
    _bookingData = null;
    _bookingError = null;
    _isBooking = false;
    notifyListeners();
    debugPrint('🗑️ Cleared booking data');
  }

  @override
  void dispose() {
    debugPrint('🔔 BookProviderProvider disposed');
    super.dispose();
  }
}