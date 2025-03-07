import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:software_graduation_project/screens/chat/chat.dart';
import 'screens/home/home.dart';
import 'screens/quran/quran.dart';
import 'package:software_graduation_project/screens/quran/quran_sura_page.dart';
import 'screens/prayers/prayers.dart';
import 'screens/chat/all_chats.dart';
import 'screens/chat/chat.dart';
import 'screens/profile/profile.dart';
import 'screens/community/community.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/base/res/media.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart';
import 'package:software_graduation_project/screens/quran/quran_web/responsive_quran_layout.dart';

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
      widgetjsonData != null
          ? kIsWeb
              ? ResponsiveQuranLayout(suraJsonData: widgetjsonData)
              : QuranPage2(suraJsonData: widgetjsonData)
          : const Center(child: CircularProgressIndicator()),
      const PrayersPage(),
      // kIsWeb ? const BrowserChatLayout() : const AllChatsPage(),
      const CommunityPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // set app to RTL
      child: Scaffold(
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
            "تطبيق القرآن الكريم", // translated title
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(FlutterIslamicIcons.solidQuran2), label: 'القرآن'),
            BottomNavigationBarItem(
                icon: Icon(FlutterIslamicIcons.solidPrayer), label: 'الصلاة'),
            BottomNavigationBarItem(
                icon: Icon(FlutterIslamicIcons.solidCommunity),
                label: 'المجتمع'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'الملف الشخصي'),
          ],
        ),
      ),
    );
  }
}
