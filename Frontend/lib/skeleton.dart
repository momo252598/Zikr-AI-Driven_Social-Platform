import 'package:flutter/material.dart';
import 'screens/home/home.dart';
import 'screens/quran/quran.dart';
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
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    QuranPage(),
    ChatPage(),
    ProfilePage(),
  ];

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
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
