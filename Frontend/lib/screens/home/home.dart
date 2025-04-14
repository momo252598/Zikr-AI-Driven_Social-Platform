import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/prayers/prayers.dart'; // Import prayer functionality
import 'package:software_graduation_project/services/auth_service.dart'; // Import auth service
import 'package:software_graduation_project/base/res/media.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Prayer>> futurePrayers;
  late Future<String?> futureUserFirstName;
  late Future<Map<String, dynamic>> futureRandomZikr;

  @override
  void initState() {
    super.initState();
    // Get prayer times
    futurePrayers = getPrayerTimes();

    // Get user's first name
    final authService = AuthService();
    futureUserFirstName = _getUserFirstName(authService);

    // Get random zikr
    futureRandomZikr = _getRandomZikr();
  }

  // Get user's first name
  Future<String?> _getUserFirstName(AuthService authService) async {
    try {
      final user = await authService.getCurrentUser();
      if (user?.firstName == null || user!.firstName.isEmpty) {
        return '';
      }

      // Direct return of firstName without any encoding manipulation
      return user.firstName;
    } catch (e) {
      print('Error fetching user name: $e');
      return '';
    }
  }

  // Determine if it's morning or evening
  bool _isMorningTime() {
    final now = DateTime.now();
    // Consider 4 AM to 5 PM as morning, otherwise evening
    return now.hour >= 4 && now.hour < 17;
  }

  // Load the appropriate JSON file based on time
  Future<List<Map<String, dynamic>>> _loadAzkarFile() async {
    final String filePath = _isMorningTime()
        ? 'assets/utils/azkar_sabah.json'
        : 'assets/utils/azkar_massa.json';

    final jsonString = await rootBundle.loadString(filePath);
    final data = json.decode(jsonString);
    return List<Map<String, dynamic>>.from(data['content']);
  }

  // Get a random zikr from the appropriate JSON file
  Future<Map<String, dynamic>> _getRandomZikr() async {
    try {
      final azkarList = await _loadAzkarFile();
      final random = Random();
      return azkarList[random.nextInt(azkarList.length)];
    } catch (e) {
      // Default zikr if loading fails
      return {
        'zekr': 'سبحان الله وبحمده سبحان الله العظيم',
        'repeat': 3,
        'bless': ''
      };
    }
  }

  // Helper method to determine screen size category
  ScreenSize _getScreenSize(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenSize.mobile;
    if (width < 1200) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  // Next Prayer Widget
  Widget _nextPrayerWidget(Prayer nextPrayer, Duration timeLeft) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppStyles.lightPurple, AppStyles.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppStyles.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyles.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "الصلاة القادمة",
                        style: TextStyle(
                          color: AppStyles.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppStyles.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${timeLeft.inHours.toString().padLeft(2, '0')}:${(timeLeft.inMinutes % 60).toString().padLeft(2, '0')} متبقي",
                          style: TextStyle(
                            color: AppStyles.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _getPrayerIcon(nextPrayer.name),
                        color: AppStyles.white,
                        size: 36,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextPrayer.name,
                            style: TextStyle(
                              color: AppStyles.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "الوقت: ${TimeOfDay.fromDateTime(nextPrayer.time.toLocal()).format(context)}",
                            style: TextStyle(
                              color: AppStyles.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String name) {
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

  // New widget to display zikr
  Widget _buildZikrWidget(Map<String, dynamic> zikr) {
    final String zikrText = zikr['zekr'] ?? '';
    final int repeat = zikr['repeat'] ?? 1;
    final String bless = zikr['bless'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.lightPurple.withOpacity(0.4),
            AppStyles.purple.withOpacity(0.4)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppStyles.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            zikrText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppStyles.darkPurple,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppStyles.purple,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "التكرار: $repeat",
              style: TextStyle(
                color: AppStyles.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (bless.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppStyles.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                bless,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppStyles.darkPurple,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = _getScreenSize(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  screenSize == ScreenSize.desktop ? 1200 : double.infinity,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize == ScreenSize.mobile ? 0 : 16,
                ),
                child: screenSize == ScreenSize.mobile
                    ? _buildMobileLayout(context, screenWidth)
                    : _buildWebLayout(context, screenWidth, screenSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome widget
        _buildWelcomeWidget(context),

        // Next Prayer Widget
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5, left: 20),
          child: Text(
            "الصلاة القادمة",
            style: TextStyle(
              color: AppStyles.purple,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildPrayerWidget(),

        // Shortcuts section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "اختصارات سريعة",
                style: TextStyle(
                  color: AppStyles.purple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFeatureCard(context, Icons.menu_book_rounded,
                      "القرآن الكريم", AppStyles.lightPurple, screenWidth),
                  _buildFeatureCard(context, Icons.volunteer_activism,
                      "الأذكار", AppStyles.purple, screenWidth),
                  _buildFeatureCard(context, Icons.compass_calibration,
                      "القبلة", AppStyles.darkPurple, screenWidth),
                ],
              ),

              // Zikr section
              const SizedBox(height: 20),
              Text(
                _isMorningTime() ? "ذكر الصباح" : "ذكر المساء",
                style: TextStyle(
                  color: AppStyles.purple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildZikrFutureWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(
      BuildContext context, double screenWidth, ScreenSize screenSize) {
    return Column(
      children: [
        // Welcome widget
        _buildWelcomeWidget(context),
        const SizedBox(height: 20),

        // Two-column layout for wider screens
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Prayer section
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 10),
                    child: Text(
                      "الصلاة القادمة",
                      style: TextStyle(
                        color: AppStyles.purple,
                        fontSize: screenSize == ScreenSize.desktop ? 22 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPrayerWidget(),

                  // Shortcuts section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "اختصارات سريعة",
                          style: TextStyle(
                            color: AppStyles.purple,
                            fontSize:
                                screenSize == ScreenSize.desktop ? 22 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          alignment: WrapAlignment.start,
                          children: [
                            _buildFeatureCard(
                                context,
                                Icons.menu_book_rounded,
                                "القرآن الكريم",
                                AppStyles.lightPurple,
                                screenWidth,
                                isWeb: true),
                            _buildFeatureCard(context, Icons.volunteer_activism,
                                "الأذكار", AppStyles.purple, screenWidth,
                                isWeb: true),
                            _buildFeatureCard(
                                context,
                                Icons.compass_calibration,
                                "القبلة",
                                AppStyles.darkPurple,
                                screenWidth,
                                isWeb: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right column - Zikr section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isMorningTime() ? "ذكر الصباح" : "ذكر المساء",
                      style: TextStyle(
                        color: AppStyles.purple,
                        fontSize: screenSize == ScreenSize.desktop ? 22 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildZikrFutureWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Extracted widgets for reuse
  Widget _buildWelcomeWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.darkPurple,
            AppStyles.lightPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: AssetImage(AppMedia.pattern3),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppStyles.appBarGrey,
            BlendMode.dstATop,
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppStyles.darkPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppStyles.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: FutureBuilder<String?>(
                future: futureUserFirstName,
                builder: (context, snapshot) {
                  final firstName = snapshot.data ?? '';
                  return Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName.isNotEmpty
                                ? "مرحبا $firstName"
                                : "مرحبا بك",
                            style: TextStyle(
                              color: AppStyles.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1.0, 1.0),
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerWidget() {
    return FutureBuilder<List<Prayer>>(
      future: futurePrayers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("حدث خطأ في تحميل مواقيت الصلاة"),
            ),
          );
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

        if (nextPrayer == null || closestDiff == null) {
          return const Center(child: Text("لا توجد صلوات قادمة اليوم"));
        }

        return _nextPrayerWidget(nextPrayer, closestDiff);
      },
    );
  }

  Widget _buildZikrFutureWidget() {
    return FutureBuilder<Map<String, dynamic>>(
      future: futureRandomZikr,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("حدث خطأ في تحميل الأذكار"),
            ),
          );
        }

        return _buildZikrWidget(snapshot.data!);
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title,
      Color color, double screenWidth,
      {bool isWeb = false}) {
    final cardWidth = isWeb
        ? 150.0 // Fixed width for web
        : (screenWidth - 60) / 3; // Dynamic width for mobile

    return Container(
      width: cardWidth,
      padding: EdgeInsets.symmetric(
        vertical: isWeb ? 20 : 15,
        horizontal: isWeb ? 15 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: isWeb ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isWeb ? 36 : 32),
          SizedBox(height: isWeb ? 12 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isWeb ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Enum for screen size categories
enum ScreenSize { mobile, tablet, desktop }
