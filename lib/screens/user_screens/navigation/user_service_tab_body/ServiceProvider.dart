import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../NATS Service/NatsService.dart';
import 'ServiceApiService.dart';
import 'ServiceModel.dart';

class ServiceProvider with ChangeNotifier {
  final ServiceApiService _apiService = ServiceApiService();
  final NatsService _natsService = NatsService();

  List<ServiceModel> _allServices = [];
  bool _isLoading = false;
  String? _error;

  // NATS related variables
  String? _natsSubscriptionTopic;
  bool _isNatsListening = false;

  // ✅ CHANGED: Store providers per service ID
  Map<String, List<Map<String, dynamic>>> _serviceProviders = {};

  // Current selected service ID
  String? _currentServiceId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isNatsListening => _isNatsListening;

  // ✅ CHANGED: Return providers for current service only
  List<Map<String, dynamic>> get interestedProviders {
    if (_currentServiceId == null) return [];
    return _serviceProviders[_currentServiceId] ?? [];
  }

  List<ServiceModel> get assignedServices {
    return _allServices.where((service) =>
    service.status == 'assigned'
    ).toList();
  }
  // Only return closed and pending services
  List<ServiceModel> get filteredServices {
    return _allServices.where((service) =>
    service.status == 'closed' || service.status == 'open'
    ).toList();
  }

  // ✅ NEW: Set current service when user opens details screen
  void setCurrentService(String serviceId) {
    _currentServiceId = serviceId;
    debugPrint('🎯 Current service set to: $serviceId');
    notifyListeners();
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

  // Initialize NATS subscription for service details
  Future<void> initializeServiceNatsSubscription(int userId) async {
    if (_isNatsListening) {
      debugPrint('✅ NATS already listening');
      return;
    }

    try {
      // Check if NATS is connected
      if (!_natsService.isConnected) {
        debugPrint('⚠️ NATS not connected yet, waiting...');

        int attempts = 0;
        while (!_natsService.isConnected && attempts < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }

        if (!_natsService.isConnected) {
          debugPrint('❌ NATS connection timeout after ${attempts * 500}ms');
          return;
        }
      }

      debugPrint('✅ NATS is connected, setting up subscription');

      _natsSubscriptionTopic = 'service.accepted.$userId';
      debugPrint('🎧 Subscribing to: $_natsSubscriptionTopic');

      _natsService.subscribe(_natsSubscriptionTopic!, (message) {
        _handleServiceAcceptedNotification(message);
      });

      _isNatsListening = true;
      notifyListeners();
      debugPrint('✅ NATS subscription active for user $userId');

    } catch (e) {
      debugPrint('❌ NATS Subscription Error: $e');
      _isNatsListening = false;
      notifyListeners();
    }
  }

  void _handleServiceAcceptedNotification(String message) {
    try {
      debugPrint('📥 Raw message received in ServiceProvider: $message');

      final data = jsonDecode(message);
      if (data == null) {
        debugPrint('⚠️ Received null data');
        return;
      }

      final serviceId = data['service_id']?.toString();
      final bidId = data['bid_id']?.toString();
      final amount = data['amount']?.toString(); // ✅ Direct amount field
      final acceptedAt = data['accepted_at']?.toString();

      final service = data['service'] as Map<String, dynamic>?;
      final providerData_raw = data['provider'] as Map<String, dynamic>?;

      // ✅ NEW: Get user object from provider
      final user = providerData_raw?['user'] as Map<String, dynamic>?;

      // ✅ CRITICAL: Check if serviceId exists
      if (serviceId == null) {
        debugPrint('❌ No service_id in message');
        return;
      }

      // Calculate provider name from user object
      final firstName = user?['firstname']?.toString() ?? '';
      final lastName = user?['lastname']?.toString() ?? '';
      final providerName = firstName.isNotEmpty || lastName.isNotEmpty
          ? '$firstName $lastName'.trim()
          : (user?['username'] ?? 'Provider #$bidId');

      debugPrint('📥 Service Accepted Notification:');
      debugPrint('   Service ID: $serviceId');
      debugPrint('   Bid ID: ${bidId ?? "N/A"}');
      debugPrint('   Provider: $providerName');
      debugPrint('   Amount: ${amount ?? "N/A"}');

      final providerData = {
        'serviceId': serviceId,
        'bidId': bidId ?? 'N/A',
        'providerName': providerName,

        // ✅ Get data from user object
        'gender': user?['gender']?.toString().toUpperCase().substring(0, 1) ?? 'N/A',
        'age': user?['age']?.toString() ?? 'N/A',

        // ✅ Distance and reach time (fallback to defaults if not available)
        'distance': '5', // Default value
        'reachTime': '10', // Default value

        // ✅ Category and subcategory from service
        'category': service?['category'] ?? 'N/A',
        'subCategory': service?['service'] ?? 'N/A',

        // ✅ IMPORTANT: Use amount from root level
        'chargeRate': amount ?? service?['budget']?.toString() ?? 'N/A',

        // ✅ Rating and experience (defaults for now)
        'rating': '4.0', // Default
        'experience': '2', // Default

        // ✅ Profile picture from user
        'dp': user?['image'] ?? 'https://picsum.photos/200/200',

        // ✅ Phone from user
        'phone': user?['mobile'] ?? user?['phone'] ?? 'N/A',

        // ✅ Provider ID from provider object
        'providerId': providerData_raw?['id']?.toString() ?? user?['id']?.toString() ?? bidId ?? DateTime.now().millisecondsSinceEpoch.toString(),

        // ✅ Additional info
        'acceptedAt': acceptedAt,
      };

      // ✅ CHANGED: Store providers per service ID
      if (!_serviceProviders.containsKey(serviceId)) {
        _serviceProviders[serviceId] = [];
      }

      final existingIndex = _serviceProviders[serviceId]!.indexWhere(
            (p) => p['providerId'] == providerData['providerId'],
      );

      if (existingIndex != -1) {
        _serviceProviders[serviceId]![existingIndex] = providerData;
        debugPrint('🔄 Updated existing provider for service $serviceId at index $existingIndex');
      } else {
        _serviceProviders[serviceId]!.insert(0, providerData);
        debugPrint('➕ Added new provider to service $serviceId. Total: ${_serviceProviders[serviceId]!.length}');
      }

      // Notify listeners to update UI
      notifyListeners();
      debugPrint('🔔 UI notified. Service $serviceId has ${_serviceProviders[serviceId]!.length} providers');

    } catch (e, stackTrace) {
      debugPrint('❌ Error handling notification: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Message received: $message');
    }
  }

  String _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  void clearInterestedProviders() {
    _serviceProviders.clear();
    _currentServiceId = null;
    notifyListeners();
    debugPrint('🗑️ Cleared all service providers');
  }

  // ✅ NEW: Clear providers for specific service
  void clearProvidersForService(String serviceId) {
    _serviceProviders.remove(serviceId);
    notifyListeners();
    debugPrint('🗑️ Cleared providers for service $serviceId');
  }

  // Get NatsService instance for StreamBuilder
  NatsService get natsService => _natsService;

  // DON'T unsubscribe - keep listening throughout app lifecycle
  @override
  void dispose() {
    // Keep NATS subscription active
    debugPrint('🔔 ServiceProvider disposed but NATS remains active');
    super.dispose();
  }
}