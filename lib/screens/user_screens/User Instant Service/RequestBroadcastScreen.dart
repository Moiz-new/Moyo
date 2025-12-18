import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

import '../../../constants/colorConstant/color_constant.dart';

class RequestBroadcastScreen extends StatefulWidget {
  const RequestBroadcastScreen({Key? key}) : super(key: key);

  @override
  State<RequestBroadcastScreen> createState() => _RequestBroadcastScreenState();
}

class _RequestBroadcastScreenState extends State<RequestBroadcastScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  // User location (example coordinates - Indore)
  static const LatLng _userLocation = LatLng(22.7196, 75.8577);
  static const LatLng _destination = LatLng(22.7532, 75.8937);

  late AnimationController _pulseController;
  late AnimationController _searchController;
  late AnimationController _zoomController;

  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _zoomTimer;

  List<Provider> _nearbyProviders = [];
  double _targetZoom = 13.5;
  bool _isZoomingOut = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTimers();
    _generateNearbyProviders();
    _setupMarkers();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    // Smooth zoom animation using timer instead of animation listener
    _zoomTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_mapController != null && mounted) {
        if (_isZoomingOut) {
          _targetZoom -= 0.01;
          if (_targetZoom <= 12.5) {
            _isZoomingOut = false;
          }
        } else {
          _targetZoom += 0.01;
          if (_targetZoom >= 13.5) {
            _isZoomingOut = true;
          }
        }

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _userLocation,
              zoom: _targetZoom,
            ),
          ),
        );
      }
    });
  }

  void _generateNearbyProviders() {
    final random = Random();
    _nearbyProviders = List.generate(8, (i) {
      return Provider(
        id: 'P${i + 1}',
        name: 'Driver ${i + 1}',
        rating: 4.0 + random.nextDouble(),
        distance: 0.5 + random.nextDouble() * 4,
        location: LatLng(
          _userLocation.latitude + (random.nextDouble() - 0.5) * 0.02,
          _userLocation.longitude + (random.nextDouble() - 0.5) * 0.02,
        ),
      );
    });
  }

  // Function to resize marker icon
  Future<BitmapDescriptor> _getResizedMarkerIcon(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List resizedBytes = (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!
        .buffer
        .asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _setupMarkers() async {
    final Set<Marker> markers = {};

    // Load and resize custom current location marker icon
    final currentLocationIcon = await _getResizedMarkerIcon(
      'assets/icons/currentmarker.png',
      70, // Width in pixels - adjust this value (40, 60, 80, 100)
    );

    // User pickup marker with custom icon
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _userLocation,
        icon: currentLocationIcon,
        anchor: const Offset(0.5, 0.5), // Center the icon on the location
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );

    // Destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );

    // Provider markers
    for (var provider in _nearbyProviders) {
      markers.add(
        Marker(
          markerId: MarkerId(provider.id),
          position: provider.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: provider.name,
            snippet:
            '${provider.distance.toStringAsFixed(1)} km • ⭐ ${provider.rating.toStringAsFixed(1)}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Set<Circle> _buildPulseCircles() {
    return {
      Circle(
        circleId: const CircleId('pulse'),
        center: _userLocation,
        radius: 500 + (_pulseController.value * 1000),
        fillColor: ColorConstant.moyoOrange
            .withOpacity(0.1 - _pulseController.value * 0.1),
        strokeColor: ColorConstant.moyoOrange
            .withOpacity(0.3 - _pulseController.value * 0.3),
        strokeWidth: 2,
      ),
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _zoomController.dispose();
    _timer?.cancel();
    _zoomTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.white,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _userLocation,
              zoom: 13.5,
            ),
            markers: _markers,
            circles: _circles,
            onMapCreated: (GoogleMapController controller) async {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
                _mapController = controller;
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: false,
            myLocationEnabled: false,
          ),

          // Broadcasting animation overlay on map center
          Center(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 150 + (_pulseController.value * 100),
                        height: 150 + (_pulseController.value * 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorConstant.moyoOrange.withOpacity(
                              0.6 - _pulseController.value * 0.6,
                            ),
                            width: 3,
                          ),
                        ),
                      ),
                      // Middle pulse ring
                      Container(
                        width: 120 + (_pulseController.value * 60),
                        height: 120 + (_pulseController.value * 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstant.moyoOrange.withOpacity(
                            0.2 - _pulseController.value * 0.2,
                          ),
                        ),
                      ),
                      // Inner pulse ring
                      Container(
                        width: 80 + (_pulseController.value * 30),
                        height: 80 + (_pulseController.value * 30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstant.moyoOrange.withOpacity(
                            0.4 - _pulseController.value * 0.4,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Top bar with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorConstant.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ColorConstant.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstant.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: ColorConstant.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstant.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstant.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _searchController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _searchController.value * 2 * pi,
                                child: const Icon(
                                  Icons.radar,
                                  color: ColorConstant.moyoOrange,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Searching for provider...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_nearbyProviders.length} nearby drivers',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_secondsElapsed}s',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.moyoOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom request card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstant.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstant.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorConstant.moyoOrangeFade,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorConstant.moyoGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Vijay Nagar Square',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: ColorConstant.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorConstant.moyoOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'C21 Mall, Vijay Nagar',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: ColorConstant.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Your offer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Your offer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '₹180',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstant.moyoOrange,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text(
                                  'Cheif',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '>',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Cook',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.scaffoldGray,
                              foregroundColor: ColorConstant.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Cancel Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Provider {
  final String id;
  final String name;
  final double rating;
  final double distance;
  final LatLng location;

  Provider({
    required this.id,
    required this.name,
    required this.rating,
    required this.distance,
    required this.location,
  });
}