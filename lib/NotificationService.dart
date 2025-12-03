import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize Firebase and Notifications
  static Future<void> initializeNotifications() async {
    print("=== Initializing Notifications ===");

    // Local notifications setup (Firebase already initialized in main)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification tapped: ${response.payload}");
        // Handle notification tap here
      },
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("Notification channel created");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("=== Foreground message received ===");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      _showLocalNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("=== Notification opened app ===");
      print("Title: ${message.notification?.title}");
      // Handle navigation here
    });

    print("=== Notification initialization complete ===");
  }

  // Request notification permission with dialog
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    print("=== Requesting notification permission ===");

    // Check current permission status
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    print("Current permission status: ${settings.authorizationStatus}");

    // If already authorized, return true
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Permission already granted");
      return true;
    }

    // Show permission dialog
    return await _showPermissionDialog(context);
  }

  // Show permission request dialog
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
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
              Text(
                'Stay updated with important information:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              _buildBenefitItem(Icons.receipt, 'Bill payment reminders'),
              _buildBenefitItem(Icons.event, 'Event notifications'),
              _buildBenefitItem(Icons.campaign, 'Important announcements'),
              _buildBenefitItem(Icons.check_circle, 'Service updates'),
              SizedBox(height: 12),
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Allow',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      print("User agreed to enable notifications, requesting system permission");
      // Request actual permission from system
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✓ User granted notification permissions');
        return true;
      } else {
        print('✗ User declined notification permissions');
        return false;
      }
    }

    print("User clicked 'Not Now'");
    return false;
  }

  // Helper widget for benefit items
  static Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // Get device token
  static Future<String?> getDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("Firebase Device Token: $token");
      return token;
    } catch (e) {
      print("Error getting device token: $e");
      return null;
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print("=== Showing Local Notification ===");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode, // Unique ID for each notification
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );

    print("=== Notification Shown ===");
  }
}