import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

// Reference the global instance from main.dart
import 'package:software_graduation_project/main.dart' as main_app;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Use the globally initialized plugin from main.dart
  FlutterLocalNotificationsPlugin get _notificationsPlugin =>
      main_app.flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _isRequestingPermission = false;

  // Channel IDs
  static const String prayerChannelId = 'prayer_channel_id';
  static const String messageChannelId = 'message_channel_id';

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    debugPrint('Initializing notification service');

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

      // Message notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          messageChannelId,
          'Messages',
          description: 'Notifications for new messages',
          importance: Importance.high,
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
    if (!_isInitialized) {
      debugPrint(
          'Initializing notification service for immediate notification');
      await initialize();
    }

    debugPrint('Showing immediate notification: $title');

    // Create Android notification details
    const androidDetails = AndroidNotificationDetails(
      prayerChannelId,
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Prayer time notification',
      // Additional settings for visibility
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      // Using default system sound
      playSound: true,
    );

    // Create iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine platform-specific notification details
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('Immediate notification sent successfully');
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

  // Show message notification with message-specific channel
  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String messageContent,
    String? conversationId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Create notification title and body from sender and message content
    final title = senderName;
    final body = messageContent;

    debugPrint('Showing message notification: $title - $messageContent');

    // Create Android notification details with message channel
    final androidDetails = AndroidNotificationDetails(
      messageChannelId, // Use the message-specific channel
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'New message notification',
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
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: conversationId, // Store conversation ID in the payload
      );
      debugPrint('Message notification sent successfully');
    } catch (e) {
      debugPrint('Error showing message notification: $e');
    }
  }
}
