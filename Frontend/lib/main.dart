import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // import ScreenUtil
import 'package:software_graduation_project/screens/Signup/signup.dart';
import 'package:software_graduation_project/screens/signin/signin.dart';
import 'package:software_graduation_project/components/signup/sign_up_form.dart';
import 'package:software_graduation_project/skeleton.dart';
import 'package:software_graduation_project/screens/prayers/prayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/services/api_service.dart';
import 'package:software_graduation_project/services/firebase_messaging_service.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/screens/chat/chat.dart';
// Import the safe animation controller
import 'package:software_graduation_project/utils/safe_animation_controller.dart';
// Import notification services
import 'package:software_graduation_project/services/notification_service.dart'
    as notification_service;
import 'package:software_graduation_project/services/message_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
// Import forgot password screen
import 'package:software_graduation_project/screens/forgot_password/forgot_password.dart';

// Define a global navigator key to enable navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Store the last tapped notification conversation ID for background handling
String? _lastTappedConversationId;

// Initialize the notification plugin early for background handling
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Track app state globally so it can be accessed by notification services
AppLifecycleState appState = AppLifecycleState.resumed;

// This callback is called for background notification handling
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle notification tap when app is in background or closed
  debugPrint(
      'Notification tapped in background: ${notificationResponse.payload}');

  // If the payload contains a conversation ID, store it for navigation when app opens
  final payload = notificationResponse.payload;
  if (payload != null && payload.isNotEmpty) {
    try {
      // Try to parse as JSON first
      Map<String, dynamic> payloadData;
      try {
        payloadData = json.decode(payload);
      } catch (e) {
        // If not JSON, use as raw string
        payloadData = {'conversationId': payload};
      }

      // Extract the conversation ID
      final conversationId = payloadData['conversationId']?.toString();
      if (conversationId != null) {
        // Store in the global variable so it can be accessed when app starts
        _lastTappedConversationId = conversationId;
        debugPrint(
            'Background/terminated: Should navigate to conversation: $conversationId when app opens');
        // We can't navigate here directly as the app might not be fully initialized
      }
    } catch (e) {
      debugPrint('Error processing notification payload: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data early
  tz_data.initializeTimeZones();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permissions early for FCM
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: false,
    criticalAlert: true,
    provisional: false,
    sound: true,
  );

  // Set foreground notification presentation options to show alerts
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  // Initialize notification plugin early for background notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    // Request critical alert authorization for important notifications
    requestCriticalPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      debugPrint('Notification clicked in foreground: ${details.payload}');
      // Handle foreground notification taps the same way as background taps
      // This ensures consistent behavior regardless of app state
      if (details.payload != null && details.payload!.isNotEmpty) {
        try {
          // Try to parse as JSON first
          Map<String, dynamic> payloadData;
          try {
            payloadData = json.decode(details.payload!);
          } catch (e) {
            // If not JSON, use as raw string
            payloadData = {'conversationId': details.payload};
          }

          // If this is a chat message, store the conversation ID for navigation
          if (payloadData['type'] == 'chat_message') {
            final conversationId = payloadData['conversationId']?.toString();
            if (conversationId != null) {
              debugPrint(
                  'Foreground: Should navigate to conversation: $conversationId');

              // Get Firebase messaging service instance and store the navigation data
              final messagingService = FirebaseMessagingService();
              messagingService.navigateToChat(conversationId);
            }
          }
        } catch (e) {
          debugPrint('Error processing foreground notification payload: $e');
        }
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  // Initialize notification service with explicit import reference
  final notificationService = notification_service.NotificationService();
  await notificationService.initialize();

  // DEBUG: Print notification initialization status
  debugPrint('Notification service initialized in main.dart');

  // Initialize auth service and check for existing session
  final authService = AuthService();
  bool isLoggedIn = await authService.initializeAuth();

  // Validate the authentication by making a test API call
  if (isLoggedIn) {
    debugPrint('Found stored session, validating token...');
    final apiService = ApiService();
    try {
      // Try to validate the token using the check-auth endpoint
      await apiService.get('/accounts/check-auth/');
      debugPrint('Token validation successful');
    } catch (e) {
      debugPrint('Token validation failed: $e');
      // If validation fails, clear the session and start fresh
      await authService.logout();
      isLoggedIn = false;
    }
  }

  // Check if we have a pending notification from terminated state
  if (_lastTappedConversationId != null) {
    debugPrint(
        'Found notification tap from terminated state at app launch: $_lastTappedConversationId');
    // Get messaging service to handle the navigation once app fully loads
    final messagingService = FirebaseMessagingService();
    messagingService.navigateToChat(_lastTappedConversationId!);
    // Clear it after setting up navigation
    _lastTappedConversationId = null;
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final MessageNotificationService _messageNotificationService =
      MessageNotificationService();
  Timer? _notificationCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize Firebase Messaging Service
    _messagingService.initialize().then((_) async {
      await _checkForPendingNotificationNavigation();
    });

    // Periodically check for notification navigation (in case it wasn't processed yet)
    _notificationCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _checkForPendingNotificationNavigation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Forward app lifecycle state changes to notification services
    debugPrint('App lifecycle state changed to: ${state.toString()}');

    // Update global app state
    appState = state;

    // Notify services
    _messageNotificationService.setAppState(state);
    _messagingService.setAppState(state);

    if (state == AppLifecycleState.resumed) {
      // Refresh messages when app comes to foreground
      _checkForPendingNotificationNavigation();

      // Clean up old notification data when app comes to foreground
      final notificationService = notification_service.NotificationService();
      notificationService.cleanupOldNotificationData();
    }
  }

  Future<void> _checkForPendingNotificationNavigation() async {
    // First check the Firebase messaging service for navigation data
    final navigationData =
        _messagingService.getAndClearNotificationNavigation();
    if (navigationData != null && navigationData['type'] == 'chat') {
      final conversationId = navigationData['conversationId'];
      if (conversationId != null) {
        debugPrint(
            'Processing navigation to chat from messaging service: $conversationId');
        // Get Firebase ID and find the corresponding Django ID using a service
        await _handleChatNavigation(conversationId);
        return;
      }
    }

    // Then check the global variable for terminated app state notifications
    if (_lastTappedConversationId != null) {
      debugPrint(
          'Found pending notification navigation from terminated state: $_lastTappedConversationId');
      String conversationId = _lastTappedConversationId!;
      // Clear the global variable to prevent duplicate navigation
      _lastTappedConversationId = null;
      // Handle the navigation
      await _handleChatNavigation(conversationId);
    }
  }

  Future<void> _handleChatNavigation(String conversationId) async {
    debugPrint('Handling chat navigation to conversation: $conversationId');

    try {
      // Check if this is a numeric ID (Django ID) or a Firebase ID
      bool isNumeric = int.tryParse(conversationId) != null;

      if (isNumeric) {
        // This is already a Django ID, navigate directly
        int djangoId = int.parse(conversationId);
        debugPrint('Navigating directly to Django conversation ID: $djangoId');

        // Navigate to the chat screen using the global navigator key
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).push(
            MaterialPageRoute(builder: (context) => ChatPage(chatId: djangoId)),
          );
          return;
        }
      } else {
        // This is a Firebase ID, need to find the corresponding Django ID
        final chatApiService = ChatApiService();
        final conversations = await chatApiService.getConversations();

        // Look for matching Firebase ID
        for (var conversation in conversations) {
          if (conversation['firebase_id'] == conversationId) {
            final djangoId = conversation['id'];
            debugPrint('Found matching Django conversation ID: $djangoId');

            // Navigate to the chat screen using the global navigator key
            if (navigatorKey.currentContext != null && djangoId != null) {
              Navigator.of(navigatorKey.currentContext!).push(
                MaterialPageRoute(
                    builder: (context) => ChatPage(chatId: djangoId)),
              );
              return;
            }
          }
        }

        debugPrint(
            'Could not find matching Django conversation ID for Firebase ID: $conversationId');
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true, // this sets _minTextAdapt
      builder: (context, child) {
        return MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => AuthService()),
            Provider<ApiService>(create: (_) => ApiService()),
          ],
          child: MaterialApp(
            navigatorKey:
                navigatorKey, // Add global navigator key for notification navigation
            title: 'Zikr',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              // Use safe page transitions to prevent animation crashes
              pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  // Use a custom page transition that uses the safe animation controller
                  TargetPlatform.android: SafePageTransitionsBuilder(),
                  TargetPlatform.iOS: SafePageTransitionsBuilder(),
                  TargetPlatform.linux: SafePageTransitionsBuilder(),
                  TargetPlatform.macOS: SafePageTransitionsBuilder(),
                  TargetPlatform.windows: SafePageTransitionsBuilder(),
                },
              ),
            ),
            // Start with either home screen or login screen based on auth status
            initialRoute: widget.isLoggedIn ? '/skeleton' : '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/skeleton': (context) =>
                  Skeleton(key: Skeleton.navigatorKey), // Move key here
              '/signup': (context) => const SignUpScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              // Other routes...
            },
          ),
        );
      },
    );
  }
}

/// A custom page transitions builder that uses SafeAnimationController
class SafePageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use a FadeTransition which uses the safe animation controller internally
    return FadeTransition(opacity: animation, child: child);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
