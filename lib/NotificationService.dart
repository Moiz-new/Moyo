import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:first_flutter/screens/provider_screens/provider_service_details_screen.dart';
import 'package:first_flutter/screens/user_screens/user_custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 CRITICAL: YE FUNCTION TOP-LEVEL HONA CHAHIYE (Class ke bahar)
// Background mein notification handle karne ke liye
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("=== 🔔 BACKGROUND Message Received (Top-Level Handler) ===");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");

  // Background mein bhi local notification show karo with conditional custom sound
  await NotificationService.showLocalNotificationStatic(message);
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 🔥 NAVIGATION KEY: Global navigation ke liye
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ================== CUSTOM SOUND CONFIGURATION ==================
  static const String _defaultSoundFileName = 'notification_sound';
  static const String _serviceCompletedSoundFileName = 'notification_sound1';

  // Helper method to get sound based on title
  static String _getSoundFileName(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    if (title == 'Service Completed') {
      print("🔊 Using SERVICE COMPLETED sound: $_serviceCompletedSoundFileName");
      return _serviceCompletedSoundFileName;
    }
    print("🔊 Using DEFAULT sound: $_defaultSoundFileName");
    return _defaultSoundFileName;
  }

  // ================== INITIALIZATION ==================
  static Future<void> initializeNotifications() async {
    print("=== 🔔 Initializing Notifications ===");

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 1. Setup Local Notifications
    await _setupLocalNotifications();

    // 2. Create Android Notification Channels (BOTH sounds)
    await _createNotificationChannels();

    // 3. Set Foreground Notification Options (iOS)
    await _setForegroundOptions();

    // 4. Listen to Foreground Messages
    _setupForegroundMessageHandler();

    // 5. Listen to Background Message Taps
    _setupBackgroundMessageHandler();

    // 6. Check if App Opened from Terminated State
    await _checkInitialMessage();

    // 7. Setup Token Refresh Listener
    setupTokenRefreshListener();

    print("=== ✅ Notification Initialization Complete ===");
  }

  // Create TWO Android Notification Channels - one for each sound
  static Future<void> _createNotificationChannels() async {
    // Default channel (notification_sound)
    final defaultAndroidSound = RawResourceAndroidNotificationSound(
      _defaultSoundFileName,
    );
    final defaultChannel = AndroidNotificationChannel(
      'moyo_high_importance_custom',
      'Moyo Custom Notifications',
      description: 'Default notifications with custom sound',
      importance: Importance.max,
      playSound: true,
      sound: defaultAndroidSound,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    // Service Completed channel (notification_sound1)
    final serviceCompletedAndroidSound = RawResourceAndroidNotificationSound(
      _serviceCompletedSoundFileName,
    );
    final serviceCompletedChannel = AndroidNotificationChannel(
      'moyo_service_completed',
      'Service Completed Notifications',
      description: 'Service completion notifications with special sound',
      importance: Importance.max,
      playSound: true,
      sound: serviceCompletedAndroidSound,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(defaultChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(serviceCompletedChannel);

    print("✅ Both channels created:");
    print("   Default: moyo_high_importance_custom ($_defaultSoundFileName)");
    print("   Service: moyo_service_completed ($_serviceCompletedSoundFileName)");
  }

  // Setup Local Notifications Plugin
  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print("📱 Notification tapped: ${response.payload}");
        _handleNotificationTap(response.payload);
      },
    );
    print("✅ Local notifications initialized");
  }

  // Set Foreground Notification Options for iOS
  static Future<void> _setForegroundOptions() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print("✅ iOS foreground options set");
  }

  // ================== MESSAGE HANDLERS ==================

  // Handle Foreground Messages (App is Open)
  static void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("=== 🔔 FOREGROUND Message Received ===");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");

      // Show local notification when app is in foreground with conditional sound
      _showLocalNotification(message);
    });
  }

  // Handle Background Message Taps (App in Background)
  static void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("=== 🔔 App Opened from BACKGROUND ===");
      print("Title: ${message.notification?.title}");
      print("Data: ${message.data}");
      _handleNotificationTap(jsonEncode(message.data));
    });
  }

  // Check if App Opened from Terminated State
  static Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      print("=== 🔔 App Opened from TERMINATED State ===");
      print("Title: ${initialMessage.notification?.title}");
      // Delay navigation to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(jsonEncode(initialMessage.data));
      });
    }
  }

  // Show Local Notification with Conditional Custom Sound (Instance method)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print("=== 📲 Showing notification with conditional custom sound ===");

    final soundFileName = _getSoundFileName(message);
    final isServiceCompleted = soundFileName == _serviceCompletedSoundFileName;

    final androidDetails = AndroidNotificationDetails(
      isServiceCompleted ? 'moyo_service_completed' : 'moyo_high_importance_custom',
      isServiceCompleted ? 'Service Completed Notifications' : 'Moyo Custom Notifications',
      channelDescription: isServiceCompleted
          ? 'Service completion notifications with special sound'
          : 'Notifications with custom sound',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundFileName),
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      ticker: 'New Notification',
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff', // iOS fallback - update if needed
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    print("✅ Notification shown with sound: $soundFileName");
  }

  static Future<void> showLocalNotificationStatic(RemoteMessage message) async {
    print("=== 📲 [BACKGROUND] Showing notification with conditional custom sound ===");

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Get conditional sound and create appropriate channel
    final soundFileName = _getSoundFileName(message);
    final isServiceCompleted = soundFileName == _serviceCompletedSoundFileName;
    final channelId = isServiceCompleted ? 'moyo_service_completed' : 'moyo_high_importance_custom';

    // Create channel for the specific sound
    final androidSound = RawResourceAndroidNotificationSound(soundFileName);
    final channel = AndroidNotificationChannel(
      channelId,
      isServiceCompleted ? 'Service Completed Notifications' : 'Moyo Custom Notifications',
      description: isServiceCompleted
          ? 'Service completion notifications with special sound'
          : 'Notifications with custom sound',
      importance: Importance.max,
      playSound: true,
      sound: androidSound,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(channel);

    // Notification details with conditional sound
    final androidDetails = AndroidNotificationDetails(
      channelId,
      isServiceCompleted ? 'Service Completed Notifications' : 'Moyo Custom Notifications',
      channelDescription: isServiceCompleted
          ? 'Service completion notifications with special sound'
          : 'Notifications with custom sound',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundFileName),
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      ticker: 'New Notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Notification show karo
    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: jsonEncode(message.data),
    );

    print("✅ [BACKGROUND] Notification shown with sound: $soundFileName");
  }

  // Handle Notification Tap with proper navigation (UNCHANGED)
  static void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      print("⚠️ Empty payload received");
      return;
    }

    print("🔔 Handling notification tap with payload: $payload");

    try {
      final Map<String, dynamic> data = jsonDecode(payload);

      if (data.containsKey("serviceId") && data.containsKey("role")) {
        String serviceId = data["serviceId"].toString();
        String role = data["role"].toString();

        print("📍 Role: $role, ServiceId: $serviceId");

        final context = navigatorKey.currentContext;

        if (context != null) {
          if (role == "user") {
            _navigateToUserServiceFromNotification(context, serviceId);
          } else if (role == "provider") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProviderServiceDetailsScreen(serviceId: serviceId),
              ),
            );
          }
        } else {
          print("❌ Navigator context not available");
        }
      }
    } catch (e) {
      print("❌ Error parsing payload: $e");
    }
  }

  // Navigation methods (UNCHANGED)
  static Future<void> _navigateToUserServiceFromNotification(
      BuildContext context,
      String serviceId,
      ) async {
    try {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => UserCustomBottomNav(
            initialTab: 2,
            notificationServiceId: serviceId,
          ),
        ),
            (route) => false,
      );
    } catch (e) {
      print("❌ Error navigating: $e");
    }
  }

  // ================== PERMISSIONS & TOKEN MANAGEMENT (UNCHANGED) ==================
  static Future<bool> requestNotificationPermission(
      BuildContext context,
      ) async {
    print("=== 📢 Requesting Notification Permission ===");

    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('notification_permission_asked') ?? false;

    final settings = await _firebaseMessaging.getNotificationSettings();
    print("Current permission: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Permission already granted");
      await _getAndSaveToken();
      return true;
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied &&
        hasAsked) {
      print("❌ Permission previously denied");
      return false;
    }

    final granted = await _showPermissionDialog(context);
    await prefs.setBool('notification_permission_asked', true);

    if (granted) {
      await _getAndSaveToken();
    }

    return granted;
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Enable Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stay updated with important information:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(Icons.receipt, 'Bill payment reminders'),
              _buildBenefitItem(Icons.event, 'Event notifications'),
              _buildBenefitItem(Icons.campaign, 'Important announcements'),
              _buildBenefitItem(Icons.check_circle, 'Service updates'),
              const SizedBox(height: 12),
              Text(
                'You can change this later in settings.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not Now',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Allow',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      print("User agreed, requesting system permission...");

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ System permission granted');
        return true;
      } else {
        print('❌ System permission denied');
        return false;
      }
    }

    print("User clicked 'Not Now'");
    return false;
  }

  static Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  static Future<void> _getAndSaveToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("🔑 FCM Token: $token");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        print("✅ Token saved locally");
      } else {
        print("❌ Failed to get FCM token");
      }
    } catch (e) {
      print("❌ Error getting token: $e");
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString('fcm_token');

      if (cachedToken != null) {
        print("📱 Using cached token");
        return cachedToken;
      }

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await prefs.setString('fcm_token', token);
        print("🔑 Fresh token retrieved");
      }
      return token;
    } catch (e) {
      print("❌ Error getting token: $e");
      return null;
    }
  }

  static void setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print("🔄 Token refreshed: $newToken");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });
  }

  // ================== TEST METHODS ==================
  static Future<void> showTestNotification() async {
    print("=== 🧪 Showing Test Notification (Default Sound) ===");

    final androidDetails = AndroidNotificationDetails(
      'moyo_high_importance_custom',
      'Moyo Custom Notifications',
      channelDescription: 'Notifications with custom sound',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_defaultSoundFileName),
      enableVibration: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      '🧪 Custom Sound Test',
      'Agar aapki default custom sound sunayi di! 🎉',
      notificationDetails,
    );

    print("✅ Test notification triggered (default sound)");
  }

  // NEW: Test Service Completed notification
  static Future<void> showServiceCompletedTestNotification() async {
    print("=== 🧪 Showing Service Completed Test Notification ===");

    final androidDetails = AndroidNotificationDetails(
      'moyo_service_completed',
      'Service Completed Notifications',
      channelDescription: 'Service completion notifications with special sound',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_serviceCompletedSoundFileName),
      enableVibration: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      'Service Completed',
      'Your service has been successfully completed! 🎉',
      notificationDetails,
    );

    print("✅ Service Completed test notification triggered");
  }

  static Future<void> deleteOldChannel() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.deleteNotificationChannel('moyo_high_importance');

    print("🗑️ Old channel deleted");
  }
}
