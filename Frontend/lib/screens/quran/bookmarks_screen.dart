import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/components/shared/loading_indicator.dart';
import 'package:software_graduation_project/models/quran_models.dart';
import 'package:software_graduation_project/screens/quran/quran_page.dart';
import 'package:software_graduation_project/services/quran_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;

class BookmarksScreen extends StatefulWidget {
  final dynamic jsonData;

  const BookmarksScreen({
    Key? key,
    required this.jsonData,
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
          _errorMessage = 'حدث خطأ في تحميل المفضلة. الرجاء المحاولة لاحقا.';
        });
      }
    }
  }

  // Navigate to the bookmarked verse
  void _navigateToVerse(QuranBookmark bookmark) {
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
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('حدث خطأ في حذف الآية من المفضلة'),
              backgroundColor: AppStyles.red,
              duration: const Duration(seconds: 2),
            ),
          );
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
      body: RefreshIndicator(
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
                          fontSize: 16.sp,
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
                              fontSize: 16.sp,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Surah and verse info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سورة $surahName - آية ${bookmark.verse}',
                    style: TextStyle(
                      fontFamily: 'Taha',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.darkPurple,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteBookmark(bookmark),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppStyles.red,
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  ),
                ],
              ),

              const Divider(),

              // Verse text
              Text(
                verseText,
                textAlign: TextAlign.right,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontFamily:
                      'QCF_P${bookmark.page.toString().padLeft(3, "0")}',
                  fontSize: 18.sp,
                  height: 2.0,
                  color: AppStyles.black,
                ),
              ),

              const SizedBox(height: 8),

              // Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'تمت الإضافة: $formattedDate',
                    style: TextStyle(
                      fontFamily: 'Taha',
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // Notes if available
              if (bookmark.notes != null && bookmark.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16.sp,
                        color: AppStyles.txtFieldColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.notes!,
                          style: TextStyle(
                            fontFamily: 'Taha',
                            fontSize: 14.sp,
                            color: AppStyles.txtFieldColor,
                            fontStyle: FontStyle.italic,
                          ),
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
