import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({Key? key}) : super(key: key);

  @override
  _AzkarScreenState createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, List<Map<String, dynamic>>>> _azkarData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _azkarData = _loadAllAzkarData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load both morning and evening azkar data
  Future<Map<String, List<Map<String, dynamic>>>> _loadAllAzkarData() async {
    try {
      // Load morning azkar
      final sabahJsonString =
          await rootBundle.loadString('assets/utils/azkar_sabah.json');
      final sabahData = json.decode(sabahJsonString);
      final sabahAzkar = List<Map<String, dynamic>>.from(sabahData['content']);

      // Load evening azkar
      final massaJsonString =
          await rootBundle.loadString('assets/utils/azkar_massa.json');
      final massaData = json.decode(massaJsonString);
      final massaAzkar = List<Map<String, dynamic>>.from(massaData['content']);

      return {
        'sabah': sabahAzkar,
        'massa': massaAzkar,
      };
    } catch (e) {
      print('Error loading azkar data: $e');
      return {
        'sabah': [],
        'massa': [],
      };
    }
  }

  // Build individual zikr card similar to home screen
  Widget _buildZikrCard(Map<String, dynamic> zikr, int index) {
    final String zikrText = zikr['zekr'] ?? '';
    final int repeat = zikr['repeat'] ?? 1;
    final String bless = zikr['bless'] ?? '';

    // Check if we're on web for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800; // Consider as web if width > 800px

    // Calculate card width based on platform
    final cardWidth = isWeb
        ? (screenWidth > 1200 ? 800.0 : screenWidth * 0.7)
        : // Web: max 800px or 70% of screen
        double.infinity; // Mobile: full width

    return Center(
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zikr number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppStyles.darkPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppStyles.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Zikr text
            Text(
              zikrText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppStyles.darkPurple,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 15),

            // Repeat count
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppStyles.purple,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "التكرار: $repeat",
                  style: TextStyle(
                    color: AppStyles.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Blessing text if available
            if (bless.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppStyles.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppStyles.lightPurple.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الفضل:',
                      style: TextStyle(
                        color: AppStyles.darkPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      bless,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppStyles.darkPurple,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build azkar list for a specific type
  Widget _buildAzkarList(List<Map<String, dynamic>> azkarList) {
    if (azkarList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'لا توجد أذكار متاحة',
            style: TextStyle(
              color: AppStyles.purple,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: azkarList.length,
      itemBuilder: (context, index) {
        return _buildZikrCard(azkarList[index], index);
      },
    );
  }

  // Build custom app bar similar to home screen (without tabs)
  Widget _buildCustomAppBar() {
    return Container(
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.darkPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppStyles.white,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'الأذكار',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppStyles.white,
                    fontSize: 24,
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
              ),
              const SizedBox(width: 44), // Balance the back button width
            ],
          ),
        ),
      ),
    );
  }

  // Build styled tab buttons below the app bar
  Widget _buildTabButtons() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.lightPurple.withOpacity(0.1),
            AppStyles.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppStyles.purple.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppStyles.lightPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final isSelected = _tabController.index == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppStyles.darkPurple,
                                  AppStyles.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppStyles.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'أذكار المساء',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? AppStyles.white : AppStyles.purple,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final isSelected = _tabController.index == 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppStyles.darkPurple,
                                  AppStyles.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppStyles.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'أذكار الصباح',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? AppStyles.white : AppStyles.purple,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: Column(
        children: [
          _buildCustomAppBar(),
          _buildTabButtons(),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _azkarData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppStyles.purple,
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'حدث خطأ في تحميل الأذكار',
                        style: TextStyle(
                          color: AppStyles.purple,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                final azkarData = snapshot.data!;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAzkarList(azkarData['massa'] ?? []),
                    _buildAzkarList(azkarData['sabah'] ?? []),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
