// providers/earnings_provider.dart

import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'EarningsResponse.dart';

class EarningsProvider extends ChangeNotifier {
  EarningsResponse? _earningsData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'Month'; // Month or Day

  EarningsResponse? get earningsData => _earningsData;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  DateTime get selectedDate => _selectedDate;

  String get filterType => _filterType;

  bool get hasDataForSelectedDate {
    if (_earningsData?.services == null) return false;
    return getFilteredServices().isNotEmpty;
  }

  Future<void> fetchEarnings({DateTime? date}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final providerAuthToken = prefs.getString('provider_auth_token');

      if (providerAuthToken == null || providerAuthToken.isEmpty) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final dateToUse = date ?? _selectedDate;

      // Month number for query parameter
      final monthNumber = dateToUse.month;

      // Format date based on filter type
      final formattedDate = _filterType == 'Month'
          ? '${dateToUse.year}-${dateToUse.month.toString().padLeft(2, '0')}'
          : '${dateToUse.year}-${dateToUse.month.toString().padLeft(2, '0')}-${dateToUse.day.toString().padLeft(2, '0')}';

      // Debug prints
      print('🔍 Filter Type: $_filterType');
      print('🔍 Selected Date: $dateToUse');
      print('🔍 Month Number: $monthNumber');
      print('🔍 Formatted Date: $formattedDate');

      final url = Uri.parse(
        '$base_url/bid/api/user/earnings?$monthNumber=$formattedDate',
      );

      print('🔍 API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $providerAuthToken',
          'Content-Type': 'application/json',
        },
      );

      print('✅ token: ${providerAuthToken}');
      print('✅ Response Status: ${response.statusCode}');
      print('✅ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _earningsData = EarningsResponse.fromJson(jsonData);
        _errorMessage = null;
        print('✅ Services Count: ${_earningsData?.services?.length ?? 0}');
      } else if (response.statusCode == 401) {
        _errorMessage = 'Unauthorized. Please login again.';
      } else {
        _errorMessage = 'Failed to load earnings: ${response.statusCode}';
      }
    } catch (e) {
      print('❌ Error: $e');
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void setDate(DateTime date) {
    _selectedDate = date;
    fetchEarnings(date: date);
  }

  void setFilterType(String type) {
    _filterType = type;
    fetchEarnings();
  }

  String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String getFormattedDate() {
    if (_filterType == 'Month') {
      return '${getMonthName(_selectedDate.month)} ${_selectedDate.year}';
    } else {
      return '${_selectedDate.day} ${getMonthName(_selectedDate.month)} ${_selectedDate.year}';
    }
  }

  double getTodayEarnings() {
    if (_earningsData?.services == null) return 0.0;

    final today = DateTime.now();
    double total = 0.0;

    for (var service in _earningsData!.services!) {
      if (service.startedAt != null &&
          service.startedAt!.year == today.year &&
          service.startedAt!.month == today.month &&
          service.startedAt!.day == today.day) {
        total += double.tryParse(service.totalAmount ?? '0') ?? 0.0;
      }
    }

    return total;
  }

  double getWeekEarnings() {
    if (_earningsData?.services == null) return 0.0;

    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    double total = 0.0;

    for (var service in _earningsData!.services!) {
      if (service.startedAt != null && service.startedAt!.isAfter(weekAgo)) {
        total += double.tryParse(service.totalAmount ?? '0') ?? 0.0;
      }
    }

    return total;
  }

  double getMonthEarnings() {
    return double.tryParse(_earningsData?.totalEarnings ?? '0') ?? 0.0;
  }

  int getTotalServices() {
    return _earningsData?.totalServices ?? 0;
  }

  List<ServiceEarning> getFilteredServices() {
    if (_earningsData?.services == null) return [];

    if (_filterType == 'Day') {
      return _earningsData!.services!.where((service) {
        if (service.startedAt == null) return false;
        return service.startedAt!.year == _selectedDate.year &&
            service.startedAt!.month == _selectedDate.month &&
            service.startedAt!.day == _selectedDate.day;
      }).toList();
    }

    return _earningsData!.services ?? [];
  }
}
