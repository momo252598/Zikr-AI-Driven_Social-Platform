import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home/home.dart';
import 'package:software_graduation_project/screens/quran/quran_sura_page.dart';
import 'screens/prayers/prayers.dart';
import 'screens/profile/profile.dart';
import 'screens/community/community.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:software_graduation_project/screens/quran/quran_web/responsive_quran_layout.dart';

import 'package:software_graduation_project/components/quran/web_verse.dart'; // For accessing showWebVersePopup
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/services/quran_service.dart';
import 'package:software_graduation_project/services/unread_messages_service.dart';
import 'package:software_graduation_project/services/auth_service.dart'; // Add this import
import 'package:software_graduation_project/screens/admin/sheikh_approve.dart'; // Add this import

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

  // Method to navigate to quran tab with optional initial page
  static void navigateToQuran(BuildContext context, {int initialPage = 1}) {
    print("Attempting to navigate to quran tab with page: $initialPage");
    final state = navigatorKey.currentState;
    if (state != null) {
      // First make sure we have the right page number before navigation
      state.navigateToQuranWithPage(initialPage);

      // Update the last read page in QuranService (move this after navigation)
      if (initialPage > 1) {
        final quranService = QuranService();
        // Update in the background, navigation is already done
        quranService.updateLastReadPage(initialPage).then((_) {
          print("Last read page updated to: $initialPage");
        }).catchError((error) {
          print("Error updating last read page: $error");
        });
      }

      print(
          "Navigation state found, navigated to quran tab with page: $initialPage");
    } else {
      print("Navigation state is null - no navigation occurred");
    }
  }

  @override
  _SkeletonState createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  var widgetjsonData;
  // Store the last quran page number to pass to ResponsiveQuranLayout
  int _quranPageNumber = 1;
  // Create QuranService instance
  final QuranService _quranService = QuranService();
  // Add a flag for admin user
  bool _isAdminUser = false;
  // Add a method to navigate to a specific page
  void navigateToTab(int index) {
    if (_currentIndex != index) {
      // Set current index first
      setState(() {
        _currentIndex = index;
      });

      // Then, only fetch the latest page if we're navigating to the Quran tab
      // AND not coming from a direct page navigation (which would set _quranPageNumber directly)
      if (index == 1 && kIsWeb) {
        _loadLastReadPage();
      }
    }
  }

  // Track when the page was last manually set
  DateTime? _lastManualPageUpdateTime;

  // Load the last read page from the QuranService
  Future<void> _loadLastReadPage() async {
    try {
      // Don't fetch new page if we just manually set it within the last second
      // This prevents API calls from overriding a manually set page number
      if (_lastManualPageUpdateTime != null &&
          DateTime.now().difference(_lastManualPageUpdateTime!) <
              Duration(seconds: 1)) {
        print(
            "Skipping page load, recently manually set to: $_quranPageNumber");
        return;
      }

      final lastPage = await _quranService.getLastReadPage();
      setState(() {
        _quranPageNumber = lastPage;
        print("Loaded last read page from API: $_quranPageNumber");
      });
    } catch (e) {
      print("Error loading last read page: $e");
    }
  } // Method to navigate to quran tab with a specific page

  void navigateToQuranWithPage(int pageNumber) {
    print("Starting navigation to page: $pageNumber");

    // First set the page number in a separate setState call
    setState(() {
      _quranPageNumber = pageNumber;
      _lastManualPageUpdateTime =
          DateTime.now(); // Record when page was manually set
    });

    // Then in a separate setState, update the current index
    // This ensures the page number is already set when the tab changes
    setState(() {
      _currentIndex = 1; // 1 is the index for quran
    });

    print(
        "Navigated to Quran with specific page: $pageNumber (current value: $_quranPageNumber)");
  }

  // Variables to track verse to highlight after navigation
  int? _pendingSurahNumber;
  int? _pendingVerseNumber;
  int? _pendingPageNumber;
  bool _hasPendingHighlight = false;

  // Method to show web verse popup after navigation
  void showWebVerseAfterNavigation(
      int surahNumber, int verseNumber, int pageNumber) {
    if (!kIsWeb) return;

    // Clear any existing highlight first to prevent stacking
    setState(() {
      // Reset previous highlights first
      _hasPendingHighlight = false;
      _pendingSurahNumber = null;
      _pendingVerseNumber = null;
      _pendingPageNumber = null;
    });

    // Wait a moment to ensure previous state is cleared
    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Set new highlight parameters
      setState(() {
        _pendingSurahNumber = surahNumber;
        _pendingVerseNumber = verseNumber;
        _pendingPageNumber = pageNumber;
        _hasPendingHighlight = true;

        // Make sure we have the correct page number
        _quranPageNumber = pageNumber;
        _lastManualPageUpdateTime = DateTime.now();
      });

      // Clear the highlight flag after a delay to prevent persistent highlighting
      Future.delayed(Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _hasPendingHighlight = false;
        });
      });
    });
  }

  // Schedule a check to find and highlight verse
  void _scheduleVerseHighlightCheck() {
    // Use a delayed future to give time for the layout to be built
    Future.delayed(Duration(milliseconds: 500), () {
      if (!_hasPendingHighlight) return;

      print(
          "Attempting to show verse popup for surah: $_pendingSurahNumber, verse: $_pendingVerseNumber");

      // Use a simpler approach - find the first QuranViewPage in the widget tree
      // and then rely on its built-in mechanisms to find and highlight the verse
      final context = this.context;

      // Look for a QuranViewPage in the widget tree
      bool foundQuranPage = false;

      void findQuranPage(Element element) {
        if (element.widget.toString().contains('QuranViewPage')) {
          print("Found QuranViewPage widget");
          foundQuranPage = true;

          // Simulate a tap on the verse
          // This is a bit of a hack but it's the most reliable way to trigger the popup
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              // Try to find a verse element with the right surah and verse
              // and simulate tapping on it
              void findAndTapVerseElement(Element element) {
                // Look for RichText widgets which contain our verse text
                if (element.widget.toString().contains('RichText')) {
                  final widgetDesc = element.widget.toString();
                  if (widgetDesc.contains('"surah":${_pendingSurahNumber}') ||
                      widgetDesc.contains(
                          '${_pendingSurahNumber}:${_pendingVerseNumber}')) {
                    print("Found verse element, simulating tap");

                    // Get the center position of this element
                    final renderBox = element.renderObject as RenderBox?;
                    if (renderBox != null) {
                      final position = renderBox.localToGlobal(Offset.zero);
                      final size = renderBox.size;

                      // Calculate center position
                      final centerPos = Offset(position.dx + size.width / 2,
                          position.dy + size.height / 2);

                      // Manually show the web verse popup
                      // Import the showWebVersePopup function at the top of the file
                      showWebVersePopup(
                          context,
                          _pendingPageNumber!,
                          _pendingSurahNumber!,
                          _pendingVerseNumber!,
                          centerPos);

                      // Clear pending highlight
                      _hasPendingHighlight = false;
                    }
                  }
                }

                // Continue the search
                element.visitChildren(findAndTapVerseElement);
              }

              // Start the search
              (context as Element).visitChildren(findAndTapVerseElement);
            } catch (e) {
              print("Error while trying to show verse popup: $e");
            }
          });
        }

        // If we haven't found it yet, continue searching
        if (!foundQuranPage) {
          element.visitChildren(findQuranPage);
        }
      }

      // Start the search from the context
      (context as Element).visitChildren(findQuranPage);

      // If we couldn't find it on the first try, try again after a delay (up to 5 times)
      if (!foundQuranPage) {
        _retryCount++;
        if (_retryCount < 5) {
          print("QuranViewPage not found, retrying... ($_retryCount/5)");
          _scheduleVerseHighlightCheck();
        } else {
          // Give up after 5 retries
          print("Failed to find QuranViewPage after 5 retries");
          _hasPendingHighlight = false;
          _retryCount = 0;
        }
      }
    });
  }

  int _retryCount = 0;

  Future<void> loadJsonAsset() async {
    final String jsonString =
        await rootBundle.loadString('assets/utils/surahs.json');
    var data = jsonDecode(jsonString);
    setState(() {
      widgetjsonData = data;
    });
  }

  @override
  void initState() {
    super.initState();
    loadJsonAsset(); // initialize JSON on startup
    if (kIsWeb) {
      _loadLastReadPage(); // load the last read page on startup
    }
    _checkIfAdmin(); // Check if current user is admin
  }

  // Method to check if current user is admin
  Future<void> _checkIfAdmin() async {
    final AuthService authService = AuthService();
    final username = await authService.getCurrentUsername();

    if (username == 'admin') {
      setState(() {
        _isAdminUser = true;
      });
      print('Admin user detected, showing admin layout');
    }
  }

  int _currentIndex = 0;
  List<Widget> get _pages {
    // For admin users, return only the needed pages
    if (_isAdminUser) {
      return [
        const SheikhApprovePage(), // First tab for admin is sheikh approval
        const ProfilePage(), // Second tab is profile
      ];
    }

    // For regular users, return all normal pages
    return [
      const HomePage(),
      widgetjsonData != null
          ? kIsWeb
              ? _buildQuranLayoutWithLatestPageNumber()
              : QuranPage2(suraJsonData: widgetjsonData)
          : const Center(child: CircularProgressIndicator()),
      const PrayersPage(),
      const CommunityPage(),
      const ProfilePage(),
    ];
  }

  // Helper method to ensure we're using the most up-to-date page number
  Widget _buildQuranLayoutWithLatestPageNumber() {
    return ResponsiveQuranLayout(
      key: ValueKey<int>(_quranPageNumber),
      suraJsonData: widgetjsonData,
      initialPage: _quranPageNumber,
      shouldHighlightText: _hasPendingHighlight, // Pass highlight flag
      highlightVerse: _hasPendingHighlight
          ? "${_pendingSurahNumber}:${_pendingVerseNumber}"
          : "", // Pass highlight verse
    );
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
        child: kIsWeb
            ? _buildWebLayout(context) // Web layout with vertical navbar
            : _buildMobileLayout(context), // Mobile layout with bottom navbar
      ),
    );
  }

  // Web layout with vertical navigation
  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
          title: 'ذكر', showAddButton: false, showBackButton: false),
      body: Row(
        children: [
          // Left vertical navigation bar with improved styling
          NavigationRail(
            backgroundColor: AppStyles.bgColor,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (_currentIndex != index) {
                navigateToTab(index);
              }
            },
            labelType: NavigationRailLabelType.all,
            useIndicator: true,
            indicatorColor: AppStyles.lightPurple.withOpacity(0.2),
            elevation: 4,
            minWidth: 85,
            minExtendedWidth: 100,
            destinations: _isAdminUser
                ? _buildAdminNavigationDestinations() // Admin navigation items
                : _buildRegularNavigationDestinations(), // Regular navigation items
            selectedIconTheme:
                IconThemeData(color: AppStyles.lightPurple, size: 28),
            unselectedIconTheme: IconThemeData(color: AppStyles.grey, size: 24),
            selectedLabelTextStyle: TextStyle(
                color: AppStyles.lightPurple, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: TextStyle(color: AppStyles.grey),
          ),
          // Divider for visual separation
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppStyles.greyShaded300,
          ),
          // Content area
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
    );
  }

  // Mobile layout with bottom navigation
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
          title: 'ذكر', showAddButton: false, showBackButton: false),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppStyles.bgColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppStyles.lightPurple,
        unselectedItemColor: AppStyles.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          navigateToTab(index);
        },
        items: _isAdminUser
            ? _buildAdminNavigationItems() // Admin navigation items
            : _buildRegularNavigationItems(), // Regular navigation items
      ),
    );
  }

  // Helper method for admin navigation items (for BottomNavigationBar)
  List<BottomNavigationBarItem> _buildAdminNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.verified_user),
        label: 'توثيق',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'الحساب',
      ),
    ];
  }

  // Helper method for regular navigation items (for BottomNavigationBar)
  List<BottomNavigationBarItem> _buildRegularNavigationItems() {
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
      const BottomNavigationBarItem(
          icon: Icon(FlutterIslamicIcons.solidQuran2), label: 'القرآن'),
      const BottomNavigationBarItem(
          icon: Icon(FlutterIslamicIcons.solidPrayer), label: 'الصلاة'),
      BottomNavigationBarItem(
          icon: Builder(builder: (context) {
            return StreamBuilder<int>(
              stream: UnreadMessagesService().unreadCountStream,
              initialData: UnreadMessagesService().unreadCount,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(FlutterIslamicIcons.solidCommunity),
                );
              },
            );
          }),
          label: 'المجتمع'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
    ];
  }

  // Helper method for admin navigation destinations (for NavigationRail)
  List<NavigationRailDestination> _buildAdminNavigationDestinations() {
    return const [
      NavigationRailDestination(
        padding: EdgeInsets.symmetric(vertical: 12),
        icon: Icon(Icons.verified_user),
        label: Text('توثيق'),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.symmetric(vertical: 12),
        icon: Icon(Icons.person),
        label: Text('الحساب'),
      ),
    ];
  }

  // Helper method for regular navigation destinations (for NavigationRail)
  List<NavigationRailDestination> _buildRegularNavigationDestinations() {
    return [
      const NavigationRailDestination(
        padding: EdgeInsets.symmetric(vertical: 12),
        icon: Icon(Icons.home),
        label: Text('الرئيسية'),
      ),
      const NavigationRailDestination(
        padding: EdgeInsets.symmetric(vertical: 12),
        icon: Icon(FlutterIslamicIcons.solidQuran2),
        label: Text('القرآن'),
      ),
      const NavigationRailDestination(
        padding: EdgeInsets.symmetric(vertical: 12),
        icon: Icon(FlutterIslamicIcons.solidPrayer),
        label: Text('الصلاة'),
      ),
      NavigationRailDestination(
        padding: const EdgeInsets.symmetric(vertical: 12),
        icon: Builder(builder: (context) {
          return StreamBuilder<int>(
            stream: UnreadMessagesService().unreadCountStream,
            initialData: UnreadMessagesService().unreadCount,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount.toString()),
                backgroundColor: Colors.redAccent,
                child: Icon(FlutterIslamicIcons.solidCommunity),
              );
            },
          );
        }),
        label: const Text('المجتمع'),
      ),
      const NavigationRailDestination(
        padding: EdgeInsets.symmetric(vertical: 12),
        icon: Icon(Icons.person),
        label: Text('الحساب'),
      ),
    ];
  }
}
