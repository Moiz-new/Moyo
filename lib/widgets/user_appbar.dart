import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class UserAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String? dp;
  final String? fullName;
  final String? type;

  const UserAppbar({super.key, this.dp, this.fullName, required this.type});

  @override
  State<UserAppbar> createState() => _UserAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _UserAppbarState extends State<UserAppbar> {
  String currentAddress = "Fetching location...";
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// Start continuous location tracking
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when user moves 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Check if location has changed significantly
      if (_lastPosition == null ||
          _hasLocationChanged(_lastPosition!, position)) {
        _lastPosition = position;
        _updateLocationAndAddress(position);
      }
    });
  }

  /// Check if location has changed significantly
  bool _hasLocationChanged(Position oldPosition, Position newPosition) {
    double distance = Geolocator.distanceBetween(
      oldPosition.latitude,
      oldPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    return distance > 10; // 10 meters threshold
  }

  /// Update location to server and refresh address
  Future<void> _updateLocationAndAddress(Position position) async {
    // Update location to server
    await _updateLocationToServer(position.latitude, position.longitude);

    // Update address display
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;
      String completeAddress =
          "${place.street}, ${place.subLocality}, ${place.locality}";

      setState(() {
        currentAddress = completeAddress;
      });
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _updateLocationToServer(
      double latitude,
      double longitude,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the appropriate token based on user type
      final token = widget.type == "provider"
          ? prefs.getString('provider_auth_token')
          : prefs.getString('auth_token');

      // Determine the correct API endpoint based on user type
      String apiEndpoint = widget.type == "provider"
          ? '$base_url/api/provider/update-location'
          : '$base_url/api/auth/update-location';

      // Use PUT for provider and POST for user
      final response = widget.type == "provider"
          ? await http.put(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      )
          : await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      );

      print('Location Update Response: ${response.body}');
      print('Location Update Response: ${latitude.toString()}');
      print('Location Update Response: ${longitude.toString()}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Location updated successfully');
        final responseData = json.decode(response.body);
        print('Message: ${responseData['message']}');
      } else {
        print('Failed to update location: ${response.statusCode}');
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    /// Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentAddress = "Location disabled";
      });
      return;
    }

    /// Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentAddress = "Permission denied";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentAddress = "Permission denied forever";
      });
      return;
    }

    /// Get Current Position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _lastPosition = position;

    /// Send location to server
    await _updateLocationToServer(position.latitude, position.longitude);

    /// Convert to readable address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    String completeAddress =
        "${place.street}, ${place.subLocality}, ${place.locality}";

    setState(() {
      currentAddress = completeAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      backgroundColor: ColorConstant.moyoOrange,
      title: Row(
        spacing: 10,
        children: [
          InkWell(
            onTap: () {
              if (widget.type == "user")
                Navigator.pushNamed(context, '/UserProfileScreen');
              else {
                Navigator.pushNamed(context, '/providerProfile');
              }
            },
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              height: 36,
              width: 36,
              child: CachedNetworkImage(
                imageUrl: widget.dp ?? "https://picsum.photos/200/200",
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Image.asset('assets/images/moyo_service_placeholder.png'),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/images/moyo_service_placeholder.png'),
              ),
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0,
              children: [
                Text(
                  'Welcome, ${widget.fullName ?? 'User'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstant.white,
                    ),
                  ),
                ),
                Row(
                  spacing: 4,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/moyo_appbar_location_icon.svg',
                    ),
                    Flexible(
                      child: Text(
                        currentAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          textStyle: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications_none_outlined,
            color: ColorConstant.white,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.settings, color: ColorConstant.white),
        ),
      ],
    );
  }
}