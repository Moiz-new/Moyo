import 'dart:async';
import 'dart:convert';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServiceTimerProvider extends ChangeNotifier {
  final String serviceId;
  final String authToken;

  Timer? _timer;
  Timer? _apiTimer;

  // Timer state
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;
  int _totalDurationMinutes = 0;
  DateTime? _startedAt;
  DateTime? _lastSyncTime;
  bool _isCompleted = false;
  bool _isLoading = true;
  bool _isExtraTime = false;
  String? _error;

  // Service data
  Map<String, dynamic>? _serviceData;

  ServiceTimerProvider({required this.serviceId, required this.authToken}) {
    _initialize();
  }

  // Getters
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds => _remainingSeconds;
  int get totalDurationMinutes => _totalDurationMinutes;
  int get allocatedSeconds => _totalDurationMinutes * 60;
  DateTime? get startedAt => _startedAt;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;
  bool get isExtraTime => _isExtraTime;
  String? get error => _error;
  Map<String, dynamic>? get serviceData => _serviceData;

  Future<void> _initialize() async {
    await _loadTimerState();
    await _fetchRemainingTime();
    _startLocalTimer();
    _startPeriodicApiCalls();
  }

  Future<void> _loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStartTime = prefs.getString('timer_start_$serviceId');
      final savedLastSync = prefs.getString('timer_last_sync_$serviceId');
      final savedElapsed = prefs.getInt('timer_elapsed_$serviceId') ?? 0;
      final savedRemaining = prefs.getInt('timer_remaining_$serviceId') ?? 0;
      final savedDuration = prefs.getInt('timer_duration_$serviceId') ?? 0;

      if (savedStartTime != null) {
        _startedAt = DateTime.parse(savedStartTime);
        _lastSyncTime = savedLastSync != null ? DateTime.parse(savedLastSync) : null;

        // Calculate offline elapsed time
        if (_lastSyncTime != null) {
          final offlineSeconds = DateTime.now().difference(_lastSyncTime!).inSeconds;
          _elapsedSeconds = savedElapsed + offlineSeconds;
          _remainingSeconds = (savedRemaining - offlineSeconds).clamp(0, savedRemaining);
        } else {
          _elapsedSeconds = savedElapsed;
          _remainingSeconds = savedRemaining;
        }

        _totalDurationMinutes = savedDuration;
        _isExtraTime = _remainingSeconds <= 0 && !_isCompleted;

        print('Loaded offline state: elapsed=$_elapsedSeconds, remaining=$_remainingSeconds');
      }
    } catch (e) {
      print('Error loading timer state: $e');
    }
  }

  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_startedAt != null) {
        await prefs.setString('timer_start_$serviceId', _startedAt!.toIso8601String());
      }
      await prefs.setString('timer_last_sync_$serviceId', DateTime.now().toIso8601String());
      await prefs.setInt('timer_elapsed_$serviceId', _elapsedSeconds);
      await prefs.setInt('timer_remaining_$serviceId', _remainingSeconds);
      await prefs.setInt('timer_duration_$serviceId', _totalDurationMinutes);
    } catch (e) {
      print('Error saving timer state: $e');
    }
  }

  // Helper method to format DateTime to IST timezone string
  String _formatToIST(DateTime dateTime) {
    // Convert to IST (UTC+5:30)
    final istDateTime = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));

    // Format as "YYYY-MM-DD HH:mm:ss+00"
    final year = istDateTime.year.toString().padLeft(4, '0');
    final month = istDateTime.month.toString().padLeft(2, '0');
    final day = istDateTime.day.toString().padLeft(2, '0');
    final hour = istDateTime.hour.toString().padLeft(2, '0');
    final minute = istDateTime.minute.toString().padLeft(2, '0');
    final second = istDateTime.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second+00';
  }

  Future<void> _fetchRemainingTime() async {
    try {
      // Get current time and format it to IST
      final now = DateTime.now();
      final currentTime = _formatToIST(now);

      print('Sending current_time (IST): $currentTime');

      final response = await http.post(
        Uri.parse('$base_url/bid/api/service/remaining-time'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'current_time': currentTime,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['error'] != null) {
        _error = data['error'];
        _isLoading = false;
        notifyListeners();
        print('API Error: ${data['error']}');
        return;
      }

      if (response.statusCode == 200) {
        if (data['success'] == true && data['data'] != null) {
          final serviceData = data['data'];

          // API se exact values lete hain
          final apiElapsedMinutes = ((serviceData['elapsed_minutes'] ?? 0) as num).toDouble();
          final apiRemainingSeconds = ((serviceData['remaining_seconds'] ?? 0) as num).toInt();

          // Elapsed seconds ko API ke exact value se set karte hain
          _elapsedSeconds = (apiElapsedMinutes * 60).round();
          _remainingSeconds = apiRemainingSeconds;
          _totalDurationMinutes = ((serviceData['total_duration_minutes'] ?? 0) as num).toInt();
          _isCompleted = (serviceData['is_completed'] ?? false) as bool;

          // Check if duration is defined
          if (_totalDurationMinutes == 0) {
            _error = 'Service duration not defined. Please contact support.';
            _isLoading = false;
            notifyListeners();
            return;
          }

          if (serviceData['started_at'] != null) {
            _startedAt = DateTime.parse(serviceData['started_at']);
          }

          // Sync time save karte hain
          _lastSyncTime = DateTime.now();

          // Check if in extra time
          _isExtraTime = _remainingSeconds <= 0 && !_isCompleted;

          // State save karte hain
          await _saveTimerState();

          _isLoading = false;
          _error = null;

          if (_isCompleted) {
            _stopTimers();
          }

          print('Synced with API: elapsed=$_elapsedSeconds, remaining=$_remainingSeconds, extra=$_isExtraTime');
          notifyListeners();
        } else {
          _error = data['message'] ?? 'Invalid response from server';
          _isLoading = false;
          notifyListeners();
        }
      } else if (response.statusCode == 404) {
        _error = 'Service not found';
        _isLoading = false;
        notifyListeners();
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized. Please login again';
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Server error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } on TimeoutException catch (e) {
      _error = 'Request timed out. Please check your internet connection.';
      _isLoading = false;
      notifyListeners();
      print('Timeout Error: $e');
    } on FormatException catch (e) {
      _error = 'Invalid response format from server';
      _isLoading = false;
      notifyListeners();
      print('Format Error: $e');
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print('Error in _fetchRemainingTime: $e');
    }
  }

  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCompleted) {
        // Elapsed time badhaate hain
        _elapsedSeconds++;

        // Remaining time kam karte hain (agar positive hai to)
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }

        // Extra time check karte hain
        if (_remainingSeconds <= 0 && !_isExtraTime) {
          _isExtraTime = true;
          print('Entered extra time at elapsed: $_elapsedSeconds');
        }

        // Har 5 second mein state save karte hain
        if (_elapsedSeconds % 5 == 0) {
          _saveTimerState();
        }

        notifyListeners();
      }
    });
  }

  void _startPeriodicApiCalls() {
    // Har 30 seconds mein API se sync karte hain
    _apiTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isCompleted && _error == null) {
        print('Auto-syncing with API...');
        _fetchRemainingTime();
      }
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _apiTimer?.cancel();
  }

  String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String formatMinutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Color getTimerColor() {
    return _isExtraTime ? Colors.red : const Color(0xFF4CAF50);
  }

  // Get extra time elapsed (only when in extra time)
  int getExtraTimeSeconds() {
    if (_isExtraTime) {
      // Extra time = elapsed - allocated
      final extraTime = _elapsedSeconds - allocatedSeconds;
      return extraTime > 0 ? extraTime : 0;
    }
    return 0;
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _fetchRemainingTime();
  }

  // Manual sync method
  Future<void> syncWithServer() async {
    print('Manual sync requested');
    await _fetchRemainingTime();
  }

  @override
  void dispose() {
    _stopTimers();
    _saveTimerState();
    super.dispose();
  }
}