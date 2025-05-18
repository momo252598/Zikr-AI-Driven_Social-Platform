import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:shared_preferences/shared_preferences.dart';

// Reference the global instance from main.dart
import 'package:software_graduation_project/main.dart' as main_app;
import 'package:software_graduation_project/services/chat_notification_helper.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Platform channel for native Android notification settings
  static const platform = MethodChannel(
      'com.example.software_graduation_project/notification_util');

  // Use the globally initialized plugin from main.dart
  FlutterLocalNotificationsPlugin get _notificationsPlugin =>
      main_app.flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _isRequestingPermission = false;
  // Channel IDs
  static const String prayerChannelId = 'prayer_channel_id';
  static const String messageChannelId = 'message_channel_id';
  static const String socialChannelId = 'social_channel_id';
  // Setup notification channel through native platform code
  Future<void> setupNativeNotificationChannel() async {
    // Skip for web platform
    if (kIsWeb) {
      debugPrint('Skipping native notification channel setup on web platform');
      return;
    }

    try {
      await platform.invokeMethod('setupNotificationChannel');
      debugPrint('Native notification channel setup completed');
    } catch (e) {
      debugPrint('Failed to setup native notification channel: $e');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    debugPrint('Initializing notification service');

    // Set up the native notification channel for heads-up display
    await setupNativeNotificationChannel();

    // Create the notification channels for Android
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Prayer notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          prayerChannelId,
          'Prayer Times',
          description: 'Notifications for prayer times',
          importance: Importance.high,
          // Using default sound instead of custom sound
          playSound: true,
        ),
      );

      // Message notifications channel with highest importance for heads-up display
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          messageChannelId,
          'Messages',
          description: 'Notifications for new messages',
          importance: Importance.max,
          playSound: true,
          showBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // Social notifications channel for likes and comments
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          socialChannelId,
          'Social',
          description: 'Notifications for likes and comments',
          importance: Importance.high,
          playSound: true,
          showBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      debugPrint('Created Android notification channels');
    }

    _isInitialized = true;
    debugPrint('Notification service initialized successfully');
  }

  // Check permissions without requesting
  Future<bool> checkPermissions() async {
    debugPrint('Checking notification permissions');
    final notificationStatus =
        await permission_handler.Permission.notification.status;

    debugPrint('Notification permission status: ${notificationStatus.name}');

    return notificationStatus.isGranted;
  }

  // Request permissions safely
  Future<bool> requestPermissions({BuildContext? context}) async {
    if (_isRequestingPermission) {
      debugPrint('Already requesting permissions, skipping');
      return false;
    }

    try {
      _isRequestingPermission = true;
      debugPrint('Requesting notification permissions');

      // Request notification permission
      final notificationStatus =
          await permission_handler.Permission.notification.request();
      debugPrint(
          'Notification permission request result: ${notificationStatus.name}');

      if (!notificationStatus.isGranted) {
        debugPrint('Notification permission denied');
        _isRequestingPermission = false;
        return false;
      }

      // Request exact alarms permission on newer Android versions
      try {
        // Check if the current platform supports scheduleExactAlarm permission
        var alarmStatus =
            await permission_handler.Permission.scheduleExactAlarm.status;
        if (!alarmStatus.isGranted) {
          // Try to request permission if it's not already granted
          alarmStatus =
              await permission_handler.Permission.scheduleExactAlarm.request();
          debugPrint('Exact alarm permission status: ${alarmStatus.name}');
        }
      } catch (e) {
        // If the permission doesn't exist on this device/platform, just log it
        debugPrint('Schedule exact alarm permission check failed: $e');
      }

      _isRequestingPermission = false;
      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      _isRequestingPermission = false;
      return false;
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint(
        'showNotification called with ID: $id, Title: $title, Body: $body');
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized, initializing now.');
      await initialize();
    }

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            prayerChannelId,
            'General Notifications',
            channelDescription: 'General notifications for the app',
            importance: Importance.max,
            priority: Priority.max,
            // Additional settings for heads-up notifications
            fullScreenIntent: true,
            category: AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
            ticker: 'New Notification',
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 200, 200, 200]),
            color: const Color(0xFF2196F3), // Material blue color
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('Notification shown successfully with ID: $id');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Schedule a notification with permission check
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int minutesBefore = 15,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if permissions are granted
    if (!await checkPermissions()) {
      debugPrint(
          'Notification permissions not granted, cannot schedule prayer notifications');
      return;
    }

    // Convert UTC time to local time if needed
    final localScheduledTime =
        scheduledTime.isUtc ? scheduledTime.toLocal() : scheduledTime;

    // Calculate notification time (e.g., 1 minute before prayer)
    final notificationTime =
        localScheduledTime.subtract(Duration(minutes: minutesBefore));

    debugPrint(
        'Scheduling notification for $title at ${notificationTime.toString()} (local time)');

    // For immediate or near-immediate notifications (within 5 seconds), use the direct show method
    final now = DateTime.now();
    if (notificationTime.isBefore(now) ||
        notificationTime.difference(now).inSeconds < 5) {
      debugPrint('Time is very soon or past, showing immediate notification');
      return showNotification(
        id: id,
        title: title,
        body: body,
      );
    }

    // Create Android-specific notification details with updated ID
    final androidDetails = AndroidNotificationDetails(
      prayerChannelId,
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.high,
      // Add additional settings to increase visibility
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      // Using default system sound
      playSound: true,
      actions: [
        const AndroidNotificationAction('dismiss', 'Dismiss'),
      ],
    );

    // Create iOS-specific notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine platform-specific notification details
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Create a TZDateTime that properly respects local timezone
      final tz.TZDateTime tzDateTime =
          tz.TZDateTime.from(notificationTime, tz.local);

      // Cancel any existing notification with this ID before scheduling a new one
      await _notificationsPlugin.cancel(id);

      // Include the required androidScheduleMode parameter
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
          'Scheduled notification for $title at ${tzDateTime.toString()} (TZ local time), ID: $id');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled');
  }

  // Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Show social notification for likes or comments
  Future<void> showSocialNotification({
    required int id,
    required String title,
    required String body,
    required String notificationType,
    required String senderId,
    required String postId,
  }) async {
    debugPrint(
        'showSocialNotification called with ID: $id, Title: $title, Type: $notificationType');
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized, initializing now.');
      await initialize();
    }

    try {
      // Create the payload with all necessary data for navigation
      final String payload = json.encode({
        'type': 'social_notification',
        'notificationType': notificationType,
        'senderId': senderId,
        'postId': postId,
      });

      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            socialChannelId,
            'Social Notifications',
            channelDescription: 'Notifications for social interactions',
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.social,
            visibility: NotificationVisibility.public,
            ticker: 'New Social Notification',
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 200, 200, 200]),
            color: const Color(0xFF6A3DE2), // Purple color
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint(
          'Social notification sent. ID: $id, Title: $title, Payload: $payload');
    } catch (e) {
      debugPrint('Error showing social notification: $e');
    }
  }

  // Cleanup old notification metadata to prevent memory leaks
  Future<void> cleanupOldNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Get all keys that start with "last_notification_"
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('last_notification_'))
          .toList();

      debugPrint('Cleaning up ${keys.length} notification metadata entries');

      // Clean up entries older than 30 minutes
      for (final key in keys) {
        try {
          final data = prefs.getString(key);
          if (data != null) {
            final jsonData = json.decode(data);
            final timestamp = jsonData['timestamp'] as int?;

            if (timestamp != null) {
              // If older than 30 minutes, remove it
              if (now - timestamp > 30 * 60 * 1000) {
                await prefs.remove(key);
                debugPrint('Removed stale notification data: $key');
              }
            }
          }
        } catch (e) {
          // If we can't parse the data, just remove it
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up notification data: $e');
    }
  }

  // Show message notification with message-specific channel
  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String messageContent,
    String? conversationId,
  }) async {
    debugPrint(
        'showMessageNotification called with ID: $id, Sender: $senderName, Message: $messageContent, Conv: $conversationId');
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized, initializing now.');
      await initialize();
    }

    // Check if user is currently in this conversation
    final chatNotificationHelper = ChatNotificationHelper();
    if (conversationId != null &&
        chatNotificationHelper.isInConversation(conversationId)) {
      debugPrint(
          'User is in conversation $conversationId, skipping notification.');
      return;
    } // Check for duplicate notifications with similar content in the foreground
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationKey =
          'last_notification_${conversationId ?? "unknown"}';
      final lastNotificationData = prefs.getString(lastNotificationKey);

      // Import main app from the global import to check app state
      final appState = main_app.appState;
      // Use different time thresholds based on app state
      final timeThreshold = appState == AppLifecycleState.resumed
          ? 500
          : 5000; // 0.5 sec for foreground, 5 sec for background

      if (lastNotificationData != null) {
        final lastData = json.decode(lastNotificationData);
        final lastTimestamp = lastData['timestamp'] as int;
        final lastMessage = lastData['message'] as String;
        final now = DateTime.now().millisecondsSinceEpoch;

        // If we showed a notification for this conversation with same content recently, skip
        if (now - lastTimestamp < timeThreshold &&
            lastMessage == messageContent) {
          debugPrint(
              'Duplicate notification detected within ${timeThreshold}ms: $conversationId - $messageContent');
          return;
        }
      }

      // Store this notification data to prevent duplicates
      await prefs.setString(
          lastNotificationKey,
          json.encode({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'message': messageContent,
          }));
    } catch (e) {
      // If there's an error checking for duplicates, continue showing the notification
      debugPrint('Error checking for duplicate notifications: $e');
    }
    try {
      await _notificationsPlugin.show(
        id,
        senderName,
        messageContent,
        NotificationDetails(
          android: AndroidNotificationDetails(
            messageChannelId,
            'Messages',
            channelDescription: 'Notifications for new messages',
            importance: Importance.max,
            priority: Priority.max,
            // Enhanced settings specifically for heads-up notifications
            fullScreenIntent: true,
            category: AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
            ticker: 'New Message',
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 200, 200, 200]),
            color: const Color(0xFF2196F3), // Material blue color
            showWhen: true,
            // These flags are crucial for heads-up display
            channelShowBadge: true,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode({
          'type': 'chat_message',
          'conversationId': conversationId,
        }),
      );
      debugPrint('Message notification shown successfully with ID: $id');
    } catch (e) {
      debugPrint('Error showing message notification: $e');
    }
  }
}
