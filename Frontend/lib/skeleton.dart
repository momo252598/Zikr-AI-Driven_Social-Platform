import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home/home.dart';
import 'screens/quran/quran.dart';
import 'package:software_graduation_project/screens/quran/quran_sura_page.dart';
import 'screens/prayers/prayers.dart';
import 'screens/chat/chat.dart';
import 'screens/profile/profile.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/base/res/media.dart';
import '../../base/res/styles/app_styles.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key});

  @override
  _SkeletonState createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  var widgetjsonData;

  loadJsonAsset() async {
    final String jsonString =
        await rootBundle.loadString('assets/utils/surahs.json');
    var data = jsonDecode(jsonString);
    setState(() {
      widgetjsonData = data;
    });
    // final String jsonString2 =
    //     await rootBundle.loadString('assets/utils/surahs.json');
    // var data2 = jsonDecode(jsonString2);
  }

  @override
  void initState() {
    loadJsonAsset(); // initialize JSON on startup
    super.initState();
  }

  int _currentIndex = 0;

  List<Widget> get _pages {
    return [
      const HomePage(),
      // const HomePage(),
      QuranPage2(
        suraJsonData: widgetjsonData,
      ),
      const PrayersPage(),
      const ChatPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Custom beautiful app bar with gradient and pattern image
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppStyles.darkPurple,
                AppStyles.lightPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: const DecorationImage(
              image: AssetImage(AppMedia
                  .pattern3), // add a suitable Islamic pattern image in assets
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(96, 255, 255, 255),
                BlendMode.dstATop,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Al-Quran",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: AppStyles.white,
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppStyles.bgColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppStyles.lightPurple,
        unselectedItemColor:
            AppStyles.grey, // Updated color for better visibility
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(FlutterIslamicIcons.solidQuran2), label: 'Quran'),
          BottomNavigationBarItem(
              icon: Icon(FlutterIslamicIcons.prayer), label: 'Prayers'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
