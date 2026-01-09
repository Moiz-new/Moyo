// providers/earnings_provider.dart

import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'EarningsResponse.dart';

enum FilterType { all, day, month, range }

class EarningsProvider extends ChangeNotifier {
  EarningsResponse? _earningsData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  FilterType _filterType = FilterType.month;
  DateTime? _rangeStartDate;
  DateTime? _rangeEndDate;

  EarningsResponse? get earningsData => _earningsData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  FilterType get filterType => _filterType;
  DateTime? get rangeStartDate => _rangeStartDate;
  DateTime? get rangeEndDate => _rangeEndDate;

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
      String url = '$base_url/bid/api/user/earnings';

      // Build URL based on filter type
      switch (_filterType) {
        case FilterType.all:
        // No date parameters - fetch all earnings
          break;
        case FilterType.day:
        // Format: date=2025-01-15
          final formattedDate =
              '${dateToUse.year}-${dateToUse.month.toString().padLeft(2, '0')}-${dateToUse.day.toString().padLeft(2, '0')}';
          url += '?date=$formattedDate';
          break;
        case FilterType.month:
        // Format: month=2025-01
          final formattedMonth =
              '${dateToUse.year}-${dateToUse.month.toString().padLeft(2, '0')}';
          url += '?month=$formattedMonth';
          break;
        case FilterType.range:
        // Format: from=2025-01-01&to=2025-01-10
          if (_rangeStartDate != null && _rangeEndDate != null) {
            final fromDate =
                '${_rangeStartDate!.year}-${_rangeStartDate!.month.toString().padLeft(2, '0')}-${_rangeStartDate!.day.toString().padLeft(2, '0')}';
            final toDate =
                '${_rangeEndDate!.year}-${_rangeEndDate!.month.toString().padLeft(2, '0')}-${_rangeEndDate!.day.toString().padLeft(2, '0')}';
            url += '?from=$fromDate&to=$toDate';
          }
          break;
      }

      print('🔍 Filter Type: $_filterType');
      print('🔍 Selected Date: $dateToUse');
      print('🔍 API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $providerAuthToken',
          'Content-Type': 'application/json',
        },
      );

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

  void setFilterType(FilterType type) {
    _filterType = type;
    fetchEarnings();
  }

  void setDateRange(DateTime start, DateTime end) {
    _rangeStartDate = start;
    _rangeEndDate = end;
    _filterType = FilterType.range;
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
    switch (_filterType) {
      case FilterType.all:
        return 'All Time';
      case FilterType.day:
        return '${_selectedDate.day} ${getMonthName(_selectedDate.month)} ${_selectedDate.year}';
      case FilterType.month:
        return '${getMonthName(_selectedDate.month)} ${_selectedDate.year}';
      case FilterType.range:
        if (_rangeStartDate != null && _rangeEndDate != null) {
          return '${_rangeStartDate!.day} ${getMonthName(_rangeStartDate!.month)} - ${_rangeEndDate!.day} ${getMonthName(_rangeEndDate!.month)}';
        }
        return 'Select Range';
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

    switch (_filterType) {
      case FilterType.all:
      // Return all services
        return _earningsData!.services ?? [];

      case FilterType.day:
      // Filter by specific day
        return _earningsData!.services!.where((service) {
          if (service.startedAt == null) return false;
          return service.startedAt!.year == _selectedDate.year &&
              service.startedAt!.month == _selectedDate.month &&
              service.startedAt!.day == _selectedDate.day;
        }).toList();

      case FilterType.month:
      // Filter by month and year
        return _earningsData!.services!.where((service) {
          if (service.startedAt == null) return false;
          return service.startedAt!.year == _selectedDate.year &&
              service.startedAt!.month == _selectedDate.month;
        }).toList();

      case FilterType.range:
      // Filter by date range
        if (_rangeStartDate == null || _rangeEndDate == null) {
          return _earningsData!.services ?? [];
        }
        return _earningsData!.services!.where((service) {
          if (service.startedAt == null) return false;
          final serviceDate = DateTime(
            service.startedAt!.year,
            service.startedAt!.month,
            service.startedAt!.day,
          );
          final startDate = DateTime(
            _rangeStartDate!.year,
            _rangeStartDate!.month,
            _rangeStartDate!.day,
          );
          final endDate = DateTime(
            _rangeEndDate!.year,
            _rangeEndDate!.month,
            _rangeEndDate!.day,
          );
          return (serviceDate.isAtSameMomentAs(startDate) ||
              serviceDate.isAfter(startDate)) &&
              (serviceDate.isAtSameMomentAs(endDate) ||
                  serviceDate.isBefore(endDate));
        }).toList();
    }
  }
}