import 'dart:async';
import 'dart:convert';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:first_flutter/widgets/user_service_details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../NATS Service/NatsService.dart';
import '../../widgets/ProviderConfirmServiceDetails.dart';

class ProviderServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ProviderServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ProviderServiceDetailsScreen> createState() =>
      _ProviderServiceDetailsScreenState();
}

class _ProviderServiceDetailsScreenState
    extends State<ProviderServiceDetailsScreen> {
  final NatsService _natsService = NatsService();
  Map<String, dynamic>? _serviceData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    try {
      // Connect to NATS if not already connected
      if (!_natsService.isConnected) {
        final connected = await _natsService.connect(
          url: 'nats://api.moyointernational.com:4222',
        );

        if (!connected) {
          setState(() {
            _errorMessage = 'Failed to connect to NATS server';
            _isLoading = false;
          });
          return;
        }
      }

      // Fetch service details initially
      await _fetchServiceDetails();

      // Start polling every 15 seconds
      _startPolling();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing: $e';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    // Cancel any existing timer to prevent duplicates
    _pollingTimer?.cancel();

    // Create a new timer that triggers every 15 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Only fetch if not currently fetching (prevents conflicts)
      if (!_isFetching && mounted) {
        _fetchServiceDetails(isPolling: true);
      }
    });
  }

  Future<void> _fetchServiceDetails({bool isPolling = false}) async {
    // Prevent concurrent API calls
    if (_isFetching) return;

    _isFetching = true;

    try {
      // Get provider_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final providerToken = prefs.getString('provider_auth_token');

      if (providerToken == null) {
        setState(() {
          _errorMessage = 'Provider authentication token not found';
          _isLoading = false;
        });
        return;
      }

      String? providerId;
      try {
        // Try to decode JWT token
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
          // Token might be the provider_id itself
          providerId = providerToken;
        }
      } catch (e) {
        // If decode fails, assume token is the provider_id
        providerId = providerToken;
      }

      if (providerId == null) {
        setState(() {
          _errorMessage = 'Could not extract provider ID from token';
          _isLoading = false;
        });
        return;
      }

      final requestData = jsonEncode({
        'service_id': widget.serviceId,
        'provider_id': providerId,
      });

      final response = await _natsService.request(
        'service.info.details',
        requestData,
        timeout: const Duration(seconds: 5),
      );

      if (response != null) {
        final responseData = jsonDecode(response);

        // ✅ FIX: Extract the 'data' field from the response
        if (responseData['success'] == true && responseData['data'] != null) {
          if (mounted) {
            setState(() {
              _serviceData = responseData['data']; // Use 'data' field, not the root
              _isLoading = false;
            });
          }
        } else {
          if (mounted && !isPolling) {
            setState(() {
              _errorMessage = 'Invalid response format or unsuccessful request';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted && !isPolling) {
          // Only show error on initial load, not during polling
          setState(() {
            _errorMessage = 'No response received from server';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && !isPolling) {
        // Only show error on initial load, not during polling
        setState(() {
          _errorMessage = 'Error fetching service details: $e';
          _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return ' at $displayHour:$minute $period';
      }
      return ' at $timeString';
    } catch (e) {
      return ' at $timeString';
    }
  }

  String _formatDuration(Map<String, dynamic> data) {
    final mode = data['service_mode'];
    final value = data['duration_value'];
    final unit = data['duration_unit'];

    if (mode == null || value == null) return 'N/A';

    if (mode == 'hrs') {
      final unitText = unit ?? 'hour';
      return '$value $unitText${value > 1 ? 's' : ''}';
    } else if (mode == 'days') {
      return '$value day${value > 1 ? 's' : ''}';
    }
    return 'N/A';
  }

  String _getDurationType(String? mode) {
    if (mode == null) return 'One Time';
    if (mode == 'hrs') return 'Hourly';
    if (mode == 'days') return 'Daily';
    return 'One Time';
  }

  List<String> _buildParticulars(Map<String, dynamic> data) {
    final List<String> particulars = [];

    // Add service type
    final service = data['service'];
    if (service != null && service.toString().isNotEmpty) {
      particulars.add(service.toString());
    }

    // Add tenure
    final tenure = data['tenure'];
    if (tenure != null && tenure.toString().isNotEmpty) {
      particulars.add(tenure.toString().replaceAll('_', ' '));
    }

    // Add duration
    final duration = _formatDuration(data);
    if (duration != 'N/A') {
      particulars.add(duration);
    }

    // Add service type (instant/scheduled)
    final serviceType = data['service_type'];
    if (serviceType != null && serviceType.toString().isNotEmpty) {
      particulars.add('Type: ${serviceType.toString()}');
    }

    // Add payment method
    final paymentMethod = data['payment_method'];
    if (paymentMethod != null && paymentMethod.toString().isNotEmpty) {
      particulars.add('Payment: ${paymentMethod.toString()}');
    }

    // Add dynamic fields if available
    final dynamicFields = data['dynamic_fields'];
    if (dynamicFields != null && dynamicFields is Map<String, dynamic>) {
      dynamicFields.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          final formattedKey = key.replaceAll('_', ' ');
          particulars.add('$formattedKey: $value');
        }
      });
    }

    return particulars;
  }

  @override
  void dispose() {
    // Cancel the polling timer to prevent memory leaks
    _pollingTimer?.cancel();
    // Don't disconnect if other parts of app might be using it
    // _natsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(_errorMessage);
    return Scaffold(
      backgroundColor: ColorConstant.moyoScaffoldGradient,
      appBar: UserOnlyTitleAppbar(title: "Service Details"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeAndFetchData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : _serviceData == null
          ? const Center(child: Text('No service data available'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProviderConfirmServiceDetails(
                isProvider: true,
                category: _serviceData!['category']?.toString() ?? 'N/A',
                serviceId: _serviceData!['id']?.toString() ?? 'N/A',
                subCategory:
                _serviceData!['service']?.toString() ??
                    _serviceData!['title']?.toString() ??
                    'N/A',
                date:
                _formatDate(_serviceData!['schedule_date']) +
                    _formatTime(_serviceData!['schedule_time']),
                pin: _serviceData!['start_otp']?.toString() ?? 'N/A',
                providerPhone:
                _serviceData!['user']?['mobile']?.toString() ?? 'N/A',
                dp:
                _serviceData!['user']?['image']?.toString() ??
                    'https://picsum.photos/200/200',
                name:
                '${_serviceData!['user']?['firstname']?.toString() ?? ''} ${_serviceData!['user']?['lastname']?.toString() ?? ''}'
                    .trim()
                    .isEmpty
                    ? 'N/A'
                    : '${_serviceData!['user']?['firstname']?.toString() ?? ''} ${_serviceData!['user']?['lastname']?.toString() ?? ''}'
                    .trim(),
                rating: "4.5",
                // Rating not in response, using default
                status: _serviceData!['status']?.toString() ?? 'pending',
                durationType: _getDurationType(
                  _serviceData!['service_mode']?.toString(),
                ),
                duration: _formatDuration(_serviceData!),
                price:
                _serviceData!['budget']?.toString() ??
                    _serviceData!['bid']?['amount']?.toString() ??
                    '0',
                address: _serviceData!['location']?.toString() ?? 'N/A',
                particular: _buildParticulars(_serviceData!),
                description:
                _serviceData!['description']?.toString() ?? 'N/A',
                user_id: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}