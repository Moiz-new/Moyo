import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show cos, sqrt, asin;

class FullScreenMapView extends StatefulWidget {
  final double providerLat;
  final double providerLng;
  final double serviceLat;
  final double serviceLng;
  final String? arrivalTime;

  const FullScreenMapView({
    Key? key,
    required this.providerLat,
    required this.providerLng,
    required this.serviceLat,
    required this.serviceLng,
    this.arrivalTime,
  }) : super(key: key);

  @override
  State<FullScreenMapView> createState() => _FullScreenMapViewState();
}

class _FullScreenMapViewState extends State<FullScreenMapView> {
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

  static const String GOOGLE_MAPS_API_KEY =
      'AIzaSyBqTGBtJYtoRpvJFpF6tls1jcwlbiNcEVI';

  @override
  void initState() {
    super.initState();
    _calculatedArrivalTime = widget.arrivalTime;
    _loadCustomMarkers();
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
                  _calculatedArrivalTime =
                      (durationValue / 60).round().toString();
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

  void _setupMap() async {
    if (!_markersLoaded) return;

    final providerLocation = LatLng(widget.providerLat, widget.providerLng);
    final serviceLocation = LatLng(widget.serviceLat, widget.serviceLng);

    _markers = {
      Marker(
        markerId: const MarkerId('service_location'),
        position: serviceLocation,
        icon: _userMarkerIcon ??
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
        icon: _providerMarkerIcon ??
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
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _centerOnProvider() {
    final providerLocation = LatLng(widget.providerLat, widget.providerLng);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: providerLocation, zoom: 16),
      ),
    );
  }

  void _centerOnRoute() {
    final providerLocation = LatLng(widget.providerLat, widget.providerLng);
    final serviceLocation = LatLng(widget.serviceLat, widget.serviceLng);
    final bounds = _calculateBounds([serviceLocation, providerLocation]);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.providerLat, widget.providerLng),
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
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
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
                    icon: const Icon(
                      Icons.my_location,
                      color: Colors.orange,
                    ),
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
                    icon: const Icon(
                      Icons.route,
                      color: Colors.blue,
                    ),
                    onPressed: _centerOnRoute,
                  ),
                ),
              ],
            ),
          ),

          // Bottom legend
          Positioned(
            bottom: 16.h,
            left: 16.w,
            right: 16.w,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}