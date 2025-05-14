import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart';
import 'package:software_graduation_project/components/quran/verse_bottom_sheet.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/res/utils/tafseer.dart';
import '../../services/quran_service.dart'; // Import QuranService for bookmark functionality
import 'tafseer_bottom_sheet.dart';
import 'web_tafseer_dialog.dart'; // Import the new web tafseer dialog

// Using the same ReciterManager and TafseerManager from verse_bottom_sheet.dart

/// Shows a popup near the verse for web users
void showWebVersePopup(
  BuildContext context,
  int pageNumber,
  int surahNumber,
  int verseNumber,
  Offset position, {
  Function? onClose,
  Function(int, int)? onVerseChange, // Add callback for verse change
}) {
  // Calculate position to show popup
  final size = MediaQuery.of(context).size;
  final screenWidth = size.width;
  final screenHeight = size.height;

  // Create audio player outside the widget to control its lifecycle separately
  final audioPlayer = AudioPlayer();

  // Store the original onClose callback so we can call it after removing the overlay
  final originalOnClose = onClose;

  // Declare overlay entry first
  late OverlayEntry entry;

  // Track drag position (added as a mutable variable outside the widget)
  Offset dragOffset = Offset.zero;

  // Function to handle cleanup and close
  void handleClose() {
    // First stop and dispose the audio player
    audioPlayer.stop().then((_) {
      audioPlayer.dispose();
      // Then remove the overlay
      entry.remove();
      // Finally call the original onClose callback to reset highlight
      if (originalOnClose != null) {
        originalOnClose();
      }
    }).catchError((_) {
      // Error handling during cleanup
      audioPlayer.dispose();
      entry.remove();
      if (originalOnClose != null) {
        originalOnClose();
      }
    });
  }

  // Create overlay entry
  entry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Dismissible background
          Positioned.fill(
            child: GestureDetector(
              onTap: handleClose,
              child: Container(color: AppStyles.trans),
            ),
          ),

          // Position the popup near the verse with drag offset
          Positioned(
            left: position.dx < screenWidth / 2
                ? position.dx + dragOffset.dx
                : null,
            right: position.dx >= screenWidth / 2
                ? (screenWidth - position.dx - 20) - dragOffset.dx
                : null,
            top: position.dy > screenHeight / 2
                ? null
                : position.dy + 30 + dragOffset.dy,
            bottom: position.dy > screenHeight / 2
                ? (screenHeight - position.dy + 30) - dragOffset.dy
                : null,
            child: Material(
              color: AppStyles.trans,
              child: WebVersePopupContent(
                pageNumber: pageNumber,
                surahNumber: surahNumber,
                verseNumber: verseNumber,
                audioPlayer: audioPlayer,
                onClose: handleClose,
                onDrag: (Offset delta) {
                  // Update the drag offset when drag occurs
                  dragOffset += delta;
                  // Force rebuild of the OverlayEntry
                  entry.markNeedsBuild();
                },
                onVerseChange: (newSurah, newVerse) {
                  // Update the highlighting on the main page
                  if (onVerseChange != null) {
                    onVerseChange(newSurah, newVerse);
                  }
                },
              ),
            ),
          ),
        ],
      );
    },
  );

  // Add the overlay to the screen
  Overlay.of(context).insert(entry);
}

// Convert to StatefulWidget to manage audio playback state
class WebVersePopupContent extends StatefulWidget {
  final int pageNumber;
  final int surahNumber;
  final int verseNumber;
  final Function onClose;
  final AudioPlayer audioPlayer;
  final Function(Offset) onDrag; // New callback for drag updates
  final Function(int, int)? onVerseChange; // Add callback for verse change

  const WebVersePopupContent({
    Key? key,
    required this.pageNumber,
    required this.surahNumber,
    required this.verseNumber,
    required this.onClose,
    required this.audioPlayer,
    required this.onDrag,
    this.onVerseChange,
  }) : super(key: key);

  @override
  State<WebVersePopupContent> createState() => _WebVersePopupContentState();
}

class _WebVersePopupContentState extends State<WebVersePopupContent> {
  // Audio playback state
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isOperationInProgress = false;
  bool _isDisposed = false;

  // Bookmark state
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  // Map of reciter IDs to their Arabic names - same as in verse_bottom_sheet.dart
  final Map<String, String> _reciters = {
    'ar.husary': 'محمود خليل الحصري',
    'ar.abdurrahmaansudais': 'عبد الرحمن السديس',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد',
    'ar.alafasy': 'مشاري راشد العفاسي',
    'ar.muhammadjibreel': 'محمد جبريل',
    'ar.muhammadayyoub': 'محمد أيوب',
    'ar.minshawi': 'محمد صديق المنشاوي',
  };

  // Track if reciter dialog is open to avoid multiple dialogs
  OverlayEntry? _dialogOverlay;
  // Service for bookmark functionality  // Service for bookmark functionality
  final QuranService _quranService = QuranService();

  // Current verse state (add these variables)
  late int _currentSurahNumber;
  late int _currentVerseNumber;

  @override
  void initState() {
    super.initState();

    // Initialize current verse
    _currentSurahNumber = widget.surahNumber;
    _currentVerseNumber = widget.verseNumber;

    // Set up audio player listeners
    widget.audioPlayer.playerStateStream.listen((state) {
      if (!_isDisposed && mounted) {
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
      if (!_isDisposed && mounted) {
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
      final bookmarks = await _quranService.getBookmarks();

      // Check if this verse is in the bookmarks
      final isBookmarked = bookmarks.any((bookmark) =>
          bookmark.surah == _currentSurahNumber &&
          bookmark.verse == _currentVerseNumber);

      if (mounted && !_isDisposed) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isBookmarkLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isBookmarkLoading = false;
        });
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
      if (_isBookmarked) {
        // Remove from bookmarks
        await _quranService.removeBookmark(
            _currentSurahNumber, _currentVerseNumber);
      } else {
        // Add to bookmarks
        await _quranService.addBookmark(
            _currentSurahNumber, _currentVerseNumber, widget.pageNumber);
      }

      if (mounted && !_isDisposed) {
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
      if (mounted && !_isDisposed) {
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
    _isDisposed = true;
    _removeDialog();
    super.dispose();
  }

  // Helper method to safely remove the dialog overlay if it exists
  void _removeDialog() {
    if (_dialogOverlay != null) {
      _dialogOverlay!.remove();
      _dialogOverlay = null;
    }
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
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = false;
            _isOperationInProgress = false;
          });
        }
      }).catchError((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isOperationInProgress = false;
          });
        }
      });
      return;
    }

    // Show loading state
    if (mounted && !_isDisposed) {
      setState(() {
        _isLoading = true;
      });
    }

    // Get audio URL
    final audioUrl = getAudioURLByVerse(_currentSurahNumber,
        _currentVerseNumber, ReciterManager.lastSelectedReciter);

    // Use a Future to avoid blocking the UI
    Future.microtask(() async {
      try {
        // Set URL with a timeout to prevent hanging
        await widget.audioPlayer.setUrl(audioUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception("Loading audio timed out");
          },
        );

        // Play with error handling
        await widget.audioPlayer.play();
      } catch (e) {
        // Handle errors
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
            _isPlaying = false;
            _isOperationInProgress = false;
          });

          // Show error indicator (simpler for web)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('عذراً، لم نتمكن من تشغيل الآية'),
              backgroundColor: AppStyles.red,
            ),
          );
        }
      } finally {
        // Ensure we reset the operation flag
        if (mounted && !_isDisposed) {
          setState(() {
            _isOperationInProgress = false;
          });
        }
      }
    });
  }

  // Show dialog to select reciter - adapted for web with overlay positioning
  void _showReciterSelectionDialog() {
    // First remove any existing dialog
    _removeDialog();

    // Get the global position of this widget
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calculate a good position for the dialog - above the popup
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = 250.0; // Fixed width for dialog
    final dialogHeight = screenSize.height * 0.3; // Approximate height

    // Position the dialog centered above the popup
    double left = position.dx + (renderBox.size.width - dialogWidth) / 2;
    double top = position.dy - dialogHeight - 10; // 10px gap

    // Keep dialog on screen
    if (left < 10) left = 10;
    if (left + dialogWidth > screenSize.width - 10) {
      left = screenSize.width - dialogWidth - 10;
    }
    if (top < 10) {
      // If not enough space above, show below
      top = position.dy + renderBox.size.height + 10;
    }

    // Create a new overlay entry
    _dialogOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full-screen dismissible background
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDialog,
              child: Container(color: AppStyles.trans),
            ),
          ),

          // The dialog itself
          Positioned(
            left: left,
            top: top,
            width: dialogWidth,
            child: Material(
              color: AppStyles.white,
              borderRadius: BorderRadius.circular(15),
              elevation: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'اختر القارئ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Taha',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.darkPurple,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: screenSize.height * 0.25),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _reciters.length,
                      itemBuilder: (_, index) {
                        String reciterId = _reciters.keys.elementAt(index);
                        String reciterName = _reciters[reciterId]!;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              ReciterManager.lastSelectedReciter = reciterId;
                            });
                            _removeDialog();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: ReciterManager.lastSelectedReciter ==
                                      reciterId
                                  ? AppStyles.lightPurple.withOpacity(0.2)
                                  : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: AppStyles.grey.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            child: Text(
                              reciterName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Taha',
                                fontSize: 14,
                                fontWeight:
                                    ReciterManager.lastSelectedReciter ==
                                            reciterId
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: ReciterManager.lastSelectedReciter ==
                                        reciterId
                                    ? AppStyles.txtFieldColor
                                    : AppStyles.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: _removeDialog,
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Taha',
                        fontSize: 14,
                        color: AppStyles.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(_dialogOverlay!);
  }

  // Show dialog to select tafseer edition for web
  void _showTafseerSelectionDialog() {
    // First remove any existing dialog
    _removeDialog();

    // Get the global position of this widget
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calculate position for the dialog
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = 250.0;
    final dialogHeight = screenSize.height * 0.3;

    // Position the dialog centered above the popup
    double left = position.dx + (renderBox.size.width - dialogWidth) / 2;
    double top = position.dy - dialogHeight - 10;

    // Keep dialog on screen
    if (left < 10) left = 10;
    if (left + dialogWidth > screenSize.width - 10) {
      left = screenSize.width - dialogWidth - 10;
    }
    if (top < 10) {
      top = position.dy + renderBox.size.height + 10;
    }

    // Create a new overlay entry for tafseer selection
    _dialogOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full-screen dismissible background
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDialog,
              child: Container(color: AppStyles.trans),
            ),
          ),

          // The dialog itself
          Positioned(
            left: left,
            top: top,
            width: dialogWidth,
            child: Material(
              color: AppStyles.white,
              borderRadius: BorderRadius.circular(15),
              elevation: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'اختر التفسير',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Taha',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.darkPurple,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: screenSize.height * 0.25),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: TafseerService.tafseerEditions.length,
                      itemBuilder: (_, index) {
                        String tafseerSlug = TafseerService.tafseerEditions.keys
                            .elementAt(index);
                        String tafseerName =
                            TafseerService.tafseerEditions[tafseerSlug]!;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              TafseerManager.lastSelectedTafseer = tafseerSlug;
                            });
                            _removeDialog();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: TafseerManager.lastSelectedTafseer ==
                                      tafseerSlug
                                  ? AppStyles.lightPurple.withOpacity(0.2)
                                  : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: AppStyles.grey.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            child: Text(
                              tafseerName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Taha',
                                fontSize: 14,
                                fontWeight:
                                    TafseerManager.lastSelectedTafseer ==
                                            tafseerSlug
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: TafseerManager.lastSelectedTafseer ==
                                        tafseerSlug
                                    ? AppStyles.txtFieldColor
                                    : AppStyles.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: _removeDialog,
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Taha',
                        fontSize: 14,
                        color: AppStyles.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(_dialogOverlay!);
  }

  // Show tafseer directly without selecting
  void _showTafseerDirectly() {
    // Store the original onClose callback for use after navigation
    final closeCallback = widget.onClose;

    // Close the verse popup first by calling onClose
    closeCallback();

    // Then show the web tafseer dialog with current selection
    showWebTafseerDialog(
      context,
      surahNumber: _currentSurahNumber,
      verseNumber: _currentVerseNumber,
      tafseerEdition: TafseerManager.lastSelectedTafseer,
    );
  }

  // Helper method to safely get font size based on screen width
  double getFontSize(BuildContext context, double size) {
    // Use more conservative font scaling for web
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth < 600 ? 0.8 : 1.0;
    return size * scaleFactor;
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

    // Update highlight in parent
    if (widget.onVerseChange != null) {
      widget.onVerseChange!(newSurahNumber, newVerseNumber);
    }

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

    // Update highlight in parent
    if (widget.onVerseChange != null) {
      widget.onVerseChange!(newSurahNumber, newVerseNumber);
    }

    // Refresh bookmark status
    _checkBookmarkStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Make popup width responsive to screen size
    final popupWidth = screenWidth < 500 ? screenWidth * 0.8 : 300.0;

    return Stack(
      children: [
        // Main popup content
        Container(
          width: popupWidth,
          constraints: BoxConstraints(
            maxHeight: 350, // Increase height for additional elements
            maxWidth:
                screenWidth * 0.9, // Ensure popup doesn't exceed screen width
          ),
          decoration: BoxDecoration(
            color: AppStyles.bgColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppStyles.boxShadow.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draggable Header area
              GestureDetector(
                onPanUpdate: (details) {
                  widget.onDrag(details.delta);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppStyles.lightPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Drag handle indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppStyles.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Close button on the right
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.close,
                              size: 20, color: AppStyles.txtFieldColor),
                          onPressed: () => widget.onClose(),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Header with decorative element
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Surah Name
                    Text(
                      "سورة ${getSurahNameArabic(_currentSurahNumber)}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: getFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        fontFamily: "Taha",
                        color: AppStyles.darkPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Decorative divider
                    Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 50),
                      height: 1,
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
                        fontSize: getFontSize(context, 16),
                        fontFamily: "Taha",
                        color: AppStyles.txtFieldColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Reciter row - right-to-left order for Arabic
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _reciters[ReciterManager.lastSelectedReciter] ?? '',
                      style: TextStyle(
                        fontFamily: "Taha",
                        fontSize: getFontSize(context, 12),
                        fontWeight: FontWeight.bold,
                        color: AppStyles.darkPurple,
                      ),
                    ),
                    Text(
                      " :القارئ",
                      style: TextStyle(
                        fontFamily: "Taha",
                        fontSize: getFontSize(context, 12),
                        color: AppStyles.greyShaded600,
                      ),
                    ),
                  ],
                ),
              ),

              // Reciter selection button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextButton.icon(
                  icon: Icon(
                    Icons.person,
                    color: AppStyles.txtFieldColor,
                    size: 14,
                  ),
                  label: Text(
                    "تغيير القارئ",
                    style: TextStyle(
                      fontFamily: "Taha",
                      fontSize: getFontSize(context, 12),
                      color: AppStyles.txtFieldColor,
                    ),
                  ),
                  onPressed: _showReciterSelectionDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    minimumSize: const Size(0, 30),
                  ),
                ),
              ),

              // Tafseer row - right-to-left order for Arabic
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      TafseerService.tafseerEditions[
                              TafseerManager.lastSelectedTafseer] ??
                          '',
                      style: TextStyle(
                        fontFamily: "Taha",
                        fontSize: getFontSize(context, 12),
                        fontWeight: FontWeight.bold,
                        color: AppStyles.darkPurple,
                      ),
                    ),
                    Text(
                      " :التفسير",
                      style: TextStyle(
                        fontFamily: "Taha",
                        fontSize: getFontSize(context, 12),
                        color: AppStyles.greyShaded600,
                      ),
                    ),
                  ],
                ),
              ),

              // Tafseer selection button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextButton.icon(
                  icon: Icon(
                    Icons.book,
                    color: AppStyles.txtFieldColor,
                    size: 14,
                  ),
                  label: Text(
                    "تغيير التفسير",
                    style: TextStyle(
                      fontFamily: "Taha",
                      fontSize: getFontSize(context, 12),
                      color: AppStyles.txtFieldColor,
                    ),
                  ),
                  onPressed: _showTafseerSelectionDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    minimumSize: const Size(0, 30),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Action Buttons Row
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bookmark Button - now with dynamic state
                    _buildIconButton(
                      context,
                      icon: _isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      backgroundColor: _isBookmarked
                          ? AppStyles.green
                          : AppStyles.lightPurple,
                      onPressed: _isBookmarkLoading ? null : _toggleBookmark,
                      showLoader: _isBookmarkLoading,
                    ),

                    // Play Button - now with dynamic state
                    _buildTextButton(
                      context,
                      icon: _isLoading
                          ? null
                          : _isPlaying
                              ? Icons.stop
                              : Icons.play_arrow,
                      text: _isLoading
                          ? "تحميل..."
                          : _isPlaying
                              ? "إيقاف"
                              : "تشغيل",
                      backgroundColor: AppStyles.darkPurple,
                      showLoader: _isLoading,
                      onPressed: (_isLoading || _isOperationInProgress)
                          ? null
                          : _togglePlayPause,
                    ),

                    // Tafsir Button - now directly shows the selected tafseer
                    _buildTextButton(
                      context,
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

        // Left navigation button (NEXT verse - functionality flipped)
        Positioned(
          left: 10, // Moved inward from -20 to 10
          top: 150, // Fixed position instead of relative calculation
          child: _buildNavigationButton(
            Icons.arrow_back_ios_rounded,
            _goToNextVerse, // Swapped to next verse
          ),
        ),

        // Right navigation button (PREVIOUS verse - functionality flipped)
        Positioned(
          right: 10, // Moved inward from -20 to 10
          top: 150, // Fixed position instead of relative calculation
          child: _buildNavigationButton(
            Icons.arrow_forward_ios_rounded,
            _goToPreviousVerse, // Swapped to previous verse
          ),
        ),
      ],
    );
  }

  // Helper method to build navigation buttons
  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36, // Slightly smaller than before (was 40)
      height: 36, // Slightly smaller than before (was 40)
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
        icon: Icon(icon,
            color: AppStyles.white, size: 16), // Smaller icon (was 18)
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // Helper method to build icon buttons with fixed sizing
  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color backgroundColor,
    VoidCallback? onPressed,
    bool showLoader = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: 36,
      height: 36,
      child: showLoader
          ? Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppStyles.white,
                  strokeWidth: 2,
                ),
              ),
            )
          : IconButton(
              icon: Icon(icon, color: AppStyles.white, size: 16),
              onPressed: onPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
    );
  }

  // Helper method to build text+icon buttons with fixed sizing
  Widget _buildTextButton(
    BuildContext context, {
    IconData? icon,
    required String text,
    required Color backgroundColor,
    VoidCallback? onPressed,
    bool showLoader = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 36,
      width: 80,
      child: MaterialButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLoader)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppStyles.white,
                  strokeWidth: 2,
                ),
              )
            else if (icon != null)
              Icon(icon, color: AppStyles.white, size: 14),
            const SizedBox(width: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppStyles.white,
                    fontFamily: "Taha",
                    fontSize: getFontSize(context, 11),
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
