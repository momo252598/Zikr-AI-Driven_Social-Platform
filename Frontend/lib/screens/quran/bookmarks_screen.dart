import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/components/shared/loading_indicator.dart';
import 'package:software_graduation_project/models/quran_models.dart';
import 'package:software_graduation_project/screens/quran/quran_page.dart';
import 'package:software_graduation_project/services/quran_service.dart';
import 'package:software_graduation_project/skeleton.dart'; // Import the Skeleton
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;

class BookmarksScreen extends StatefulWidget {
  final dynamic jsonData;
  final bool isWeb;

  const BookmarksScreen({
    Key? key,
    required this.jsonData,
    this.isWeb = false,
  }) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final QuranService _quranService = QuranService();
  bool _isLoading = true;
  List<QuranBookmark> _bookmarks = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  // Load bookmarks from the API
  Future<void> _loadBookmarks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final bookmarks = await _quranService.getBookmarks();

      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Check if this is an authentication error
          if (e.toString().contains('Authentication failed') ||
              e.toString().contains('Unauthorized')) {
            _errorMessage = 'يرجى تسجيل الدخول لعرض المفضلة';
            // You might want to navigate to login screen here
            // _navigateToLogin();
          } else {
            _errorMessage = 'حدث خطأ في تحميل المفضلة. الرجاء المحاولة لاحقا.';
          }
        });
      }
    }
  }

  // Optional: Add a method to navigate to login
  /*
  void _navigateToLogin() {
    // Add a slight delay to allow the state to update first
    Future.delayed(Duration(milliseconds: 100), () {
      Navigator.of(context).pushReplacementNamed('/login');
      // Or use your app's navigation method to the login screen
    });
  }
  */
  // Navigate to the bookmarked verse
  void _navigateToVerse(QuranBookmark bookmark) {
    if (widget.isWeb) {
      Navigator.of(context).pop();

      // For web, use a small delay to ensure navigation completes first
      // before triggering the verse highlighting
      Future.delayed(Duration(milliseconds: 300), () {
        // Navigate to the Quran page
        Skeleton.navigateToQuran(context, initialPage: bookmark.page);

        // Wait a bit longer before showing the verse - this prevents the popup from
        // being triggered during navigation transitions
        Future.delayed(Duration(milliseconds: 500), () {
          final skeletonState = Skeleton.navigatorKey.currentState;
          if (skeletonState != null) {
            skeletonState.showWebVerseAfterNavigation(
                bookmark.surah, bookmark.verse, bookmark.page);
          }
        });
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuranViewPage(
            pageNumber: bookmark.page,
            jsonData: widget.jsonData,
            shouldHighlightText: true,
            highlightVerse: "${bookmark.surah}:${bookmark.verse}",
            isWeb: false,
          ),
        ),
      );
    }
  }

  // Delete a bookmark with confirmation
  Future<void> _deleteBookmark(QuranBookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف المفضلة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Taha',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل تريد حقا حذف هذه الآية من المفضلة؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Taha',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Taha',
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Taha',
                color: AppStyles.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _quranService.removeBookmark(bookmark.surah, bookmark.verse);

        // Reload bookmarks after deletion
        _loadBookmarks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حذف الآية من المفضلة بنجاح'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Check if this is an authentication error
            if (e.toString().contains('Authentication failed') ||
                e.toString().contains('Unauthorized')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('يرجى تسجيل الدخول أولاً'),
                  backgroundColor: AppStyles.red,
                  duration: const Duration(seconds: 2),
                ),
              );
              // You might want to navigate to login screen here
              // _navigateToLogin();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('حدث خطأ في حذف الآية من المفضلة'),
                  backgroundColor: AppStyles.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'القرآن الكريم - المفضلة',
        showBackButton: true,
        showAddButton: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if we're on a wide screen (web)
          final isWideScreen = constraints.maxWidth > 800;

          // Store the isWideScreen value for use in text styling
          _isWideScreen = isWideScreen;

          Widget content = _buildBookmarkContent();

          // If we're on a wide screen, constrain the width
          if (isWideScreen) {
            content = Center(
              child: Container(
                width: 800,
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }

  // Add this property to track if we're on web/wide screen
  bool _isWideScreen = false;

  // Get appropriate font size based on platform
  double _getFontSize(double mobileSize) {
    if (_isWideScreen) {
      // Use a smaller, fixed font size on web, but not too small
      return mobileSize / 1.2; // Changed from 1.5 to 1.2 for larger text
    }
    return mobileSize.sp; // Use screenutil scaling on mobile
  }

  Widget _buildBookmarkContent() {
    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: _isLoading
          ? const LoadingIndicator()
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppStyles.red,
                        fontFamily: 'Taha',
                        fontSize: _getFontSize(16),
                      ),
                    ),
                  ),
                )
              : _bookmarks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'لا توجد آيات محفوظة في المفضلة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Taha',
                            fontSize: _getFontSize(16),
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _bookmarks.length,
                      padding: const EdgeInsets.all(16.0),
                      itemBuilder: (context, index) {
                        final bookmark = _bookmarks[index];
                        return _buildBookmarkCard(bookmark);
                      },
                    ),
    );
  }

  Widget _buildBookmarkCard(QuranBookmark bookmark) {
    // Format the timestamp
    final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm').format(bookmark.timestamp);

    // Get verse text and surah name
    final verseText = getVerse(bookmark.surah, bookmark.verse);
    final surahName = getSurahNameArabic(bookmark.surah);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVerse(bookmark),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end, // Align content to the right
            children: [
              // Surah and verse info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete icon now on the left side
                  IconButton(
                    onPressed: () => _deleteBookmark(bookmark),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppStyles.red,
                      size: _getFontSize(20),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  ),

                  // Text on the right side
                  Text(
                    'سورة $surahName - آية ${bookmark.verse}',
                    style: TextStyle(
                      fontFamily: 'Taha',
                      fontSize: _getFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: AppStyles.darkPurple,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),

              const Divider(),

              // Verse text (already right-aligned)
              Text(
                verseText,
                textAlign: TextAlign.right,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontFamily:
                      'QCF_P${bookmark.page.toString().padLeft(3, "0")}',
                  fontSize: _getFontSize(18),
                  height: 2.0,
                  color: AppStyles.black,
                ),
              ),

              const SizedBox(height: 8),

              // Timestamp - already at the end which is correct for RTL
              Text(
                'تمت الإضافة: $formattedDate',
                style: TextStyle(
                  fontFamily: 'Taha',
                  fontSize: _getFontSize(12),
                  color: Colors.grey,
                ),
                textAlign: TextAlign.right,
              ),

              // Notes if available
              if (bookmark.notes != null && bookmark.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    textDirection: ui.TextDirection.rtl, // Ensure right-to-left
                    children: [
                      Icon(
                        Icons.note,
                        size: _getFontSize(16),
                        color: AppStyles.txtFieldColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.notes!,
                          style: TextStyle(
                            fontFamily: 'Taha',
                            fontSize: _getFontSize(14),
                            color: AppStyles.txtFieldColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
