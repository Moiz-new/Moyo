import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/provider_service_list_card.dart';
import '../../confirm_provider_service_details_screen.dart';
import '../../provider_service_details_screen.dart';

class ProviderServiceApi {
  static const String baseUrl =
      'https://api.moyointernational.com/bid/api/service';

  Future<List<ServiceHistory>> getProviderServiceHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token') ?? '';

      print('Token: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/provider-service-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Check if response has the expected structure
        if (jsonResponse.containsKey('services') &&
            jsonResponse['services'] is List) {
          final List<dynamic> servicesJson = jsonResponse['services'];
          return servicesJson
              .map((json) => ServiceHistory.fromJson(json))
              .toList();
        } else if (jsonResponse.containsKey('success') &&
            jsonResponse['success'] == true &&
            jsonResponse.containsKey('services')) {
          final List<dynamic> servicesJson = jsonResponse['services'];
          return servicesJson
              .map((json) => ServiceHistory.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
          'Failed to load service history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getProviderServiceHistory: $e');
      throw Exception('Error: $e');
    }
  }
}

class ServiceHistory {
  final String id;
  final String title;
  final String category;
  final String service;
  final String description;
  final String userId;
  final String budget;
  final String maxBudget;
  final String tenure;
  final String? scheduleDate;
  final String? scheduleTime;
  final String serviceType;
  final String location;
  final String latitude;
  final String longitude;
  final String serviceMode;
  final int? durationValue;
  final String? durationUnit;
  final String? serviceDays;
  final String? startDate;
  final String? endDate;
  final int extraTimeMinutes;
  final String? assignedProviderId;
  final String status;
  final String? reason;
  final String? startedAt;
  final String? arrivedAt;
  final String? endedAt;
  final String? confirmedAt;
  final String? startOtp;
  final String? endOtp;
  final String paymentMethod;
  final String paymentType;
  final String? finalAmount;
  final Map<String, dynamic> dynamicFields;
  final String? cancelledBy;
  final String? cancelReason;
  final String? cancelledAt;
  final String createdAt;
  final String updatedAt;
  final String totalBids;
  final List<Bid> bids;
  final Customer customer;
  final String createdAtFormatted;

  ServiceHistory({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.userId,
    required this.budget,
    required this.maxBudget,
    required this.tenure,
    this.scheduleDate,
    this.scheduleTime,
    required this.serviceType,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.serviceMode,
    this.durationValue,
    this.durationUnit,
    this.serviceDays,
    this.startDate,
    this.endDate,
    required this.extraTimeMinutes,
    this.assignedProviderId,
    required this.status,
    this.reason,
    this.startedAt,
    this.arrivedAt,
    this.endedAt,
    this.confirmedAt,
    this.startOtp,
    this.endOtp,
    required this.paymentMethod,
    required this.paymentType,
    this.finalAmount,
    required this.dynamicFields,
    this.cancelledBy,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.totalBids,
    required this.bids,
    required this.customer,
    required this.createdAtFormatted,
  });

  factory ServiceHistory.fromJson(Map<String, dynamic> json) {
    return ServiceHistory(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '0',
      maxBudget: json['max_budget']?.toString() ?? '0',
      tenure: json['tenure']?.toString() ?? '',
      scheduleDate: json['schedule_date']?.toString(),
      scheduleTime: json['schedule_time']?.toString(),
      serviceType: json['service_type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      serviceMode: json['service_mode']?.toString() ?? '',
      durationValue: json['duration_value'] != null
          ? int.tryParse(json['duration_value'].toString())
          : null,
      durationUnit: json['duration_unit']?.toString(),
      serviceDays: json['service_days']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      extraTimeMinutes: json['extra_time_minutes'] != null
          ? int.tryParse(json['extra_time_minutes'].toString()) ?? 0
          : 0,
      assignedProviderId: json['assigned_provider_id']?.toString(),
      status: json['status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      startedAt: json['started_at']?.toString(),
      arrivedAt: json['arrived_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      startOtp: json['start_otp']?.toString(),
      endOtp: json['end_otp']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentType: json['payment_type']?.toString() ?? '',
      finalAmount: json['final_amount']?.toString(),
      dynamicFields: json['dynamic_fields'] is Map
          ? Map<String, dynamic>.from(json['dynamic_fields'])
          : {},
      cancelledBy: json['cancelled_by']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      cancelledAt: json['cancelled_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      totalBids: json['total_bids']?.toString() ?? '0',
      bids:
          (json['bids'] as List?)
              ?.map((b) => Bid.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : Customer.empty(),
      createdAtFormatted: json['created_at_formatted']?.toString() ?? '',
    );
  }
}

class Bid {
  final String notes;
  final double amount;
  final int bidId;
  final String status;
  final String createdAt;
  final int providerId;

  Bid({
    required this.notes,
    required this.amount,
    required this.bidId,
    required this.status,
    required this.createdAt,
    required this.providerId,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      notes: json['notes']?.toString() ?? '',
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString()) ?? 0.0
          : 0.0,
      bidId: json['bid_id'] != null
          ? int.tryParse(json['bid_id'].toString()) ?? 0
          : 0,
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      providerId: json['provider_id'] != null
          ? int.tryParse(json['provider_id'].toString()) ?? 0
          : 0,
    );
  }
}

class Customer {
  final int id;
  final String firstname;
  final String lastname;
  final String username;
  final String email;
  final String mobile;
  final String gender;
  final int age;
  final String image;
  final bool isregister;
  final bool isProvider;
  final bool isBlocked;
  final String referralCode;
  final double wallet;
  final bool emailVerified;

  Customer({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.email,
    required this.mobile,
    required this.gender,
    required this.age,
    required this.image,
    required this.isregister,
    required this.isProvider,
    required this.isBlocked,
    required this.referralCode,
    required this.wallet,
    required this.emailVerified,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      age: json['age'] != null ? int.tryParse(json['age'].toString()) ?? 0 : 0,
      image: json['image']?.toString() ?? '',
      isregister: json['isregister'] == true || json['isregister'] == 1,
      isProvider: json['is_provider'] == true || json['is_provider'] == 1,
      isBlocked: json['is_blocked'] == true || json['is_blocked'] == 1,
      referralCode: json['referral_code']?.toString() ?? '',
      wallet: json['wallet'] != null
          ? double.tryParse(json['wallet'].toString()) ?? 0.0
          : 0.0,
      emailVerified:
          json['email_verified'] == true || json['email_verified'] == 1,
    );
  }

  factory Customer.empty() {
    return Customer(
      id: 0,
      firstname: '',
      lastname: '',
      username: '',
      email: '',
      mobile: '',
      gender: '',
      age: 0,
      image: '',
      isregister: false,
      isProvider: false,
      isBlocked: false,
      referralCode: '',
      wallet: 0.0,
      emailVerified: false,
    );
  }
}

// ============================================================================
// 3. PROVIDER STATE MANAGEMENT (No changes needed)
// File: lib/providers/provider_service_provider.dart
// ============================================================================

class ProviderServiceProvider with ChangeNotifier {
  final ProviderServiceApi _api = ProviderServiceApi();

  List<ServiceHistory> _services = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceHistory> get services => _services;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> fetchServiceHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _api.getProviderServiceHistory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ProviderConfirmedService extends StatefulWidget {
  const ProviderConfirmedService({super.key});

  @override
  State<ProviderConfirmedService> createState() =>
      _ProviderConfirmedServiceState();
}

class _ProviderConfirmedServiceState extends State<ProviderConfirmedService> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderServiceProvider>().fetchServiceHistory();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _getDuration(ServiceHistory service) {
    // Check if it's task-based
    if (service.serviceMode == 'task' || service.tenure == 'task') {
      return 'Task';
    }

    // Check if duration values exist
    if (service.durationValue != null && service.durationUnit != null) {
      return '${service.durationValue} ${service.durationUnit}';
    }

    // Fallback to tenure
    return service.tenure;
  }

  String _getStatus(ServiceHistory service) {
    // Priority order for status determination:

    // 1. Check if cancelled
    if (service.status.toLowerCase() == 'cancelled') {
      return 'Cancelled';
    }

    // 2. Check if closed/completed
    if (service.status.toLowerCase() == 'closed') {
      return 'Completed';
    }

    // 3. Check if confirmed
    if (service.confirmedAt != null && service.confirmedAt!.isNotEmpty) {
      return 'Confirmed';
    }

    // 4. Check if assigned
    if (service.status.toLowerCase() == 'assigned' ||
        service.assignedProviderId != null) {
      return 'Assigned';
    }

    // 5. Check if started
    if (service.startedAt != null && service.startedAt!.isNotEmpty) {
      return 'In Progress';
    }

    // 6. Check if has bids
    if (service.bids.isNotEmpty) {
      return 'Bided';
    }

    // 7. Return the actual status from API
    return service.status.isNotEmpty
        ? service.status[0].toUpperCase() + service.status.substring(1)
        : 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProviderServiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
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
                      'Error loading services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchServiceHistory(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No services yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Services will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchServiceHistory(),
            child: ListView.builder(
              itemCount: provider.services
                  .where((service) => _getStatus(service) != 'Pending')
                  .length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                // Filter out pending services
                final filteredServices = provider.services
                    .where((service) => _getStatus(service) != 'Pending')
                    .toList();

                final service = filteredServices[index];

                print(service.status);
                return ProviderServiceListCard(
                  category: service.category,
                  subCategory: service.service,
                  date: _formatDate(service.createdAt),
                  dp: service.customer.image,
                  price: service.budget,
                  duration: _getDuration(service),
                  priceBy: service.tenure == 'task' ? 'Task' : 'Hourly',
                  providerCount: int.tryParse(service.totalBids) ?? 0,
                  status: _getStatus(service),
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConfirmProviderServiceDetailsScreen(
                              serviceId: service.id,
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
