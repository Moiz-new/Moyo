import 'dart:convert';
import 'dart:async';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:first_flutter/widgets/user_service_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:dart_nats/dart_nats.dart';
import '../../NATS Service/NatsService.dart';
import '../../widgets/user_interested_provider_list_card.dart';
import '../provider_screens/navigation/ServiceTimerScreen.dart';
import 'navigation/RazorpayProvider.dart';
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
  Map<String, dynamic>? _locationData;
  bool _isLoading = true;
  String? _errorMessage;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  String? _arrivalTime;
  Timer? _locationUpdateTimer;
  bool _isMapReady = false;
  Subscription? _serviceUpdateSubscription;
  Subscription? _locationUpdateSubscription;
  Subscription? _genericUpdateSubscription;

  static const String GOOGLE_MAPS_API_KEY =
      'AIzaSyBqTGBtJYtoRpvJFpF6tls1jcwlbiNcEVI';

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    try {
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

      await _fetchServiceDetails();
      await _fetchLocationDetails();

      _setupRealtimeListeners();

      // CHANGED: Update every 1 second instead of 10
      _locationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) {
        _fetchServiceDetails(); // ADDED: Fetch service details too
        _fetchLocationDetails();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing: $e';
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeListeners() {
    try {
      final serviceUpdateSubject = 'service.update.${widget.serviceId}';

      _serviceUpdateSubscription = _natsService.subscribe(
        serviceUpdateSubject,
        (message) {
          try {
            final data = jsonDecode(message);
            if (mounted) {
              setState(() {
                _serviceData = data;
              });
            }
          } catch (e) {}
        },
      );

      // Listen for location updates
      final locationUpdateSubject =
          'service.location.update.${widget.serviceId}';

      _locationUpdateSubscription = _natsService.subscribe(
        locationUpdateSubject,
        (message) {
          try {
            final data = jsonDecode(message);
            if (mounted) {
              setState(() {
                _locationData = data;
              });
            }
            if (_isMapReady) {
              _setupMap(animate: true);
            }
          } catch (e) {}
        },
      );

      // Generic service updates listener (if available)
      final genericServiceSubject = 'service.updates';
      _genericUpdateSubscription = _natsService.subscribe(
        genericServiceSubject,
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['service_id'] == widget.serviceId) {
              _fetchServiceDetails();
            }
          } catch (e) {}
        },
      );
    } catch (e) {}
  }

  Future<void> _fetchServiceDetails() async {
    try {
      // CHANGED: Don't show loading on subsequent updates
      final isFirstLoad = _serviceData == null;
      if (isFirstLoad) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      if (!_natsService.isConnected) {
        await _natsService.connect();
      }

      final reqData = {'service_id': widget.serviceId};

      final response = await _natsService.request(
        'service.user.info.details',
        jsonEncode(reqData),
        timeout: const Duration(seconds: 5),
      );

      if (response != null && response.isNotEmpty) {
        final decodedData = jsonDecode(response);

        // Check if response has 'data' wrapper
        Map<String, dynamic> serviceData;
        if (decodedData.containsKey('data')) {
          // Response is wrapped in 'data'
          serviceData = decodedData['data'];
        } else {
          // Response is at root level
          serviceData = decodedData;
        }

        if (mounted) {
          setState(() {
            _serviceData = serviceData;
            // CHANGED: Only set isLoading false on first load
            if (isFirstLoad) {
              _isLoading = false;
            }
          });
        }
      } else {
        if (mounted && isFirstLoad) {
          setState(() {
            _errorMessage = 'No response received from server';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted && _serviceData == null) {
        setState(() {
          _errorMessage = 'Failed to fetch service details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLocationDetails() async {
    try {
      final requestData = jsonEncode({'service_id': widget.serviceId});

      final response = await _natsService.request(
        'service.location.info',
        requestData,
        timeout: const Duration(seconds: 3),
      );

      if (response != null) {
        final data = jsonDecode(response);
        if (mounted) {
          // CHANGED: Silently update without showing any loading
          setState(() {
            _locationData = data;
          });
        }

        if (_isMapReady) {
          _setupMap(animate: _markers.isNotEmpty);
        }
      }
    } catch (e) {
      // CHANGED: Quietly log error, don't show to user
    }
  }

  Future<List<LatLng>> _getDirectionsRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$GOOGLE_MAPS_API_KEY&mode=driving';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];

            final legs = route['legs'] as List;
            if (legs.isNotEmpty) {
              final duration = legs[0]['duration'];
              if (duration != null) {
                final durationValue = duration['value'];
                if (mounted) {
                  setState(() {
                    _arrivalTime = (durationValue / 60).round().toString();
                  });
                }
              }
            }

            final polylinePoints = route['overview_polyline']['points'];
            PolylinePoints polylinePointsDecoder = PolylinePoints(apiKey: '');
            List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
              polylinePoints,
            );

            return decodedPoints
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
          }
        }
      }

      return [origin, destination];
    } catch (e) {
      print('Error fetching directions: $e');
      return [origin, destination];
    }
  }

  void _setupMap({bool animate = false}) async {
    if (_locationData == null) return;

    final serviceLat = double.tryParse(
      _locationData!['latitude']?.toString() ?? '0',
    );
    final serviceLng = double.tryParse(
      _locationData!['longitude']?.toString() ?? '0',
    );
    final providerLat = double.tryParse(
      _locationData!['provider']?['latitude']?.toString() ?? '0',
    );
    final providerLng = double.tryParse(
      _locationData!['provider']?['longitude']?.toString() ?? '0',
    );

    if (serviceLat == null ||
        serviceLng == null ||
        providerLat == null ||
        providerLng == null) {
      return;
    }

    final providerLocation = LatLng(providerLat, providerLng);
    final serviceLocation = LatLng(serviceLat, serviceLng);

    final distance = _calculateDistance(
      providerLat,
      providerLng,
      serviceLat,
      serviceLng,
    );
    final fallbackTimeInMinutes = (distance / 0.5).round();

    _markers = {
      Marker(
        markerId: const MarkerId('service_location'),
        position: serviceLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0),
        infoWindow: const InfoWindow(title: 'Service Location'),
      ),
      Marker(
        markerId: const MarkerId('provider_location'),
        position: providerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Provider Location'),
      ),
    };

    _circles = {
      Circle(
        circleId: const CircleId('provider_circle'),
        center: providerLocation,
        radius: 100,
        fillColor: Colors.orange.withOpacity(0.2),
        strokeColor: Colors.orange,
        strokeWidth: 2,
      ),
    };

    List<LatLng> routePoints = await _getDirectionsRoute(
      providerLocation,
      serviceLocation,
    );

    if (_arrivalTime == null) {
      _arrivalTime = fallbackTimeInMinutes.toString();
    }

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFF5B8DEE),
        width: 5,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };

    if (mounted) {
      setState(() {});
    }

    if (_mapController != null && animate) {
      final bounds = _calculateBounds([serviceLocation, providerLocation]);

      Future.delayed(const Duration(milliseconds: 100), () {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      });
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    return LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
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

  List<String> _extractParticulars(
    Map<String, dynamic>? dynamicFields,
    Map<String, dynamic>? serviceData,
  ) {
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
  void dispose() {
    _mapController?.dispose();
    _locationUpdateTimer?.cancel();

    // Unsubscribe from NATS subscriptions
    if (_serviceUpdateSubscription != null) {
      _natsService.unsubscribe('service.update.${widget.serviceId}');
    }
    if (_locationUpdateSubscription != null) {
      _natsService.unsubscribe('service.location.update.${widget.serviceId}');
    }
    if (_genericUpdateSubscription != null) {
      _natsService.unsubscribe('service.updates');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle user_rating_given safely
    final userRatingGiven = _serviceData?['user_rating_given'];
    final bool ratingGiven;

    if (userRatingGiven == null) {
      ratingGiven = false;
    } else if (userRatingGiven is bool) {
      ratingGiven = userRatingGiven;
    } else if (userRatingGiven is int) {
      ratingGiven = userRatingGiven == 1;
    } else if (userRatingGiven is String) {
      ratingGiven =
          userRatingGiven.toLowerCase() == 'true' || userRatingGiven == '1';
    } else {
      ratingGiven = false;
    }

    return Scaffold(
      backgroundColor: ColorConstant.moyoScaffoldGradient,
      appBar: UserOnlyTitleAppbar(title: "Service Details"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
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
            )
          : Consumer3<ServiceProvider, BookProviderProvider, RazorpayProvider>(
              builder:
                  (
                    context,
                    serviceProvider,
                    bookProviderProvider,
                    razorpayProvider,
                    child,
                  ) {
                    final user = _serviceData?['user'];
                    final dynamicFields = _serviceData?['dynamic_fields'];
                    final providerId = _serviceData?['assigned_provider_id']
                        ?.toString();

                    // Listen to payment success
                    if (razorpayProvider.paymentId != null &&
                        !razorpayProvider.isProcessing) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _handlePaymentSuccess(razorpayProvider.paymentId!);
                        razorpayProvider.resetPaymentState();
                      });
                    }
                    print("object");
                    print(user?['user']['mobile'] ?? 'N/A');

                    // Listen to payment error
                    if (razorpayProvider.errorMessage != null &&
                        !razorpayProvider.isProcessing) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showPaymentError(razorpayProvider.errorMessage!);
                        razorpayProvider.resetPaymentState();
                      });
                    }
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          UserServiceDetails(
                            serviceId: widget.serviceId,
                            onCompleteService: () => _handleCompleteService(
                              context,
                              razorpayProvider,
                            ),
                            providerId:
                                _serviceData?['assigned_provider_id']
                                    ?.toString() ??
                                'N/A',
                            category: _serviceData?['category'] ?? 'N/A',
                            subCategory: _serviceData?['service'] ?? 'N/A',
                            date: _formatDate(_serviceData?['schedule_date']),
                            pin: _serviceData?['status'] == "in_progress"
                                ? (_serviceData?['end_otp'] ?? 'N/A')
                                : (_serviceData?['start_otp'] ?? 'N/A'),
                            providerPhone: user?['user']['mobile'] ?? 'N/A',
                            dp:
                                user?['image'] ??
                                'https://picsum.photos/200/200',
                            name: user != null
                                ? '${user['user']['firstname'] ?? ''} ${user['user']['lastname'] ?? ''}'
                                      .trim()
                                : 'N/A',
                            rating: '4.5',
                            status: _serviceData?['status'] ?? 'N/A',
                            durationType: _serviceData?['service_mode'] == 'hrs'
                                ? 'Hourly'
                                : (_serviceData?['service_mode'] ?? 'N/A'),
                            // CHANGED: Use the safely parsed boolean value
                            userRatingGiven: ratingGiven,
                            duration:
                                _serviceData?['duration_value'] != null &&
                                    _serviceData?['duration_unit'] != null
                                ? '${_serviceData!['duration_value']} ${_serviceData!['duration_unit']}'
                                : 'N/A',
                            price: _serviceData?['budget']?.toString() ?? 'N/A',
                            address: _serviceData?['location'] ?? 'N/A',
                            particular: _extractParticulars(
                              dynamicFields,
                              _serviceData,
                            ),
                            onSeeWorktime: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final authToken =
                                  prefs.getString('auth_token') ?? '';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceTimerScreen(
                                    serviceId: widget.serviceId,
                                    durationValue:
                                        _serviceData?['duration_value'] ?? 1,
                                    durationUnit:
                                        _serviceData?['duration_unit'] ??
                                        'hours',
                                    categoryName:
                                        _serviceData?['category'] ?? 'N/A',
                                    subCategoryName:
                                        _serviceData?['service'] ?? 'N/A',
                                    authToken: authToken,
                                  ),
                                ),
                              );
                            },
                            description:
                                _serviceData?['description'] ??
                                'No description available',
                          ),

                          if (_locationData != null &&
                              (_serviceData?['status'] ?? '') !=
                                  "completed") ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: Container(
                                height: 300,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                        double.parse(
                                          _locationData!['latitude']
                                                  ?.toString() ??
                                              '0',
                                        ),
                                        double.parse(
                                          _locationData!['longitude']
                                                  ?.toString() ??
                                              '0',
                                        ),
                                      ),
                                      zoom: 13,
                                    ),
                                    markers: _markers,
                                    polylines: _polylines,
                                    circles: _circles,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    compassEnabled: false,
                                    mapToolbarEnabled: false,
                                    myLocationEnabled: false,
                                    mapType: MapType.normal,
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                      _isMapReady = true;
                                      _setupMap();
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (_arrivalTime != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.access_time,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Provider arriving in $_arrivalTime minutes',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
            ),
    );
  }

  void _handleCompleteService(
    BuildContext context,
    RazorpayProvider razorpayProvider,
  ) {
    final amount =
        double.tryParse(_serviceData?['budget']?.toString() ?? '0') ?? 0;
    // CHANGED: Access user from root level
    final user = _serviceData?['user'];
    final userName = user != null
        ? '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim()
        : 'Customer';
    final userPhone = user?['mobile'] ?? '';
    final userEmail = user?['email'] ?? '';

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid payment amount')));
      return;
    }

    // Open Razorpay checkout
    razorpayProvider.openCheckout(
      amount: amount,
      name: userName,
      description: 'Payment for ${_serviceData?['service'] ?? 'Service'}',
      contact: userPhone,
      email: userEmail,
    );
  }

  void _handlePaymentSuccess(String paymentId) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful! ID: $paymentId'),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Send payment confirmation to your backend
    // You can use NATS or HTTP to confirm the payment
    _confirmPaymentWithBackend(paymentId);
  }

  void _showPaymentError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _confirmPaymentWithBackend(String paymentId) async {
    try {
      final requestData = jsonEncode({
        'service_id': widget.serviceId,
        'payment_id': paymentId,
        'amount': _serviceData?['budget'],
        'status': 'completed',
      });

      final response = await _natsService.request(
        'service.payment.confirm',
        requestData,
        timeout: const Duration(seconds: 5),
      );

      if (response != null) {
        debugPrint('✅ Payment confirmed with backend');
        // Optionally navigate back or show completion screen
      }
    } catch (e) {
      debugPrint('❌ Error confirming payment: $e');
    }
  }
}
