import 'dart:convert';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:first_flutter/widgets/user_service_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../NATS Service/NatsService.dart';
import '../../widgets/user_interested_provider_list_card.dart';
import 'navigation/user_service_tab_body/ServiceModel.dart';
import 'navigation/user_service_tab_body/ServiceProvider.dart';
import 'BookProviderProvider.dart';

class AssignedandCompleteUserServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const AssignedandCompleteUserServiceDetailsScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<AssignedandCompleteUserServiceDetailsScreen> createState() =>
      _AssignedandCompleteUserServiceDetailsScreenState();
}

class _AssignedandCompleteUserServiceDetailsScreenState
    extends State<AssignedandCompleteUserServiceDetailsScreen> {
  final NatsService _natsService = NatsService();
  Map<String, dynamic>? _serviceData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ensure NATS is connected
      if (!_natsService.isConnected) {
        await _natsService.connect();
      }

      // Prepare request data
      final reqData = {
        'service_id': widget.serviceId,
      };

      debugPrint('📤 Sending request to service.user.info.details: $reqData');

      // Make NATS request
      final response = await _natsService.request(
        'service.user.info.details',
        jsonEncode(reqData),
        timeout: const Duration(seconds: 5),
      );

      if (response != null && response.isNotEmpty) {
        final decodedData = jsonDecode(response);
        setState(() {
          _serviceData = decodedData;
          _isLoading = false;
        });
        debugPrint('✅ Service details received: $_serviceData');
      } else {
        setState(() {
          _errorMessage = 'No response received from server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch service details: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error fetching service details: $e');
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  List<String> _extractParticulars(Map<String, dynamic>? dynamicFields, Map<String, dynamic>? serviceData) {
    List<String> particulars = [];

    if (dynamicFields != null) {
      dynamicFields.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          particulars.add('$key: $value');
        }
      });
    }

    // Add duration info
    if (serviceData != null) {
      final durationValue = serviceData['duration_value'];
      final durationUnit = serviceData['duration_unit'];
      if (durationValue != null && durationUnit != null) {
        particulars.add('$durationValue $durationUnit');
      }
    }

    return particulars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.moyoScaffoldGradient,
      appBar: UserOnlyTitleAppbar(title: "Service Details"),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchServiceDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Consumer2<ServiceProvider, BookProviderProvider>(
        builder: (context, serviceProvider, bookProviderProvider, child) {
          final user = _serviceData?['user'];
          final dynamicFields = _serviceData?['dynamic_fields'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 16,
                children: [
                  UserServiceDetails(
                    category: _serviceData?['category'] ?? 'N/A',
                    subCategory: _serviceData?['service'] ?? 'N/A',
                    date: _formatDate(_serviceData?['schedule_date']),
                    pin: _serviceData?['start_otp'] ?? 'N/A',
                    providerPhone: user?['mobile'] ?? 'N/A',
                    dp: user?['image'] ?? 'https://picsum.photos/200/200',
                    name: user != null
                        ? '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim()
                        : 'N/A',
                    rating: '4.5', // You may want to get actual rating from API
                    status: _serviceData?['status'] ?? 'N/A',
                    durationType: _serviceData?['service_mode'] == 'hrs'
                        ? 'Hourly'
                        : (_serviceData?['service_mode'] ?? 'N/A'),
                    duration: _serviceData?['duration_value'] != null && _serviceData?['duration_unit'] != null
                        ? '${_serviceData!['duration_value']} ${_serviceData!['duration_unit']}'
                        : 'N/A',
                    price: _serviceData?['budget']?.toString() ?? 'N/A',
                    address: _serviceData?['location'] ?? 'N/A',
                    particular: _extractParticulars(dynamicFields, _serviceData),
                    description: _serviceData?['description'] ?? 'No description available',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Don't disconnect NATS in dispose as per requirement
  @override
  void dispose() {
    // Not disconnecting NATS service as requested
    super.dispose();
  }
}