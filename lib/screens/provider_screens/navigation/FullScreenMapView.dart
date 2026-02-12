import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:dart_nats/dart_nats.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import '../../../NATS Service/NatsService.dart';

class FullScreenMapView extends StatefulWidget {
  final String serviceId;
  final String? arrivalTime;

  const FullScreenMapView({
    Key? key,
    required this.serviceId,
    this.arrivalTime,
  }) : super(key: key);

  @override
  State<FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<FullScreenMapView>
    with WidgetsBindingObserver {
  late final NatsService _natsService;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  BitmapDescriptor? _providerMarkerIcon;
  BitmapDescriptor? _userMarkerIcon;
  bool _markersLoaded = false;
  String? _calculatedArrivalTime;
  double? _distanceKm;
  bool _isLoadingRoute = true;
  MapType _currentMapType = MapType.normal;

  // Real-time location data
  Map<String, dynamic>? _locationData;
  Subscription? _locationSubscription;

  // Current positions (will be updated in real-time)
  late double _currentProviderLat;
  late double _currentProviderLng;
  late double _currentServiceLat;
  late double _currentServiceLng;
  bool _hasOpenedNavigation = false;


  static const String GOOGLE_MAPS_API_KEY =
      'AIzaSyBqTGBtJYtoRpvJFpF6tls1jcwlbiNcEVI';

  @override
  void initState() {
    super.initState();
    _natsService = NatsService();
    _calculatedArrivalTime = widget.arrivalTime;

    // Initialize with default coordinates (will be updated from API)
    _currentProviderLat = 0.0;
    _currentProviderLng = 0.0;
    _currentServiceLat = 0.0;
    _currentServiceLng = 0.0;
    WidgetsBinding.instance.addObserver(this);
    _loadCustomMarkers();
    _initializeNatsAndSubscribe();
    // _openDirections();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 App resumed from navigation");

      // 🔥 You can run any logic here
      _centerOnRoute();        // Recenter map
      _setupMap(animate: true); // Refresh route if needed
    }

    if (state == AppLifecycleState.paused) {
      debugPrint("🚀 App moved to background (Navigation opened)");
    }
  }


  Future<void> _initializeNatsAndSubscribe() async {
    try {
      // Connect to NATS if not already connected
      if (!_natsService.isConnected) {
        final connected = await _natsService.connect(
          url: 'nats://api.moyointernational.com:4222',
        );

        if (!connected) {
          debugPrint('Failed to connect to NATS server');
          return;
        }
      }

      // Subscribe to location updates
      _subscribeToLocationUpdates();
    } catch (e) {
      debugPrint('Error initializing NATS: $e');
    }
  }

  void _subscribeToLocationUpdates() {
    // Create subscription request
    final requestData = jsonEncode({'service_id': widget.serviceId});

    // Subscribe to the location info subject
    _locationSubscription = _natsService.subscribe('service.location.info', (
        message,
        ) {
      try {
        final responseData = jsonDecode(message);

        // Handle both nested and direct response formats
        final data =
        responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData['data'] != null
            ? responseData['data']
            : responseData;

        // Update location data
        _updateLocationData(data);
      } catch (e) {
        debugPrint('Error processing location update: $e');
      }
    });

    // Send initial request to get location data
    _requestInitialLocation();

    debugPrint(
      '✅ Subscribed to location updates for service: ${widget.serviceId}',
    );
  }

  Future<void> _requestInitialLocation() async {
    try {
      final requestData = jsonEncode({'service_id': widget.serviceId});

      final response = await _natsService.request(
        'service.location.info',
        requestData,
        timeout: const Duration(seconds: 10),
      );

      if (response != null) {
        final responseData = jsonDecode(response);

        final data =
        responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData['data'] != null
            ? responseData['data']
            : responseData;

        _updateLocationData(data);
      }
    } catch (e) {
      debugPrint('Error requesting initial location: $e');
    }
  }

  void _updateLocationData(Map<String, dynamic> data) {
    if (!mounted) return;

    final newServiceLat = double.tryParse(data['latitude']?.toString() ?? '0');
    final newServiceLng = double.tryParse(data['longitude']?.toString() ?? '0');
    final newProviderLat =
    double.tryParse(data['provider']?['latitude']?.toString() ?? '0');
    final newProviderLng =
    double.tryParse(data['provider']?['longitude']?.toString() ?? '0');

    if (newServiceLat == null ||
        newServiceLng == null ||
        newProviderLat == null ||
        newProviderLng == null ||
        newServiceLat == 0.0 ||
        newServiceLng == 0.0 ||
        newProviderLat == 0.0 ||
        newProviderLng == 0.0) {
      return;
    }

    bool hasChanged =
        _currentProviderLat != newProviderLat ||
            _currentProviderLng != newProviderLng ||
            _currentServiceLat != newServiceLat ||
            _currentServiceLng != newServiceLng;

    if (hasChanged) {
      setState(() {
        _locationData = data;
        _currentProviderLat = newProviderLat;
        _currentProviderLng = newProviderLng;
        _currentServiceLat = newServiceLat;
        _currentServiceLng = newServiceLng;
        _isLoadingRoute = false;
      });

      _setupMap(animate: true);

      // 🔥 AUTO OPEN NAVIGATION (ONLY FIRST TIME)
      if (!_hasOpenedNavigation) {
        _hasOpenedNavigation = true;

        Future.delayed(const Duration(milliseconds: 500), () {
          _openDirections();
        });
      }
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      _providerMarkerIcon = await _createCustomMarkerIcon(
        Icons.directions_bike,
        Colors.orange,
        90.0,
      );

      _userMarkerIcon = await _createCustomMarkerIcon(
        Icons.location_on,
        Colors.red,
        80.0,
      );

      setState(() {
        _markersLoaded = true;
      });

      _setupMap();
    } catch (e) {
      print('Error loading custom markers: $e');
      setState(() {
        _markersLoaded = true;
      });
      _setupMap();
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(
      IconData iconData,
      Color color,
      double size,
      ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    if (color == Colors.orange) {
      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 + 4, glowPaint);
    }

    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    final borderWidth = color == Colors.orange ? 5.0 : 4.0;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    if (color == Colors.orange) {
      final accentPaint = Paint()
        ..color = Colors.deepOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 + borderWidth,
        accentPaint,
      );
    }

    final iconSize = color == Colors.orange ? size * 0.55 : size * 0.5;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
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
              final distance = legs[0]['distance'];

              if (duration != null) {
                final durationValue = duration['value'];
                setState(() {
                  _calculatedArrivalTime = (durationValue / 60)
                      .round()
                      .toString();
                });
              }

              if (distance != null) {
                final distanceValue = distance['value'];
                setState(() {
                  _distanceKm = distanceValue / 1000;
                });
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
    if (!_markersLoaded) return;

    // Don't setup map if we don't have valid coordinates yet
    if (_currentProviderLat == 0.0 || _currentProviderLng == 0.0 ||
        _currentServiceLat == 0.0 || _currentServiceLng == 0.0) {
      debugPrint('⚠️ Waiting for valid coordinates from API...');
      return;
    }

    final providerLocation = LatLng(_currentProviderLat, _currentProviderLng);
    final serviceLocation = LatLng(_currentServiceLat, _currentServiceLng);

    _markers = {
      Marker(
        markerId: const MarkerId('service_location'),
        position: serviceLocation,
        icon:
        _userMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(
          title: 'Service Location',
          snippet: 'Destination',
        ),
        zIndex: 1,
      ),
      Marker(
        markerId: const MarkerId('provider_location'),
        position: providerLocation,
        icon:
        _providerMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Provider',
        ),
        zIndex: 2,
      ),
    };

    _circles = {
      Circle(
        circleId: const CircleId('provider_outer_glow'),
        center: providerLocation,
        radius: 100,
        fillColor: Colors.orange.withOpacity(0.08),
        strokeColor: Colors.orange.withOpacity(0.2),
        strokeWidth: 2,
        zIndex: 0,
      ),
      Circle(
        circleId: const CircleId('provider_circle'),
        center: providerLocation,
        radius: 60,
        fillColor: Colors.orange.withOpacity(0.15),
        strokeColor: Colors.orange.withOpacity(0.4),
        strokeWidth: 3,
        zIndex: 1,
      ),
    };

    List<LatLng> routePoints = await _getDirectionsRoute(
      providerLocation,
      serviceLocation,
    );

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFF5B8DEE),
        width: 6,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        zIndex: 0,
      ),
    };

    setState(() {
      _isLoadingRoute = false;
    });

    if (_mapController != null) {
      final bounds = _calculateBounds([serviceLocation, providerLocation]);

      if (animate) {
        // Smooth animation when location updates
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } else {
        // Initial setup without animation
        Future.delayed(const Duration(milliseconds: 300), () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        });
      }
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _centerOnProvider() {
    final providerLocation = LatLng(_currentProviderLat, _currentProviderLng);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: providerLocation, zoom: 16),
      ),
    );
  }

  void _centerOnRoute() {
    final providerLocation = LatLng(_currentProviderLat, _currentProviderLng);
    final serviceLocation = LatLng(_currentServiceLat, _currentServiceLng);
    final bounds = _calculateBounds([serviceLocation, providerLocation]);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  // Open directions in external navigation app
  Future<void> _openDirections() async {
    try {
      final destination = '$_currentServiceLat,$_currentServiceLng';
      final origin = '$_currentProviderLat,$_currentProviderLng';

      Uri? url;

      // Try to open in platform-specific navigation apps
      if (Platform.isIOS) {
        // Try Apple Maps first on iOS
        url = Uri.parse(
          'http://maps.apple.com/?saddr=$origin&daddr=$destination&dirflg=d',
        );

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Fallback to Google Maps (works on both platforms)
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Show error if navigation app can't be opened
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open navigation app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening directions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening navigation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentProviderLat, _currentProviderLng),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            myLocationEnabled: false,
            mapType: _currentMapType,
            onMapCreated: (controller) {
              _mapController = controller;
              _setupMap();
            },
          ),

          // Loading indicator
          if (_isLoadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Real-time update indicator
          if (_locationData != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70.h,
              left: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top bar with back button and info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8.h,
                bottom: 12.h,
                left: 16.w,
                right: 16.w,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Info card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Time info
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.blue,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _calculatedArrivalTime != null
                                    ? '$_calculatedArrivalTime min'
                                    : 'Calculating...',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          // Distance info
                          if (_distanceKm != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten,
                                  color: Colors.orange,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '${_distanceKm!.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control buttons
          Positioned(
            right: 16.w,
            top: MediaQuery.of(context).padding.top + 80.h,
            child: Column(
              children: [
                // Map type toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _currentMapType == MapType.normal
                          ? Icons.satellite
                          : Icons.map,
                      color: Colors.black87,
                    ),
                    onPressed: _toggleMapType,
                  ),
                ),

                SizedBox(height: 12.h),

                // Center on provider
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.orange),
                    onPressed: _centerOnProvider,
                  ),
                ),

                SizedBox(height: 12.h),

                // Center on route
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.route, color: Colors.blue),
                    onPressed: _centerOnRoute,
                  ),
                ),
              ],
            ),
          ),

          // Bottom section with legend and directions button
          Positioned(
            bottom: 16.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start Directions Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: ElevatedButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.navigation, color: Colors.white),
                    label: Text(
                      'Start Navigation',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B8DEE),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),

                // Legend
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Your Location (Provider)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Service Location (Destination)',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            width: 20.w,
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B8DEE),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Route Path',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.unSub();
    _mapController?.dispose();
    super.dispose();
  }
}
