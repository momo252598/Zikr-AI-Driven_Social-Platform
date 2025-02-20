import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';

// A page to test and display prayer times
class PrayerTestPage extends StatefulWidget {
  const PrayerTestPage({Key? key}) : super(key: key);

  @override
  _PrayerTestPageState createState() => _PrayerTestPageState();
}

class _PrayerTestPageState extends State<PrayerTestPage> {
  late Future<PrayerTimes> futurePrayerTimes;
  final Location location = Location();

  @override
  void initState() {
    super.initState();
    futurePrayerTimes = _getPrayerTimes();
  }

  Future<PrayerTimes> _getPrayerTimes() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) throw Exception("Location service disabled");
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted)
        throw Exception("Location permission denied");
    }
    final locationData = await location.getLocation();
    final coordinates =
        Coordinates(locationData.latitude!, locationData.longitude!);
    final params = CalculationMethod.karachi.getParameters();
    final dateComponents = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, dateComponents, params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Prayer Times')),
      body: FutureBuilder<PrayerTimes>(
        future: futurePrayerTimes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final prayerTimes = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Prayer Times for Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Fajr: ${DateFormat.jm().format(prayerTimes.fajr)}'),
                Text('Sunrise: ${DateFormat.jm().format(prayerTimes.sunrise)}'),
                Text('Dhuhr: ${DateFormat.jm().format(prayerTimes.dhuhr)}'),
                Text('Asr: ${DateFormat.jm().format(prayerTimes.asr)}'),
                Text('Maghrib: ${DateFormat.jm().format(prayerTimes.maghrib)}'),
                Text('Isha: ${DateFormat.jm().format(prayerTimes.isha)}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PrayerTestPage(),
  ));
}
