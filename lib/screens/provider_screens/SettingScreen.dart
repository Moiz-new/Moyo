import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:io'; // Added for XFile
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/colorConstant/color_constant.dart';
import '../commonOnboarding/splashScreen/splash_screen_provider.dart';
import '../user_screens/Profile/FAQScreen.dart';
import 'ContactFormScreen.dart';
import 'LegalDocumentScreen.dart';
import 'SettingsProvider.dart';
import 'TermsandConditions.dart';

class SettingScreen extends StatefulWidget {
  final String? type;
  final List<String>? roles;

  const SettingScreen({Key? key, this.type, this.roles}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with WidgetsBindingObserver {
  bool notificationsEnabled = true;
  bool locationEnabled = true;
  String selectedCurrency = 'Indian Rupee (₹)';
  String selectedDistanceUnit = 'Kilometers';
  bool _isLoading = false;
  String appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppVersion();
    _loadPreferences();
    _checkPermissions();

    // Load saved radius from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadSavedRadius();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.location.status;

    setState(() {
      notificationsEnabled = notificationStatus.isGranted;
      locationEnabled = locationStatus.isGranted;
    });

    _savePreference('notifications', notificationsEnabled);
    _savePreference('location', locationEnabled);
  }

  Future<void> _handleNotificationPermission(bool enable) async {
    if (enable) {
      final status = await Permission.notification.status;

      if (status.isDenied) {
        final result = await Permission.notification.request();

        if (result.isGranted) {
          setState(() {
            notificationsEnabled = true;
          });
          _savePreference('notifications', true);
          _showSnackBar('Notifications enabled');
        } else if (result.isPermanentlyDenied) {
          _showPermissionDialog(
            'Notification Permission',
            'Notification permission is permanently denied. Please enable it from app settings.',
            'notifications',
          );
        } else {
          setState(() {
            notificationsEnabled = false;
          });
          _showSnackBar('Notification permission denied');
        }
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog(
          'Notification Permission',
          'Notification permission is disabled. Please enable it from app settings.',
          'notifications',
        );
      } else if (status.isGranted) {
        setState(() {
          notificationsEnabled = true;
        });
        _savePreference('notifications', true);
        _showSnackBar('Notifications enabled');
      }
    } else {
      _showPermissionDialog(
        'Disable Notifications',
        'To disable notifications, please go to app settings.',
        'notifications',
      );
    }
  }

  Future<void> _handleLocationPermission(bool enable) async {
    if (enable) {
      final status = await Permission.location.status;

      if (status.isDenied) {
        final result = await Permission.location.request();

        if (result.isGranted) {
          setState(() {
            locationEnabled = true;
          });
          _savePreference('location', true);
          _showSnackBar('Location enabled');
        } else if (result.isPermanentlyDenied) {
          _showPermissionDialog(
            'Location Permission',
            'Location permission is permanently denied. Please enable it from app settings.',
            'location',
          );
        } else {
          setState(() {
            locationEnabled = false;
          });
          _showSnackBar('Location permission denied');
        }
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog(
          'Location Permission',
          'Location permission is disabled. Please enable it from app settings.',
          'location',
        );
      } else if (status.isGranted) {
        setState(() {
          locationEnabled = true;
        });
        _savePreference('location', true);
        _showSnackBar('Location enabled');
      }
    } else {
      _showPermissionDialog(
        'Disable Location',
        'To disable location services, please go to app settings.',
        'location',
      );
    }
  }

  void _showPermissionDialog(
    String title,
    String message,
    String permissionType,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: ColorConstant.black,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorConstant.black.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissions();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: ColorConstant.black.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings(type: AppSettingsType.settings);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.moyoOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(fontSize: 14.sp, color: ColorConstant.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      print('Error loading app version: $e');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        selectedCurrency = prefs.getString('currency') ?? 'Indian Rupee (₹)';
        selectedDistanceUnit = prefs.getString('distanceUnit') ?? 'Kilometers';
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      print('Error saving preference: $e');
    }
  }

  List<String> get userRoles {
    if (widget.roles != null && widget.roles!.isNotEmpty) {
      return widget.roles!;
    }
    return widget.type != null ? [widget.type!] : ['user'];
  }

  void _navigateToLegalDocument(String documentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermsandConditions(type: "terms", roles: [""]),
      ),
    );
  }

  // CHANGED: Updated _shareApp method to include app logo and referral code
  // Replace the _shareApp method with this updated version

  Future<void> _shareApp() async {
    try {
      // Get referral code from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final referralCode = prefs.getString('referral_code') ?? '';

      // Build share message with referral code
      String shareMessage = 'Check out this amazing app! ';
      if (referralCode.isNotEmpty) {
        shareMessage += 'Use my referral code: $referralCode\n\n';
      }
      shareMessage +=
          'Download now: https://play.google.com/store/apps/details?id=com.acore.moyo&pcampaignid=web_share';

      // Load the image from assets as bytes
      final ByteData bytes = await rootBundle.load(
        'assets/icons/app_icon_radius.png.png',
      );
      final Uint8List list = bytes.buffer.asUint8List();

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/app_logo.png').create();
      await file.writeAsBytes(list);

      // Share with app logo image using XFile
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: shareMessage,
        subject: 'Check out this app!',
      );

      if (result.status == ShareResultStatus.success) {
        _showSnackBar('App shared successfully!');
      }
    } catch (e) {
      print('Error sharing app with image: $e');
      // Fallback to text-only share if image sharing fails
      try {
        final prefs = await SharedPreferences.getInstance();
        final referralCode = prefs.getString('referral_code') ?? '';

        String shareMessage = 'Check out this amazing app! ';
        if (referralCode.isNotEmpty) {
          shareMessage += 'Use my referral code: $referralCode\n\n';
        }
        shareMessage +=
            'Download now: https://play.google.com/store/apps/details?id=com.acore.moyo&pcampaignid=web_share';

        await Share.share(shareMessage, subject: 'Check out this app!');
        _showSnackBar('App shared!');
      } catch (e) {
        _showSnackBar('Failed to share app');
      }
    }
  }

  Future<void> _rateApp() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.acore.moyo&pcampaignid=web_share',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open Play Store');
      }
    } catch (e) {
      _showSnackBar('Error opening Play Store');
    }
  }

  Future<void> _contactSupport() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactFormScreen()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            return Scaffold(
              backgroundColor: ColorConstant.scaffoldGray,
              appBar: AppBar(
                backgroundColor: ColorConstant.appColor,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, size: 24.sp),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),

                        // App Preferences Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'App Preferences',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorConstant.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: ColorConstant.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            children: [
                              // Notifications Toggle
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Notifications',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: ColorConstant.black,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Enable push notifications',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: ColorConstant.black
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: notificationsEnabled,
                                    onChanged: (value) {
                                      _handleNotificationPermission(value);
                                    },
                                    activeColor: ColorConstant.white,
                                    activeTrackColor: ColorConstant.moyoOrange,
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              // Location Services Toggle
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Location Services',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: ColorConstant.black,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Allow access to your location',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: ColorConstant.black
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: locationEnabled,
                                    onChanged: (value) {
                                      _handleLocationPermission(value);
                                    },
                                    activeColor: ColorConstant.white,
                                    activeTrackColor: ColorConstant.moyoOrange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Distance Settings Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'Distance Settings',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorConstant.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: ColorConstant.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Maximum Search Distance',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: ColorConstant.black,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ColorConstant.moyoOrange
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Text(
                                          '${settingsProvider.maxSearchDistance.toStringAsFixed(1)} ${selectedDistanceUnit == 'Kilometers' ? 'km' : 'miles'}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstant.moyoOrange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Adjust your work radius to find jobs nearby',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: ColorConstant.black.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor:
                                          ColorConstant.moyoOrange,
                                      inactiveTrackColor: ColorConstant
                                          .moyoOrange
                                          .withOpacity(0.3),
                                      thumbColor: ColorConstant.moyoOrange,
                                      overlayColor: ColorConstant.moyoOrange
                                          .withOpacity(0.2),
                                      trackHeight: 4.h,
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 12.r,
                                      ),
                                    ),
                                    child: Slider(
                                      value: settingsProvider.maxSearchDistance
                                          .toDouble(),
                                      min: 1.0,
                                      max: 50.0,
                                      divisions: 49,
                                      onChanged: (value) {
                                        settingsProvider.setMaxSearchDistance(
                                          value.round(),
                                        );
                                      },
                                      onChangeEnd: (value) async {
                                        bool success = await settingsProvider
                                            .updateWorkRadius(value.round());

                                        if (success) {
                                          _showSnackBar(
                                            'Search distance updated successfully',
                                          );
                                        } else {
                                          if (settingsProvider.errorMessage !=
                                              null) {
                                            _showSnackBar(
                                              settingsProvider.errorMessage!,
                                            );
                                          } else {
                                            _showSnackBar(
                                              'Failed to update search distance',
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Legal & About Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'Legal & About',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorConstant.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: ColorConstant.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            children: [
                              // Version
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                      title: Text('App Information'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Version: $appVersion'),
                                          SizedBox(height: 8.h),
                                          Text('Build: Release'),
                                          SizedBox(height: 8.h),
                                          Text('© 2024 Your Company'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'App Version',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: ColorConstant.black,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            appVersion,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: ColorConstant.black
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.info_outline,
                                            size: 16.sp,
                                            color: ColorConstant.moyoOrange,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Privacy Policy',
                                onTap: () =>
                                    _navigateToLegalDocument('privacy_policy'),
                              ),
                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.description_outlined,
                                title: 'Terms of Service',
                                onTap: () => _navigateToLegalDocument('terms'),
                              ),
                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.gavel_outlined,
                                title: 'Code of Conduct',
                                onTap: () =>
                                    _navigateToLegalDocument('code_of_conduct'),
                              ),
                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.help_outline,
                                title: 'FAQ',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FAQScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.support_agent_outlined,
                                title: 'Contact Support',
                                onTap: _contactSupport,
                              ),
                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.share_outlined,
                                title: 'Share App',
                                onTap: _shareApp,
                              ),
                              Divider(
                                color: ColorConstant.black.withOpacity(0.1),
                                height: 1.h,
                              ),
                              _buildLegalTile(
                                icon: Icons.star_outline,
                                title: 'Rate App',
                                onTap: _rateApp,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Account Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorConstant.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: ColorConstant.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: InkWell(
                            onTap: () {
                              _showLogoutDialog();
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.red,
                                    size: 20.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),

                  // Loading overlay
                  if (settingsProvider.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorConstant.moyoOrange,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegalTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, color: ColorConstant.moyoOrange, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: ColorConstant.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ColorConstant.black.withOpacity(0.4),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: ColorConstant.black,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorConstant.black.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: ColorConstant.black.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 14.sp, color: ColorConstant.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final splashProvider = Provider.of<SplashProvider>(
        context,
        listen: false,
      );
      await splashProvider.clearSession();

      print('User logged out successfully');

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      _showErrorDialog('Logout failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
