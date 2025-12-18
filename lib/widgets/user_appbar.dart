import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/screens/provider_screens/navigation/NotificationListScreen.dart';
import 'package:first_flutter/screens/user_screens/UserMyRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../screens/provider_screens/SettingScreen.dart';
import '../screens/provider_screens/navigation/NotificationProvider.dart';
import '../screens/provider_screens/navigation/UserNotificationProvider.dart';
import '../screens/provider_screens/navigation/UserNotificationListScreen.dart';
import '../screens/user_screens/Profile/UserProfileProvider.dart';

class UserAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String? type;

  const UserAppbar({super.key, required this.type});

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

    // Load user profile using existing provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().loadUserProfile();
    });

    _getUserLocation();
    _startLocationTracking();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// Fetch notifications for both provider and user
  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (widget.type == 'provider') {
        final token = prefs.getString('provider_auth_token');
        if (token != null && token.isNotEmpty) {
          Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).fetchNotifications(token);
        }
      } else {
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          Provider.of<UserNotificationProvider>(
            context,
            listen: false,
          ).fetchNotifications(token);
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  /// Check if user is blocked by fetching profile
  Future<void> _checkBlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = widget.type == "provider"
          ? prefs.getString('provider_auth_token')
          : prefs.getString('auth_token');

      if (token == null || token.isEmpty) return;

      String apiEndpoint = widget.type == "provider"
          ? '$base_url/api/provider/profile'
          : '$base_url/api/auth/profile';

      final response = await http.get(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final profile = responseData['profile'];

        bool isBlocked = false;

        // Check user blocked status
        if (profile['is_blocked'] == true) {
          isBlocked = true;
        }

        // Check provider blocked status if provider type
        if (widget.type == 'provider' &&
            profile['provider'] != null &&
            profile['provider']['is_blocked'] == true) {
          isBlocked = true;
        }

        if (isBlocked) {
          // User is blocked, logout and show dialog
          await _handleBlockedUser();
        }
      }
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  /// Handle blocked user - logout and redirect
  Future<void> _handleBlockedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all tokens
      await prefs.remove('auth_token');
      await prefs.remove('provider_auth_token');

      // Cancel location tracking
      _positionStreamSubscription?.cancel();

      // Show blocked dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Account Blocked',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Text(
                'Your account has been blocked. You cannot access the app anymore. Please contact support for more information.',
                style: GoogleFonts.roboto(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to login screen and clear all previous routes
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/LoginScreen', (route) => false);
                  },
                  child: Text(
                    'OK',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.moyoOrange,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error handling blocked user: $e');
    }
  }

  /// Start continuous location tracking
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_lastPosition == null ||
                _hasLocationChanged(_lastPosition!, position)) {
              _lastPosition = position;
              _updateLocationAndAddress(position);
            }
          },
        );
  }

  /// Check if location has changed significantly
  bool _hasLocationChanged(Position oldPosition, Position newPosition) {
    double distance = Geolocator.distanceBetween(
      oldPosition.latitude,
      oldPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    return distance > 10;
  }

  /// Update location to server and refresh address
  Future<void> _updateLocationAndAddress(Position position) async {
    await _updateLocationToServer(position.latitude, position.longitude);

    // Check block status after updating location
    await _checkBlockStatus();

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

      final token = widget.type == "provider"
          ? prefs.getString('provider_auth_token')
          : prefs.getString('auth_token');

      String apiEndpoint = widget.type == "provider"
          ? '$base_url/api/provider/update-location'
          : '$base_url/api/auth/update-location';

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

    // Check block status after initial location update
    await _checkBlockStatus();

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
      title: Consumer<UserProfileProvider>(
        builder: (context, profileProvider, child) {
          return Row(
            spacing: 10,
            children: [
              InkWell(
                onTap: () {
                  if (widget.type == "user") {
                    Navigator.pushNamed(context, '/UserProfileScreen');
                  } else {
                    Navigator.pushNamed(context, '/UserProfileScreen');
                  }
                },
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  height: 36,
                  width: 36,
                  child: profileProvider.isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : CachedNetworkImage(
                          imageUrl: profileProvider.profileImage.isNotEmpty
                              ? profileProvider.profileImage
                              : "https://picsum.photos/200/200",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset(
                            'assets/images/moyo_service_placeholder.png',
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/moyo_service_placeholder.png',
                          ),
                        ),
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 0,
                  children: [
                    Text(
                      'Welcome, ${profileProvider.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
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
          );
        },
      ),
      actions: [
        if (widget.type == 'user')
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserMyRating()),
              );
            },
            icon: Icon(Icons.star_border_outlined, color: ColorConstant.white),
          ),
        if (widget.type == 'provider')
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationListScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: ColorConstant.white,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorConstant.moyoOrange,
                            width: 2,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: GoogleFonts.roboto(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        else
          Consumer<UserNotificationProvider>(
            builder: (context, userNotificationProvider, child) {
              final unreadCount = userNotificationProvider.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserNotificationListScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: ColorConstant.white,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorConstant.moyoOrange,
                            width: 2,
                          ),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingScreen(roles: [?widget.type]),
              ),
            );
          },
          icon: Icon(Icons.settings, color: ColorConstant.white),
        ),
      ],
    );
  }
}
