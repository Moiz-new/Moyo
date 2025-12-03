import 'dart:convert';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:first_flutter/widgets/user_service_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/user_interested_provider_list_card.dart';
import 'navigation/user_service_tab_body/ServiceModel.dart';
import 'navigation/user_service_tab_body/ServiceProvider.dart';
import 'BookProviderProvider.dart';

class UserServiceDetailsScreen extends StatefulWidget {
  const UserServiceDetailsScreen({super.key});

  @override
  State<UserServiceDetailsScreen> createState() =>
      _UserServiceDetailsScreenState();
}

class _UserServiceDetailsScreenState extends State<UserServiceDetailsScreen> {
  ServiceModel? _currentService;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final service =
      ModalRoute.of(context)?.settings.arguments as ServiceModel?;
      if (service != null) {
        _currentService = service;

        // ✅ Set current service in ServiceProvider (for NATS)
        context.read<ServiceProvider>().setCurrentService(service.id);

        _isInitialized = true;
        debugPrint('📋 Loaded service: ${service.id}');
      }
    }
  }

  Future<void> _handleBookProvider(
      BuildContext context,
      String serviceId,
      String providerId,
      String providerName,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: Text(
            'Are you sure you want to book $providerName for this service?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // ✅ Use BookProviderProvider for booking API
    final bookProvider = context.read<BookProviderProvider>();
    final success = await bookProvider.bookProvider(
      serviceId: serviceId,
      providerId: providerId,
    );

    if (success && mounted) {
      Navigator.pop(context, true); // ✅ Pass true to indicate success
      Navigator.pop(context, true); // ✅ Pass true to indicate success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Provider booked successfully!')),
      );
    }


    /*if (success) {
      final bookingData = bookProvider.bookingData;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              const Text('Booking Confirmed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provider $providerName has been booked successfully!'),
              const SizedBox(height: 16),
              if (bookingData != null) ...[
                const Text(
                  'Service OTPs:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Start OTP:'),
                          Text(
                            bookingData.startOtp,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('End OTP:'),
                          Text(
                            bookingData.endOtp,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please save these OTPs for service verification.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                bookProvider.clearBookingData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookProvider.bookingError ??
                'Failed to book provider. Please try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }*/
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

  String _getDurationType(ServiceModel service) {
    if (service.serviceMode == 'hrs') return 'Hourly';
    if (service.serviceMode == 'day') return 'Daily';
    return 'Fixed';
  }

  String _getDuration(ServiceModel service) {
    if (service.durationValue != null && service.durationUnit != null) {
      return '${service.durationValue} ${service.durationUnit}${service.durationValue! > 1 ? 's' : ''}';
    } else if (service.serviceDays != null) {
      return '${service.serviceDays} day${service.serviceDays! > 1 ? 's' : ''}';
    }
    return 'N/A';
  }

  List<String> _getParticulars(ServiceModel service) {
    List<String> particulars = [];

    if (service.serviceMode == 'hrs') {
      particulars.add('Hourly Service');
    } else if (service.serviceMode == 'day') {
      particulars.add('Daily Service');
    } else {
      particulars.add('Fixed Service');
    }

    if (service.durationValue != null && service.durationUnit != null) {
      particulars.add(
        '${service.durationValue} ${service.durationUnit}${service.durationValue! > 1 ? 's' : ''}',
      );
    }

    if (service.serviceDays != null && service.serviceDays! > 0) {
      particulars.add(
        '${service.serviceDays} Day${service.serviceDays! > 1 ? 's' : ''}',
      );
    }

    if (service.maxBudget != '0' && service.maxBudget != service.budget) {
      particulars.add('Budget: ₹${service.budget} - ₹${service.maxBudget}');
    }

    return particulars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.moyoScaffoldGradient,
      appBar: UserOnlyTitleAppbar(title: "Service Details"),
      body: Consumer2<ServiceProvider, BookProviderProvider>(
        builder: (context, serviceProvider, bookProviderProvider, child) {
          // ✅ Get NATS data from ServiceProvider
          final isConnected = serviceProvider.natsService.isConnected;
          final isListening = serviceProvider.isNatsListening;
          final interestedProviders = serviceProvider.interestedProviders;

          // ✅ Get booking state from BookProviderProvider
          final isBooking = bookProviderProvider.isBooking;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 16,
                children: [
                  UserServiceDetails(
                    category: "Home",
                    subCategory: "Cleaning",
                    date: "Dec 07, 2025",
                    pin: "2156",
                    providerPhone: "8890879707",
                    dp: "https://picsum.photos/200/200",
                    name: "Aarif Husain",
                    rating: "4.5",
                    status: "confirmed",
                    durationType: "Hourly",
                    duration: "4 hours",
                    price: "450",
                    address:
                    "Aarif Husain, Chacha Chai Zakir hotl k samne Tanzeem Nagar khajrana indore",
                    particular: ["Cooking", "Dessert", "5 Days", "4 People"],
                    description:
                    "This is the service description can write here which will be five line long",
                  ),

                  // ✅ NATS Connection Status from ServiceProvider
                  StreamBuilder<bool>(
                    stream: serviceProvider.natsService.connectionStream,
                    initialData: isConnected,
                    builder: (context, snapshot) {
                      final connected = snapshot.data ?? false;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: (connected && isListening)
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (connected && isListening)
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (connected && isListening)
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              color: (connected && isListening)
                                  ? Colors.green
                                  : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (connected && isListening)
                                  ? 'Connected • ${interestedProviders.length} provider(s) found'
                                  : connected
                                  ? 'Setting up...'
                                  : 'Reconnecting...',
                              style: TextStyle(
                                color: (connected && isListening)
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // ✅ Booking Loading State
                  if (isBooking)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorConstant.moyoOrange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('Booking provider...'),
                        ],
                      ),
                    ),

                  // ✅ Interested Providers List (from ServiceProvider NATS)
                  if (interestedProviders.isNotEmpty)
                    ...(interestedProviders.map((provider) {
                      return UserInterestedProviderListCard(
                        providerName: provider['providerName'] ?? 'Unknown',
                        gender: provider['gender'] ?? 'N/A',
                        age: provider['age'] ?? 'N/A',
                        distance: provider['distance'] != 'N/A'
                            ? '${provider['distance']} KM'
                            : 'N/A',
                        reachTime: provider['reachTime'] != 'N/A'
                            ? '${provider['reachTime']} min'
                            : 'N/A',
                        category: provider['category'] ?? 'N/A',
                        subCategory: provider['subCategory'] ?? 'N/A',
                        chargeRate: provider['chargeRate'] != 'N/A'
                            ? '₹${provider['chargeRate']}/Hour'
                            : 'N/A',
                        rating: provider['rating'] ?? '0.0',
                        experience: provider['experience'] ?? 'N/A',
                        dp: provider['dp'] ?? 'https://picsum.photos/200/200',
                        onBook: () {
                          if (_currentService != null) {
                            _handleBookProvider(
                              context,
                              _currentService!.id,
                              provider['providerId'] ?? '',
                              provider['providerName'] ?? 'Provider',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Service information not available',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    }).toList())
                  else
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for interested providers...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll be notified when providers show interest',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connected: $isConnected | Listening: $isListening',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}