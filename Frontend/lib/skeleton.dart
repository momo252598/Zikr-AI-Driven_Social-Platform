import 'package:flutter/material.dart';
import 'screens/home/home.dart';
import 'screens/quran/quran.dart';
import 'screens/chat/chat.dart';
import 'screens/profile/profile.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 78, 41, 153),
                Color.fromARGB(255, 152, 78, 248)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/islamic_pattern.png'), // add a suitable Islamic pattern image in assets
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(96, 255, 255, 255),
                BlendMode.dstATop,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Al-Quran",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 152, 78, 248),
        unselectedItemColor: Colors.grey, // Updated color for better visibility
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
