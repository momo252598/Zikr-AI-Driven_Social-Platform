import 'dart:async';
import 'dart:core'; // Explicitly import core library for DateTime
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/components/prayers/geolocation_provider.dart'; // added new helper import
import 'package:software_graduation_project/services/notification_service.dart'; // import for notifications
import 'package:shared_preferences/shared_preferences.dart';

// Model for Prayer
class Prayer {
  final String name;
  // Ensure we're using the correct DateTime type
  DateTime time;
  Prayer({required this.name, required this.time});
}

// Retrieve location and compute prayer times using adhan_dart package.
Future<List<Prayer>> getPrayerTimes() async {
  final Coordinates coordinates;
  final now = DateTime.now();
  if (kIsWeb) {
    // Use dynamic location on web using helper.
    coordinates = await getCurrentCoordinates();
  } else {
    final location = Location();
    // Check service
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) throw Exception("Location service disabled");
    }
    // Check permission
    var permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted)
        throw Exception("Location permission denied");
    }
    final locationData = await location.getLocation();
    coordinates = Coordinates(locationData.latitude!, locationData.longitude!);
  }

  // Dates: today and tomorrow
  final today = now;
  final tomorrow = now.add(const Duration(days: 1));

  CalculationParameters params = CalculationMethod.muslimWorldLeague();
  params.madhab = Madhab.shafi;

  final todayTimes = PrayerTimes(
    coordinates: coordinates,
    date: today,
    calculationParameters: params,
    precision: true,
  );
  final tomorrowTimes = PrayerTimes(
    coordinates: coordinates,
    date: tomorrow,
    calculationParameters: params,
    precision: true,
  );

  DateTime shiftedOrNext(DateTime? todayTime, DateTime? tomorrowTime) {
    final t = todayTime ?? DateTime.now();
    return t.isAfter(now) ? t : (tomorrowTime ?? DateTime.now());
  }

  return [
    Prayer(
        name: "الفجر",
        time: shiftedOrNext(todayTimes.fajr, tomorrowTimes.fajr)),
    Prayer(
        name: "الظهر",
        time: shiftedOrNext(todayTimes.dhuhr, tomorrowTimes.dhuhr)),
    Prayer(
        name: "العصر", time: shiftedOrNext(todayTimes.asr, tomorrowTimes.asr)),
    Prayer(
        name: "المغرب",
        time: shiftedOrNext(todayTimes.maghrib, tomorrowTimes.maghrib)),
    Prayer(
        name: "العشاء",
        time: shiftedOrNext(todayTimes.isha, tomorrowTimes.isha)),
  ];
}

// PrayerCard widget showing an icon, prayer time, and time left.
class PrayerCard extends StatelessWidget {
  final Prayer prayer;
  final bool isClosest; // new flag
  const PrayerCard({Key? key, required this.prayer, this.isClosest = false})
      : super(key: key);

  // Map for prayer icons.
  IconData _getIcon(String name) {
    switch (name) {
      case "الفجر":
        return Icons.wb_twighlight;
      case "الظهر":
        return Icons.wb_sunny;
      case "العصر":
        return Icons.wb_sunny_rounded;
      case "المغرب":
        return Icons.wb_twilight;
      case "العشاء":
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  // Calculates time left until the prayer.
  String _timeLeft() {
    Duration diff = prayer.time.difference(DateTime.now());
    if (diff.isNegative) return "انتهى"; // translated text
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(diff.inHours);
    String minutes = twoDigits(diff.inMinutes.remainder(60));
    return "$hours:$minutes متبقي"; // appended "متبقي"
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          // Change decoration if isClosest is true.
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isClosest ? AppStyles.lightPurple : AppStyles.whitePurple,
            borderRadius: BorderRadius.circular(12),
            // border:
            //     isClosest ? Border.all(color: AppStyles.grey, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: AppStyles.purple.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(_getIcon(prayer.name),
                  size: 40,
                  color: isClosest ? AppStyles.white : AppStyles.purple),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prayer.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: isClosest
                                    ? AppStyles.white
                                    : AppStyles.purple)),
                    const SizedBox(height: 4),
                    Text(
                      "الوقت: ${TimeOfDay.fromDateTime(prayer.time.toLocal()).format(context)}", // updated label
                      style: TextStyle(
                        fontSize: 16,
                        color: isClosest ? AppStyles.white : AppStyles.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLeft(),
                      style: TextStyle(
                          fontSize: 14,
                          color: isClosest ? AppStyles.white : AppStyles.grey),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Main page that displays prayer times.
class PrayersPage extends StatefulWidget {
  const PrayersPage({Key? key}) : super(key: key);

  @override
  _PrayersPageState createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage> with WidgetsBindingObserver {
  late Future<List<Prayer>> futurePrayers;
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = false;
  Timer? _refreshTimer;
  static const String PREFS_NOTIFICATIONS_KEY = 'prayer_notifications_enabled';

  @override
  void initState() {
    super.initState();

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    futurePrayers = getPrayerTimes();
    _loadNotificationPreference().then((_) {
      _initNotifications();
    });

    // Set up a periodic timer to refresh prayer times and notifications
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _refreshPrayerTimes();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background, refresh prayer times and notifications
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed from background, refreshing prayer times');
      _refreshPrayerTimes();
    } else if (state == AppLifecycleState.paused) {
      // When app goes to background, make sure notifications are scheduled
      if (_notificationsEnabled) {
        _scheduleNotifications();
      }
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _refreshTimer?.cancel();
    super.dispose();
  }

  // Load saved notification preference
  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(PREFS_NOTIFICATIONS_KEY) ?? false;
    });
    debugPrint('Loaded notification preference: $_notificationsEnabled');
  }

  // Save notification preference
  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFS_NOTIFICATIONS_KEY, value);
    debugPrint('Saved notification preference: $value');
  }

  // Refresh prayer times and reschedule notifications
  Future<void> _refreshPrayerTimes() async {
    setState(() {
      futurePrayers = getPrayerTimes();
    });

    // If notifications are enabled and NOT on web, reschedule them with the new prayer times
    if (_notificationsEnabled && !kIsWeb) {
      await _scheduleNotifications();
    }
  }

  // Initialize notification service
  Future<void> _initNotifications() async {
    // Skip notification initialization on web
    if (kIsWeb) {
      setState(() {
        _notificationsEnabled = false;
      });
      debugPrint('Notifications disabled on web platform');
      return;
    }

    debugPrint('Initializing prayer notifications');
    await _notificationService.initialize();
    final hasPermissions = await _notificationService.checkPermissions();
    setState(() {
      // Only update if notifications were previously enabled or permissions are granted
      if (_notificationsEnabled || hasPermissions) {
        _notificationsEnabled = hasPermissions;
        _saveNotificationPreference(hasPermissions);
      }
    });

    // Schedule notifications if permissions were granted
    if (hasPermissions && _notificationsEnabled) {
      await _scheduleNotifications();
    }
  }

  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    // Prevent requesting notifications on web
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الإشعارات غير متاحة في الموقع")),
      );
      return;
    }

    debugPrint('Requesting notification permissions for prayer times');
    final granted =
        await _notificationService.requestPermissions(context: context);
    setState(() {
      _notificationsEnabled = granted;
    });

    // Save the preference
    await _saveNotificationPreference(granted);

    if (granted) {
      // Schedule notifications immediately if permission was granted
      await _scheduleNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تفعيل الإشعارات بنجاح")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم يتم منح إذن الإشعارات")),
      );
    }
  }

  // Schedule notifications for all prayers
  Future<void> _scheduleNotifications() async {
    // Don't schedule notifications on web platform
    if (kIsWeb) {
      debugPrint('Skipping notification scheduling on web platform');
      return;
    }

    try {
      final prayers = await futurePrayers;
      // Cancel any existing notifications before scheduling new ones
      await _notificationService.cancelAllNotifications();

      // Schedule notifications for each prayer
      for (int i = 0; i < prayers.length; i++) {
        final prayer = prayers[i];
        if (prayer.time.isAfter(DateTime.now())) {
          await _notificationService.schedulePrayerNotification(
            id: i + 1, // Use index+1 as ID
            title: "حان وقت ${prayer.name}",
            body: "لا تنسى الصلاة في وقتها",
            scheduledTime: prayer.time,
            minutesBefore: 1, // Notify 1 minute before prayer time
          );
          // Add debug message to verify scheduling
          debugPrint(
              'Scheduled notification for ${prayer.name} at ${prayer.time} (1 minute before)');
        }
      }
      debugPrint('All prayer notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      // Silently fail if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      // Add notification toggle button in app bar only for mobile
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Only show notification button on mobile
          if (!kIsWeb)
            IconButton(
              icon: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: AppStyles.purple,
              ),
              onPressed: () {
                if (_notificationsEnabled) {
                  _notificationService.cancelAllNotifications();
                  setState(() {
                    _notificationsEnabled = false;
                    _saveNotificationPreference(false);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم إلغاء تفعيل الإشعارات")),
                  );
                } else {
                  _requestNotificationPermissions();
                }
              },
              tooltip:
                  _notificationsEnabled ? 'إلغاء التنبيهات' : 'تفعيل التنبيهات',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Prayer>>(
              future: futurePrayers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final prayers = snapshot.data!;
                final now = DateTime.now();
                Prayer? nextPrayer;
                Duration? closestDiff;
                for (var prayer in prayers) {
                  final diff = prayer.time.difference(now);
                  if (diff.isNegative) continue;
                  if (closestDiff == null || diff < closestDiff) {
                    closestDiff = diff;
                    nextPrayer = prayer;
                  }
                }
                return kIsWeb
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: prayers
                              .map((prayer) => PrayerCard(
                                    prayer: prayer,
                                    isClosest: nextPrayer != null &&
                                        prayer.name == nextPrayer.name,
                                  ))
                              .toList(),
                        ),
                      )
                    : Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: prayers
                                .map((prayer) => PrayerCard(
                                      prayer: prayer,
                                      isClosest: nextPrayer != null &&
                                          prayer.name == nextPrayer.name,
                                    ))
                                .toList(),
                          ),
                        ),
                      );
              },
            ),
          ),
          // Test buttons for notifications - hidden
          // if (!kIsWeb)
          //   Container(
          //     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          //     decoration: BoxDecoration(
          //       color: AppStyles.whitePurple,
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.1),
          //           blurRadius: 4,
          //           offset: const Offset(0, -2),
          //         ),
          //       ],
          //     ),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           "إختبار الإشعارات",
          //           style: TextStyle(
          //             fontSize: 18,
          //             fontWeight: FontWeight.bold,
          //             color: AppStyles.purple,
          //           ),
          //         ),
          //         const SizedBox(height: 12),
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceAround,
          //           children: [
          //             ElevatedButton(
          //               onPressed: () async {
          //                 // Request notification permissions if not already granted
          //                 final hasPermissions = await _notificationService
          //                     .requestPermissions(context: context);
          //                 if (!hasPermissions) {
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     const SnackBar(
          //                         content:
          //                             Text("يرجى منح الإذن للإشعارات أولاً")),
          //                   );
          //                   return;
          //                 }
          //
          //                 // Show immediate test notification
          //                 await _notificationService.showNotification(
          //                   id: 100,
          //                   title: "إشعار إختباري",
          //                   body: "هذا إشعار لإختبار نظام الإشعارات. الآن!",
          //                 );
          //                 ScaffoldMessenger.of(context).showSnackBar(
          //                   const SnackBar(
          //                       content: Text(
          //                           "تم إرسال إشعار اختباري. ستظهر خلال ثوانٍ")),
          //                 );
          //               },
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: AppStyles.purple,
          //                 foregroundColor: Colors.white,
          //               ),
          //               child: const Text("إشعار فوري"),
          //             ),
          //             ElevatedButton(
          //               onPressed: () async {
          //                 // Request notification permissions if not already granted
          //                 final hasPermissions = await _notificationService
          //                     .requestPermissions(context: context);
          //                 if (!hasPermissions) {
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     const SnackBar(
          //                         content:
          //                             Text("يرجى منح الإذن للإشعارات أولاً")),
          //                   );
          //                   return;
          //                 }
          //
          //                 // Schedule a delayed notification (testing background notification handling)
          //                 await _notificationService.schedulePrayerNotification(
          //                   id: 101,
          //                   title: "إشعار تجريبي مجدول",
          //                   body:
          //                       "هذا إشعار مجدول لإختبار نظام الإشعارات في الخلفية",
          //                   scheduledTime:
          //                       DateTime.now().add(const Duration(seconds: 10)),
          //                   minutesBefore: 0,
          //                 );
          //                 ScaffoldMessenger.of(context).showSnackBar(
          //                   const SnackBar(
          //                       content: Text(
          //                           "تم جدولة إشعار اختباري. سيظهر بعد ١٠ ثوانٍ")),
          //                 );
          //               },
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: AppStyles.lightPurple,
          //                 foregroundColor: Colors.white,
          //               ),
          //               child: const Text("إشعار بعد ١٠ ثوانٍ"),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         TextButton(
          //           onPressed: () async {
          //             await _notificationService.cancelAllNotifications();
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               const SnackBar(
          //                   content: Text("تم إلغاء جميع الإشعارات")),
          //             );
          //           },
          //           child: Text(
          //             "إلغاء كل الإشعارات",
          //             style: TextStyle(
          //               color: AppStyles.purple,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }
}
