import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:first_flutter/providers/provider_navigation_provider.dart';
import 'package:first_flutter/providers/user_navigation_provider.dart';
import 'package:first_flutter/screens/Skills/MySkillProvider.dart';
import 'package:first_flutter/screens/SubCategory/SkillProvider.dart';
import 'package:first_flutter/screens/SubCategory/SubcategoryProvider.dart';
import 'package:first_flutter/screens/commonOnboarding/otpScreen/otp_screen_provider.dart';
import 'package:first_flutter/screens/provider_screens/LegalDocumentScreen.dart';
import 'package:first_flutter/screens/provider_screens/ProviderProfile/EditProviderProfileProvider.dart';
import 'package:first_flutter/screens/provider_screens/ProviderProfile/EditProviderProfileScreen.dart';
import 'package:first_flutter/screens/provider_screens/ProviderProfile/ProviderOnboardingScreen.dart';
import 'package:first_flutter/screens/provider_screens/ProviderProfile/ProviderProfileProvider.dart';
import 'package:first_flutter/screens/provider_screens/ProviderProfile/ProviderProfileScreen.dart';
import 'package:first_flutter/screens/provider_screens/ServiceArrivalProvider.dart';
import 'package:first_flutter/screens/provider_screens/SettingsProvider.dart';
import 'package:first_flutter/screens/provider_screens/StartWorkProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/AvailabilityProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/EarningsProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/NotificationProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/ProviderChats/ProviderChatProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/UserNotificationProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/ProviderBidProvider.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_confirmed_service.dart';
import 'package:first_flutter/screens/provider_screens/navigation/provider_service_tab_body/provider_re_bid_service.dart';
import 'package:first_flutter/screens/provider_screens/provider_custom_bottom_nav.dart';
import 'package:first_flutter/screens/provider_screens/provider_service_details_screen.dart';
import 'package:first_flutter/screens/user_screens/Address/MyAddressProvider.dart';
import 'package:first_flutter/screens/user_screens/BookProviderProvider.dart';
import 'package:first_flutter/screens/user_screens/Home/CategoryProvider.dart';
import 'package:first_flutter/screens/user_screens/Profile/EditProfileProvider.dart';
import 'package:first_flutter/screens/user_screens/Profile/EditProfileScreen.dart';
import 'package:first_flutter/screens/user_screens/Profile/FAQProvider.dart';
import 'package:first_flutter/screens/user_screens/Profile/UserProfileProvider.dart';
import 'package:first_flutter/screens/user_screens/SubCategory/SubCategoryProvider.dart';
import 'package:first_flutter/screens/user_screens/SubCategory/SubCategoryStateProvider.dart';
import 'package:first_flutter/screens/user_screens/SubCategory/sub_cat_of_cat_screen.dart';
import 'package:first_flutter/screens/user_screens/User%20Instant%20Service/UserInstantServiceProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/BookingProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/EmergencyContactProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/RazorpayProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/SOSProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/UserChats/UserChatProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/UserSOSProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/ServiceProvider.dart';
import 'package:first_flutter/screens/user_screens/navigation/user_service_tab_body/UserCompletedServiceProvider.dart';
import 'package:first_flutter/screens/user_screens/user_custom_bottom_nav.dart';
import 'package:first_flutter/screens/user_screens/User%20Instant%20Service/user_instant_service_screen.dart';
import 'package:first_flutter/screens/user_screens/Profile/user_profile_screen.dart';
import 'package:first_flutter/screens/user_screens/user_service_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'BannerModel.dart';
import 'NATS Service/NatsService.dart';
import 'NotificationService.dart';
import 'baseControllers/NavigationController/navigation_controller.dart';
import 'firebase_options.dart';
import 'screens/commonOnboarding/loginScreen/login_screen.dart';
import 'screens/commonOnboarding/loginScreen/login_screen_provider.dart';
import 'screens/commonOnboarding/splashScreen/splash_screen.dart';
import 'screens/commonOnboarding/splashScreen/splash_screen_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handling
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("=== 🔔 BACKGROUND Message Received ===");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");

  // Background notifications are automatically shown by Firebase
  // You can add custom logic here if needed
}

// ================== MAIN ==================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("=== 🚀 App Starting ===");

  try {
    // 1. Initialize NATS Service
    print("📡 Initializing NATS...");
    await NatsService().initialize(
      url: 'nats://api.moyointernational.com',
      autoReconnect: true,
      reconnectInterval: const Duration(seconds: 5),
    );
    print("✅ NATS initialized");

    // 2. Initialize Firebase
    print("🔥 Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized");

    // 3. Set Background Message Handler (MUST be before notification init)
    print("📨 Setting background message handler...");
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print("✅ Background handler set");

    // 4. Initialize Notification Service
    print("🔔 Initializing notifications...");
    await NotificationService.initializeNotifications();
    print("✅ Notifications initialized");

    // 5. Setup Token Refresh Listener
    NotificationService.setupTokenRefreshListener();
    print("✅ Token refresh listener setup");

    print("=== ✅ All Services Initialized Successfully ===\n");
  } catch (e) {
    print("=== ❌ Initialization Error: $e ===");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => OtpScreenProvider()),
        ChangeNotifierProvider(create: (_) => UserNavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProviderNavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SubcategoryProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => MySkillProvider()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()),
        ChangeNotifierProvider(create: (_) => SubCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ServiceFormFieldProvider()),
        ChangeNotifierProvider(create: (_) => ProviderProfileProvider()),
        ChangeNotifierProvider(create: (_) => EditProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserInstantServiceProvider()),
        ChangeNotifierProvider(create: (_) => MyAddressProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => EditProviderProfileProvider()),
        ChangeNotifierProvider(create: (_) => ProviderBidProvider()),
        ChangeNotifierProvider(create: (_) => BookProviderProvider()),
        ChangeNotifierProvider(create: (_) => ProviderServiceProvider()),
        ChangeNotifierProvider(create: (_) => ServiceArrivalProvider()),
        ChangeNotifierProvider(create: (_) => StartWorkProvider()),
        ChangeNotifierProvider(create: (_) => FAQProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserNotificationProvider()),
        ChangeNotifierProvider(create: (_) => LegalDocumentProvider()),
        ChangeNotifierProvider(create: (_) => CompletedServiceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => UserChatProvider()),
        ChangeNotifierProvider(create: (_) => ProviderChatProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyContactProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()),
        ChangeNotifierProvider(create: (_) => UserSOSProvider()),
        ChangeNotifierProvider(create: (_) => RazorpayProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NatsService _natsService = NatsService();
  bool _notificationPermissionRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to NATS connection status
    _natsService.connectionStream.listen((isConnected) {
      debugPrint('📡 NATS: ${isConnected ? "Connected ✅" : "Disconnected ❌"}');
    });

    // Request notification permission after delay
    Future.delayed(const Duration(seconds: 2), () {
      _requestNotificationPermissionIfNeeded();
    });
  }

  // Request Notification Permission
  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;

    if (mounted && context != null) {
      final granted = await NotificationService.requestNotificationPermission(
        context,
      );
      debugPrint(
        '📢 Notification permission: ${granted ? "✅ Granted" : "❌ Denied"}',
      );

      if (granted) {
        final token = await NotificationService.getDeviceToken();
        debugPrint('🔑 FCM Token: $token');
        // TODO: Send token to your backend
        // await YourApiService.sendTokenToServer(token);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App Resumed');
        if (!_natsService.isConnected) {
          _natsService.reconnect();
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App Paused');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App Inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App Detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App Hidden');
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return SafeArea(
          top: false,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: NotificationService.navigatorKey,

            theme: ThemeData(
              textTheme: GoogleFonts.robotoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            initialRoute: '/splash',
            routes: {
              '/splash': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/UserCustomBottomNav': (_) => const UserCustomBottomNav(),
              '/UserServiceDetailsScreen': (_) =>
                  const UserServiceDetailsScreen(),
              '/editProfile': (_) => const EditProfileScreen(),
              '/provider_bid_details': (_) =>
                  const ProviderServiceDetailsScreen(serviceId: "null"),
              '/ProviderCustomBottomNav': (_) =>
                  const ProviderCustomBottomNav(),
              '/UserProfileScreen': (_) => const UserProfileScreen(),
              '/SubCatOfCatScreen': (_) => const SubCatOfCatScreen(),
              '/providerProfile': (context) => ProviderProfileScreen(),
              '/editProviderProfile': (context) => EditProviderProfileScreen(),
              '/ProviderOnboarding': (context) =>
                  const ProviderOnboardingDialog(),
              '/UserInstantServiceScreen': (_) =>
                  const UserInstantServiceScreen(
                    categoryId: 1,
                    serviceType: '',
                  ),
              '/EmailVerificationScreen': (context) {
                final email =
                    ModalRoute.of(context)?.settings.arguments as String?;
                return ChangeNotifierProvider(
                  create: (_) => OtpScreenProvider(),
                );
              },
            },
          ),
        );
      },
    );
  }
}
