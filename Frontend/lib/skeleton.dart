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
import 'screens/community/create_post.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/base/res/media.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart';
import 'package:software_graduation_project/screens/quran/quran_web/responsive_quran_layout.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';

class Skeleton extends StatefulWidget {
  // We need to make sure the key is properly passed when creating the Skeleton widget
  const Skeleton({super.key});

  // Use a static instance to access the state
  static final GlobalKey<_SkeletonState> navigatorKey =
      GlobalKey<_SkeletonState>();

  // Modified method to only use Skeleton navigation (no fallbacks)
  static void navigateToPrayers(BuildContext context) {
    print("Attempting to navigate to prayers tab");
    final state = navigatorKey.currentState;
    if (state != null) {
      state.navigateToTab(2); // 2 is the index for prayers
      print("Navigation state found, navigating to tab 2");
    } else {
      print("Navigation state is null - no navigation occurred");
      // Do not use direct navigation as fallback
    }
  }

  @override
  _SkeletonState createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  var widgetjsonData;

  // Add a method to navigate to a specific page
  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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
    return WillPopScope(
      onWillPop: () async {
        // If we're not on the home tab, navigate to it
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false; // Prevent app from closing
        }
        // Show confirmation dialog when trying to exit app
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأكيد الخروج'),
                content: const Text('هل تريد الخروج من التطبيق؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('لا'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('نعم'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Directionality(
        textDirection: TextDirection.rtl, // set app to RTL
        child: Scaffold(
          appBar: const CustomAppBar(
              title: 'ذكر', showAddButton: false, showBackButton: false),
          body: _pages[
              _currentIndex], // Directly use the page without extra wrappers
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
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: 'الرئيسية'),
              BottomNavigationBarItem(
                  icon: Icon(FlutterIslamicIcons.solidQuran2), label: 'القرآن'),
              BottomNavigationBarItem(
                  icon: Icon(FlutterIslamicIcons.solidPrayer), label: 'الصلاة'),
              BottomNavigationBarItem(
                  icon: Icon(FlutterIslamicIcons.solidCommunity),
                  label: 'المجتمع'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'الحساب'),
            ],
          ),
        ),
      ),
    );
  }
}
