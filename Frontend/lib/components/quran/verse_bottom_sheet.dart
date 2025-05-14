import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/utils/tafseer.dart';
import 'package:software_graduation_project/services/quran_service.dart'; // Import the new QuranService
import 'tafseer_bottom_sheet.dart';

// Static variable to remember last selected reciter across all bottom sheets
class ReciterManager {
  static String lastSelectedReciter = 'ar.husary';
}

// Static variable to remember last selected tafseer across all bottom sheets
class TafseerManager {
  static String lastSelectedTafseer = 'ar-tafsir-muyassar';
}

/// Shows a bottom sheet with verse details
void showVerseBottomSheet(
  BuildContext context,
  int pageNumber,
  int surahNumber,
  int verseNumber, {
  Function? onClose,
}) {
  // Create audio player outside the widget to control its lifecycle separately
  final audioPlayer = AudioPlayer();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Make background transparent
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
    ),
    builder: (context) {
      return Padding(
        // Wrap in padding to handle keyboard properly
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: VerseBottomSheetContent(
          pageNumber: pageNumber,
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          audioPlayer: audioPlayer, // Pass the audio player instance
        ),
      );
    },
  ).then((_) {
    // Ensure audio player is properly disposed when sheet is closed
    audioPlayer.stop().then((_) {
      audioPlayer.dispose();
      if (onClose != null) {
        onClose();
      }
    }).catchError((_) {
      // Ignore errors during cleanup
      audioPlayer.dispose();
      if (onClose != null) {
        onClose();
      }
    });
  });
}

class VerseBottomSheetContent extends StatefulWidget {
  final int pageNumber;
  final int surahNumber;
  final int verseNumber;
  final AudioPlayer audioPlayer;

  const VerseBottomSheetContent({
    Key? key,
    required this.pageNumber,
    required this.surahNumber,
    required this.verseNumber,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<VerseBottomSheetContent> createState() =>
      _VerseBottomSheetContentState();
}

class _VerseBottomSheetContentState extends State<VerseBottomSheetContent> {
  bool _isPlaying = false;
  bool _isLoading = false;
  late String _selectedReciter;
  bool _isOperationInProgress = false;
  late String _selectedTafseer; // Changed from initialization to late
  bool _isBookmarked = false; // New state to track bookmark status
  bool _isBookmarkLoading = false; // New state to track bookmark loading state
  
  // New state variables to track current verse
  late int _currentSurahNumber;
  late int _currentVerseNumber;

  // Map of reciter IDs to their Arabic names - added three new reciters
  final Map<String, String> _reciters = {
    'ar.husary': 'محمود خليل الحصري',
    'ar.abdurrahmaansudais': 'عبد الرحمن السديس',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد',
    'ar.alafasy': 'مشاري راشد العفاسي',
    'ar.muhammadjibreel': 'محمد جبريل',
    'ar.muhammadayyoub': 'محمد أيوب',
    'ar.minshawi': 'محمد صديق المنشاوي',
  };

  @override
  void initState() {
    super.initState();

    // Initialize with the last selected reciter from our static manager
    _selectedReciter = ReciterManager.lastSelectedReciter;

    // Initialize with the last selected tafseer from our static manager
    _selectedTafseer = TafseerManager.lastSelectedTafseer;
    
    // Initialize current verse tracking
    _currentSurahNumber = widget.surahNumber;
    _currentVerseNumber = widget.verseNumber;

    // Set up audio player listeners
    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
          });
        } else if (state.playing && _isLoading) {
          setState(() {
            _isLoading = false;
            _isPlaying = true;
            _isOperationInProgress = false; // Reset flag when playback starts
          });
        }
      }
    }, onError: (_) {
      // Handle stream errors gracefully
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
          _isOperationInProgress = false; // Also reset flag on error
        });
      }
    });

    // Check if verse is bookmarked
    _checkBookmarkStatus();
  }

  // Check if the current verse is bookmarked
  Future<void> _checkBookmarkStatus() async {
    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      final quranService = QuranService();
      final bookmarks = await quranService.getBookmarks();

      // Check if this verse is in the bookmarks
      final isBookmarked = bookmarks.any((bookmark) =>
          bookmark.surah == _currentSurahNumber &&
          bookmark.verse == _currentVerseNumber);

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isBookmarkLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحقق من المفضلة'),
            backgroundColor: AppStyles.red,
          ),
        );
      }
    }
  }

  // Toggle bookmark status
  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading) return; // Prevent multiple requests

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      final quranService = QuranService();

      if (_isBookmarked) {
        // Remove from bookmarks
        await quranService.removeBookmark(
            _currentSurahNumber, _currentVerseNumber);
      } else {
        // Add to bookmarks
        await quranService.addBookmark(
            _currentSurahNumber, _currentVerseNumber, widget.pageNumber);
      }

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
          _isBookmarkLoading = false;
        });

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked
                ? 'تمت إضافة الآية للمفضلة'
                : 'تمت إزالة الآية من المفضلة'),
            backgroundColor: _isBookmarked ? AppStyles.green : AppStyles.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحديث المفضلة'),
            backgroundColor: AppStyles.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Note: We don't dispose the audio player here, it's handled in the parent function
    super.dispose();
  }

  // Play or pause the verse audio
  void _togglePlayPause() {
    // Prevent multiple clicks
    if (_isOperationInProgress) return;

    setState(() {
      _isOperationInProgress = true;
    });

    // If currently playing, stop
    if (_isPlaying) {
      widget.audioPlayer.pause().then((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isOperationInProgress = false;
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _isOperationInProgress = false;
          });
        }
      });
      return;
    }

    // Show loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Get audio URL
    final audioUrl = getAudioURLByVerse(
        _currentSurahNumber, _currentVerseNumber, _selectedReciter);

    // Use a Future to avoid blocking the UI
    Future.microtask(() async {
      try {
        // Set URL with a timeout to prevent hanging
        await widget.audioPlayer.setUrl(audioUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException("Loading audio timed out");
          },
        );

        // Play with error handling
        await widget.audioPlayer.play();
      } catch (e) {
        // Handle errors
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isPlaying = false;
            _isOperationInProgress = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('عذراً، لم نتمكن من تشغيل الآية'),
              backgroundColor: AppStyles.red,
            ),
          );
        }
      } finally {
        // Ensure we reset the operation flag
        if (mounted) {
          setState(() {
            _isOperationInProgress = false;
          });
        }
      }
    });
  }

  // Show dialog to select reciter
  void _showReciterSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'اختر القارئ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Taha',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppStyles.darkPurple,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            // Add a fixed height constraint to make the list shorter
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.25,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _reciters.length,
              itemBuilder: (BuildContext context, int index) {
                String reciterId = _reciters.keys.elementAt(index);
                String reciterName = _reciters[reciterId]!;

                return ListTile(
                  title: Text(
                    reciterName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Taha',
                      fontSize: 16.sp,
                      // Make the selected reciter text bold and colored instead of using check mark
                      fontWeight: _selectedReciter == reciterId
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedReciter == reciterId
                          ? AppStyles.txtFieldColor
                          : AppStyles.black,
                    ),
                  ),
                  selected: _selectedReciter == reciterId,
                  onTap: () {
                    setState(() {
                      _selectedReciter = reciterId;

                      // Save the selection to our static manager
                      ReciterManager.lastSelectedReciter = reciterId;
                    });
                    Navigator.of(context).pop();
                  },
                  // Removed trailing check mark
                  // Add a subtle background for the selected item
                  tileColor: _selectedReciter == reciterId
                      ? AppStyles.lightPurple.withOpacity(0.2)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
                // Add less padding between items to make list more compact
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4);
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Taha',
                  fontSize: 16.sp,
                  color: AppStyles.grey,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  // Show dialog to select tafseer edition
  void _showTafseerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'اختر التفسير',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Taha',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppStyles.darkPurple,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.25,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TafseerService.tafseerEditions.length,
              itemBuilder: (BuildContext context, int index) {
                String tafseerSlug =
                    TafseerService.tafseerEditions.keys.elementAt(index);
                String tafseerName =
                    TafseerService.tafseerEditions[tafseerSlug]!;

                return ListTile(
                  title: Text(
                    tafseerName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Taha',
                      fontSize: 16.sp,
                      // Make the selected tafseer text bold and colored
                      fontWeight: _selectedTafseer == tafseerSlug
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTafseer == tafseerSlug
                          ? AppStyles.txtFieldColor
                          : AppStyles.black,
                    ),
                  ),
                  selected: _selectedTafseer == tafseerSlug,
                  onTap: () {
                    setState(() {
                      _selectedTafseer = tafseerSlug;

                      // Save the selection to our static manager
                      TafseerManager.lastSelectedTafseer = tafseerSlug;
                    });
                    Navigator.of(context).pop();
                  },
                  // Add a subtle background for the selected item
                  tileColor: _selectedTafseer == tafseerSlug
                      ? AppStyles.lightPurple.withOpacity(0.2)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Taha',
                  fontSize: 16.sp,
                  color: AppStyles.grey,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  // Show the tafseer directly without selecting edition
  void _showTafseerDirectly() {
    showTafseerBottomSheet(
      context,
      surahNumber: _currentSurahNumber,
      verseNumber: _currentVerseNumber,
      tafseerEdition: _selectedTafseer,
    );
  }

  // Method to navigate to previous verse
  void _goToPreviousVerse() {
    int newVerseNumber = _currentVerseNumber;
    int newSurahNumber = _currentSurahNumber;

    // If we're at first verse of the surah, go to previous surah's last verse
    if (newVerseNumber <= 1) {
      if (newSurahNumber > 1) {
        newSurahNumber--;
        newVerseNumber = getVerseCount(newSurahNumber);
      } else {
        // Already at first verse of first surah, do nothing
        return;
      }
    } else {
      // Simply go to previous verse in current surah
      newVerseNumber--;
    }

    // Update verse in state
    setState(() {
      _currentSurahNumber = newSurahNumber;
      _currentVerseNumber = newVerseNumber;
    });

    // Stop any playing audio
    widget.audioPlayer.stop();

    // Reset playback state
    setState(() {
      _isPlaying = false;
      _isLoading = false;
    });

    // Refresh bookmark status
    _checkBookmarkStatus();
  }

  // Method to navigate to next verse
  void _goToNextVerse() {
    int newVerseNumber = _currentVerseNumber;
    int newSurahNumber = _currentSurahNumber;

    // If we're at last verse of the surah, go to next surah's first verse
    if (newVerseNumber >= getVerseCount(newSurahNumber)) {
      if (newSurahNumber < 114) {
        newSurahNumber++;
        newVerseNumber = 1;
      } else {
        // Already at last verse of last surah, do nothing
        return;
      }
    } else {
      // Simply go to next verse in current surah
      newVerseNumber++;
    }

    // Update verse in state
    setState(() {
      _currentSurahNumber = newSurahNumber;
      _currentVerseNumber = newVerseNumber;
    });

    // Stop any playing audio
    widget.audioPlayer.stop();

    // Reset playback state
    setState(() {
      _isPlaying = false;
      _isLoading = false;
    });

    // Refresh bookmark status
    _checkBookmarkStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to calculate better positioning
    final screenSize = MediaQuery.of(context).size;
    final contentHeight = screenSize.height * 0.6; // Approximate content height
    
    return Stack(
      children: [
        Container(
          width: double.infinity,
          // Remove fixed height to avoid overflow issues
          decoration: BoxDecoration(
            color: AppStyles.bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppStyles.boxShadow.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          // Use Padding and SafeArea to ensure proper spacing
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum size to fit content
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 15),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppStyles.greyShaded300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header with decorative element
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppStyles.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyles.boxShadow.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Surah Name
                        Text(
                          "سورة ${getSurahNameArabic(_currentSurahNumber)}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Taha",
                            color: AppStyles.darkPurple,
                          ),
                        ),

                        // Decorative divider
                        Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 50),
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppStyles.trans,
                                AppStyles.lightPurple,
                                AppStyles.trans,
                              ],
                            ),
                          ),
                        ),

                        // Verse Number
                        Text(
                          "الآية ${_currentVerseNumber}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontFamily: "Taha",
                            color: AppStyles.txtFieldColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Currently selected reciter display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _reciters[_selectedReciter] ?? '',
                          style: TextStyle(
                            fontFamily: "Taha",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.darkPurple,
                          ),
                        ),
                        Text(
                          " :القارئ",
                          style: TextStyle(
                            fontFamily: "Taha",
                            fontSize: 14.sp,
                            color: AppStyles.greyShaded600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Button to change reciter
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.person,
                        color: AppStyles.txtFieldColor,
                        size: 18,
                      ),
                      label: Text(
                        "تغيير القارئ",
                        style: TextStyle(
                          fontFamily: "Taha",
                          fontSize: 14.sp,
                          color: AppStyles.txtFieldColor,
                        ),
                      ),
                      onPressed: _showReciterSelectionDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),

                  // Currently selected tafseer display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          TafseerService.tafseerEditions[_selectedTafseer] ?? '',
                          style: TextStyle(
                            fontFamily: "Taha",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.darkPurple,
                          ),
                        ),
                        Text(
                          " :التفسير",
                          style: TextStyle(
                            fontFamily: "Taha",
                            fontSize: 14.sp,
                            color: AppStyles.greyShaded600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Button to change tafseer
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.book,
                        color: AppStyles.txtFieldColor,
                        size: 18,
                      ),
                      label: Text(
                        "تغيير التفسير",
                        style: TextStyle(
                          fontFamily: "Taha",
                          fontSize: 14.sp,
                          color: AppStyles.txtFieldColor,
                        ),
                      ),
                      onPressed: _showTafseerSelectionDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),

                  // Action Buttons Row with proper padding
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Bookmark Button - Updated with dynamic state
                        _buildIconButton(
                          icon: _isBookmarkLoading
                              ? null // No icon during loading
                              : _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                          backgroundColor: _isBookmarked
                              ? AppStyles.green // Green when bookmarked
                              : AppStyles.lightPurple,
                          onPressed: _toggleBookmark,
                          showLoader: _isBookmarkLoading,
                        ),

                        // Play/Stop Button - Updated with dynamic content
                        _buildTextButton(
                          icon: _isLoading
                              ? null // No icon during loading
                              : _isPlaying
                                  ? Icons.stop
                                  : Icons.play_arrow,
                          text: _isLoading
                              ? "تحميل..." // Shorter text to prevent overflow
                              : _isPlaying
                                  ? "إيقاف"
                                  : "تشغيل",
                          backgroundColor: AppStyles.darkPurple,
                          onPressed: (_isLoading || _isOperationInProgress)
                              ? null
                              : _togglePlayPause,
                          showLoader: _isLoading,
                        ),

                        // Tafsir Button - Now directly shows the selected tafseer
                        _buildTextButton(
                          icon: Icons.menu_book,
                          text: "التفسير",
                          backgroundColor: AppStyles.txtFieldColor,
                          onPressed: _showTafseerDirectly,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Left navigation button (NEXT verse in RTL) - positioned vertically centered
        Positioned(
          left: 15,
          top: contentHeight * 0.35, // Lower position for better vertical centering
          child: _buildNavigationButton(
            Icons.arrow_back_ios_rounded,
            _goToNextVerse,
          ),
        ),

        // Right navigation button (PREVIOUS verse in RTL) - positioned vertically centered
        Positioned(
          right: 15,
          top: contentHeight * 0.35, // Lower position for better vertical centering
          child: _buildNavigationButton(
            Icons.arrow_forward_ios_rounded,
            _goToPreviousVerse,
          ),
        ),
      ],
    );
  }

  // Helper method to build navigation buttons
  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppStyles.txtFieldColor.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppStyles.boxShadow.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppStyles.white, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // Helper method to build icon buttons with loading state support
  Widget _buildIconButton({
    IconData? icon,
    required Color backgroundColor,
    VoidCallback? onPressed,
    bool showLoader = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: 60,
      height: 60,
      child: IconButton(
        icon: showLoader
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppStyles.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon ?? Icons.error, color: AppStyles.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  // Helper method to build text+icon buttons with text overflow handling
  Widget _buildTextButton({
    IconData? icon,
    required String text,
    required Color backgroundColor,
    VoidCallback? onPressed,
    bool showLoader = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 60,
      width: 120,
      child: MaterialButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLoader)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppStyles.white,
                  strokeWidth: 2,
                ),
              )
            else if (icon != null)
              Icon(icon, color: AppStyles.white),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppStyles.white,
                    fontFamily: "Taha",
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
