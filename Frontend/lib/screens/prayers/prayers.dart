import 'dart:async';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/components/prayers/geolocation_provider.dart'; // added new helper import

// Model for Prayer
class Prayer {
  final String name;
  final DateTime time;
  Prayer({required this.name, required this.time});
}

// Retrieve location and compute prayer times using adhan_dart package.
Future<List<Prayer>> _getPrayerTimes() async {
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
    PermissionStatus permissionGranted = await location.hasPermission();
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
        name: "Fajr", time: shiftedOrNext(todayTimes.fajr, tomorrowTimes.fajr)),
    Prayer(
        name: "Dhuhr",
        time: shiftedOrNext(todayTimes.dhuhr, tomorrowTimes.dhuhr)),
    Prayer(name: "Asr", time: shiftedOrNext(todayTimes.asr, tomorrowTimes.asr)),
    Prayer(
        name: "Maghrib",
        time: shiftedOrNext(todayTimes.maghrib, tomorrowTimes.maghrib)),
    Prayer(
        name: "Isha", time: shiftedOrNext(todayTimes.isha, tomorrowTimes.isha)),
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
      case "Fajr":
        return Icons.wb_twighlight;
      case "Dhuhr":
        return Icons.wb_sunny;
      case "Asr":
        return Icons.wb_sunny_rounded;
      case "Maghrib":
        return Icons.wb_twilight;
      case "Isha":
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  // Calculates time left until the prayer.
  String _timeLeft() {
    Duration diff = prayer.time.difference(DateTime.now());
    if (diff.isNegative) return "Passed";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(diff.inHours);
    String minutes = twoDigits(diff.inMinutes.remainder(60));
    return "$hours:$minutes left";
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
            color: isClosest ? AppStyles.lightPurple : Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            // border:
            //     isClosest ? Border.all(color: AppStyles.grey, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(_getIcon(prayer.name),
                  size: 40, color: isClosest ? AppStyles.white : Colors.purple),
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
                                    : Colors.purple)),
                    const SizedBox(height: 4),
                    Text(
                      "Time: ${TimeOfDay.fromDateTime(prayer.time.toLocal()).format(context)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: isClosest ? AppStyles.white : Colors.purple,
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

class _PrayersPageState extends State<PrayersPage> {
  late Future<List<Prayer>> futurePrayers;

  @override
  void initState() {
    super.initState();
    futurePrayers = _getPrayerTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      // appBar removed or uncomment if needed.
      body: FutureBuilder<List<Prayer>>(
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
          return Center(
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
    );
  }
}
