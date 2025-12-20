import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../NATS Service/NatsService.dart';
import '../../baseControllers/APis.dart';

class ServiceArrivalProvider extends ChangeNotifier {
  final NatsService _natsService = NatsService();

  // Timer state
  int _remainingSeconds = 600;
  bool _isTimerActive = false;
  bool _hasArrived = false;
  bool _canStartWork = false;
  DateTime? _arrivalTime;
  String? _currentServiceId;

  // Loading states
  bool _isProcessingArrival = false;
  String? _errorMessage;

  // Auto-refresh timers
  Timer? _countdownTimer;
  Timer? _statusCheckTimer;
  Timer? _natsListenerTimer;

  // Status tracking
  String? _currentStatus;
  Map<String, dynamic>? _cachedServiceData;

  // Getters
  int get remainingSeconds => _remainingSeconds;

  bool get isTimerActive => _isTimerActive;

  bool get hasArrived => _hasArrived;

  bool get canStartWork => _canStartWork;

  bool get isProcessingArrival => _isProcessingArrival;

  String? get errorMessage => _errorMessage;

  String? get currentStatus => _currentStatus;

  Map<String, dynamic>? get cachedServiceData => _cachedServiceData;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ServiceArrivalProvider() {
    _initializeTimer();
  }

  // Initialize timer state from SharedPreferences
  Future<void> _initializeTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serviceId = prefs.getString('timer_service_id');

      if (serviceId != null && serviceId.isNotEmpty) {
        _currentServiceId = serviceId;
        final arrivalTimeStr = prefs.getString('arrival_time_$serviceId');

        if (arrivalTimeStr != null) {
          _arrivalTime = DateTime.parse(arrivalTimeStr);
          _hasArrived = true;

          final elapsed = DateTime.now().difference(_arrivalTime!).inSeconds;
          _remainingSeconds = 600 - elapsed;

          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _isTimerActive = false;
            _canStartWork = true;
          } else {
            _isTimerActive = true;
            _canStartWork = false;
            _startTimerCountdown();
          }

          // Start auto-refresh listeners
          _startAutoRefresh(serviceId);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error initializing timer: $e');
    }
  }

  // Load timer state for specific service
  Future<void> loadTimerState(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentServiceId = serviceId;

      final arrivalTimeStr = prefs.getString('arrival_time_$serviceId');
      final hasArrivedFlag = prefs.getBool('has_arrived_$serviceId') ?? false;

      if (arrivalTimeStr != null && hasArrivedFlag) {
        _arrivalTime = DateTime.parse(arrivalTimeStr);
        _hasArrived = true;

        final elapsed = DateTime.now().difference(_arrivalTime!).inSeconds;
        _remainingSeconds = 600 - elapsed;

        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _isTimerActive = false;
          _canStartWork = true;
        } else {
          _isTimerActive = true;
          _canStartWork = false;
          _startTimerCountdown();
        }

        // Start auto-refresh listeners
        _startAutoRefresh(serviceId);
        notifyListeners();
      } else {
        _resetTimerState();
        // Still start status check for new services
        _startAutoRefresh(serviceId);
      }
    } catch (e) {
      print('Error loading timer state: $e');
      _resetTimerState();
    }
  }

  // Start auto-refresh mechanism
  void _startAutoRefresh(String serviceId) {
    // Cancel existing timers
    _stopAutoRefresh();

    // Poll backend every 3 seconds for status changes (reduced from 15s)
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkServiceStatus(serviceId),
    );
  }

  // Stop all auto-refresh timers
  void _stopAutoRefresh() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    _natsListenerTimer?.cancel();
    _natsListenerTimer = null;
  }

  // Check service status via API
  Future<void> _checkServiceStatus(String serviceId) async {
    try {
      // Prevent multiple concurrent requests
      if (_isProcessingArrival) return;

      final prefs = await SharedPreferences.getInstance();
      final providerToken = prefs.getString('provider_auth_token');

      if (providerToken == null) return;

      String? providerId;
      try {
        final parts = providerToken.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          providerId =
              payload['provider_id']?.toString() ??
              payload['id']?.toString() ??
              payload['sub']?.toString();
        } else {
          providerId = providerToken;
        }
      } catch (e) {
        providerId = providerToken;
      }

      if (providerId == null) return;

      final requestData = jsonEncode({
        'service_id': serviceId,
        'provider_id': providerId,
      });

      final response = await _natsService.request(
        'service.info.details',
        requestData,
        timeout: const Duration(seconds: 5),
      );

      if (response != null) {
        final data = jsonDecode(response);
        _updateServiceData(data);
      }
    } catch (e) {
      // Silent fail - don't show errors to user for background polling
      print('Background status check: $e');
    }
  }

  void _updateServiceData(Map<String, dynamic> newData) {
    bool hasChanges = false;

    // Check status change
    final newStatus = newData['status']?.toString().toLowerCase();
    if (newStatus != null && newStatus != _currentStatus) {
      _currentStatus = newStatus;
      hasChanges = true;

      // Handle status-specific logic
      if (newStatus == 'in_progress' || newStatus == 'started') {
        // Work has started - clear arrival timer
        if (_hasArrived && _currentServiceId != null) {
          clearTimerState(_currentServiceId!);
        }
      } else if (newStatus == 'completed' || newStatus == 'cancelled') {
        // Service ended - stop all timers
        _stopAutoRefresh();
        _resetTimerState();
      }
    }

    // Check for arrival confirmation from backend
    final arrivedStatus = newData['provider_arrived'];
    if (arrivedStatus == true && !_hasArrived) {
      _hasArrived = true;
      _isTimerActive = true;
      _canStartWork = false;
      _remainingSeconds = 600;
      _startTimerCountdown();
      hasChanges = true;
    }

    // Cache service data - only update if different
    final newDataString = jsonEncode(newData);
    final oldDataString = _cachedServiceData != null
        ? jsonEncode(_cachedServiceData)
        : '';

    if (newDataString != oldDataString) {
      _cachedServiceData = newData;
      hasChanges = true;
    }

    // Only notify if there are actual changes
    if (hasChanges) {
      notifyListeners();
    }
  }

  // Confirm provider arrival
  Future<bool> confirmProviderArrival(String serviceId) async {
    if (_isProcessingArrival) return false;

    _isProcessingArrival = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final providerToken = prefs.getString('provider_auth_token');

      if (providerToken == null) {
        _errorMessage = 'Provider authentication token not found';
        _isProcessingArrival = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$base_url/bid/api/service/provider-arrived'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $providerToken',
        },
        body: jsonEncode({'service_id': serviceId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentServiceId = serviceId;
        _arrivalTime = DateTime.now();
        _hasArrived = true;
        _isTimerActive = true;
        _canStartWork = false;
        _remainingSeconds = 600;
        _currentStatus = 'arrived';

        await prefs.setString('timer_service_id', serviceId);
        await prefs.setString(
          'arrival_time_$serviceId',
          _arrivalTime!.toIso8601String(),
        );
        await prefs.setBool('has_arrived_$serviceId', true);

        _startTimerCountdown();

        // Start auto-refresh after arrival
        _startAutoRefresh(serviceId);

        _isProcessingArrival = false;
        notifyListeners();
        return true;
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to confirm arrival';
        _isProcessingArrival = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error confirming arrival: $e';
      _isProcessingArrival = false;
      notifyListeners();
      return false;
    }
  }

  // Start timer countdown
  void _startTimerCountdown() {
    // Cancel existing countdown timer
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerActive && _remainingSeconds > 0) {
        _remainingSeconds--;

        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _isTimerActive = false;
          _canStartWork = true;
          _countdownTimer?.cancel();
        }

        notifyListeners();
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  // Clear timer state
  Future<void> clearTimerState(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('arrival_time_$serviceId');
      await prefs.remove('has_arrived_$serviceId');

      if (_currentServiceId == serviceId) {
        await prefs.remove('timer_service_id');
        _stopAutoRefresh();
        _resetTimerState();
      }
    } catch (e) {
      print('Error clearing timer state: $e');
    }
  }

  // Reset timer state
  void _resetTimerState() {
    _remainingSeconds = 600;
    _isTimerActive = false;
    _hasArrived = false;
    _canStartWork = false;
    _arrivalTime = null;
    _currentServiceId = null;
    _currentStatus = null;
    _cachedServiceData = null;
    _countdownTimer?.cancel();
    notifyListeners();
  }

  // Force refresh service data
  Future<void> forceRefresh(String serviceId) async {
    await _checkServiceStatus(serviceId);
  }

  // Check if timer is active for a specific service
  bool isTimerActiveForService(String serviceId) {
    return _currentServiceId == serviceId && _isTimerActive;
  }

  // Check if can start work for a specific service
  bool canStartWorkForService(String serviceId) {
    return _currentServiceId == serviceId && _canStartWork;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopAutoRefresh();
    super.dispose();
  }
}
