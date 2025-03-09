import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/utils/tafseer.dart';
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
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return VerseBottomSheetContent(
        pageNumber: pageNumber,
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        audioPlayer: audioPlayer, // Pass the audio player instance
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
        widget.surahNumber, widget.verseNumber, _selectedReciter);

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
      surahNumber: widget.surahNumber,
      verseNumber: widget.verseNumber,
      tafseerEdition: _selectedTafseer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Increase height to fix overflow issue
      height: MediaQuery.of(context).size.height * 0.48,
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
      child: Column(
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
                  "سورة ${getSurahNameArabic(widget.surahNumber)}",
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
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 50),
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
                  "الآية ${widget.verseNumber}",
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

          // Currently selected reciter display - switched order
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

          // Currently selected tafseer display - switched order
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

          // Spacer to push buttons to the bottom
          const Spacer(),

          // Action Buttons Row
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bookmark Button
                _buildIconButton(
                  icon: Icons.bookmark_border,
                  backgroundColor: AppStyles.lightPurple,
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
    );
  }

  // Helper method to build icon buttons
  Widget _buildIconButton({
    required IconData icon,
    required Color backgroundColor,
    VoidCallback? onPressed,
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
        icon: Icon(icon, color: AppStyles.white, size: 28),
        onPressed: onPressed ?? () {},
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
