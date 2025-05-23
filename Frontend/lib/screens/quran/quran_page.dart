import 'dart:async';
import 'dart:math';
import 'dart:convert'; // Add this import for JSON parsing
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:easy_container/easy_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:software_graduation_project/components/quran/basmallah.dart';
import 'package:software_graduation_project/components/quran/header_widget.dart';
import 'package:software_graduation_project/components/quran/verse_bottom_sheet.dart';
import 'package:software_graduation_project/components/quran/web_verse.dart';
import 'package:software_graduation_project/screens/quran/bookmarks_screen.dart'; // Import the bookmarks screen
import 'package:software_graduation_project/services/quran_service.dart'; // Import the QuranService
import '../../base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class QuranViewPage extends StatefulWidget {
  final int pageNumber;
  final dynamic jsonData;
  final bool shouldHighlightText;
  final String highlightVerse;
  final bool isWeb;
  final String initialSurahName; // New property to receive surah name
  final Function()? onToggleFullscreen; // Add callback for fullscreen toggle
  final bool isFullscreen; // Add state of fullscreen mode

  const QuranViewPage({
    Key? key,
    required this.pageNumber,
    required this.jsonData,
    required this.shouldHighlightText,
    required this.highlightVerse,
    this.isWeb = false,
    this.initialSurahName = "", // Default to empty string
    this.onToggleFullscreen, // Optional callback for toggling fullscreen
    this.isFullscreen = false, // Default to not fullscreen
  }) : super(key: key);

  @override
  State<QuranViewPage> createState() => _QuranViewPageState();
}

class _QuranViewPageState extends State<QuranViewPage> {
  late int index;
  late PageController _pageController;
  Timer? timer; // Change to nullable type, initialized as null
  String selectedSpan = "";
  var highlightVerse;
  var shouldHighlightText;
  String _currentSurahName = ""; // Store current surah name
  List<GlobalKey> richTextKeys = List.generate(
    604, // Replace with the number of pages in your PageView
    (_) => GlobalKey(),
  );
  final QuranService _quranService =
      QuranService(); // Add QuranService instance
  Timer? _readingProgressTimer; // Timer to update reading progress periodically

  int? highlightedSurahNumber;
  int? highlightedVerseNumber;

  // Add properties for page audio playback
  final AudioPlayer _pageAudioPlayer = AudioPlayer();
  bool _isPlayingPage = false;
  bool _isLoadingAudio = false;
  int _currentPlayingVerseIndex = 0;
  List<Map<String, dynamic>> _pageVerses = [];
  bool _isDisposed = false;
  bool _isPaused = false; // Track if playback is paused vs stopped

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

  // Add new state variables for cluster coloring
  bool _isColoringEnabled = false;
  Map<String, int> _verseClusterMap =
      {}; // Map to store (surah:ayah) -> cluster mapping
  List<Color> _clusterColors = []; // List of colors for each cluster (0-19)
  bool _isClusterDataLoaded = false;

  highlightVerseFunction() {
    setState(() {
      shouldHighlightText = widget.shouldHighlightText;
    });

    if (widget.shouldHighlightText && widget.highlightVerse.isNotEmpty) {
      List<String> verseParts = widget.highlightVerse.split(':');
      if (verseParts.length == 2) {
        setState(() {
          highlightVerse = widget.highlightVerse;
          highlightedSurahNumber = int.tryParse(verseParts[0]);
          highlightedVerseNumber = int.tryParse(verseParts[1]);
        });

        // Only show the web verse popup if not already handled externally
        if (widget.isWeb &&
            highlightedSurahNumber != null &&
            highlightedVerseNumber != null) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Calculate the position for the popup
              final renderBox = richTextKeys[index - 1]
                  .currentContext
                  ?.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final position = renderBox.localToGlobal(Offset.zero);
                final centerPosition = Offset(
                  position.dx + renderBox.size.width / 2,
                  position.dy + renderBox.size.height / 4,
                );

                // Show the web verse popup with verse change callback
                showWebVersePopup(
                  context,
                  index,
                  highlightedSurahNumber!,
                  highlightedVerseNumber!,
                  centerPosition,
                  onClose: () {
                    // Clear highlight after popup closes
                    if (mounted) {
                      setState(() {
                        highlightedSurahNumber = null;
                        highlightedVerseNumber = null;
                      });
                    }
                  },
                  onVerseChange: (newSurah, newVerse) {
                    // When verse changes in popup, update highlight on page
                    if (mounted) {
                      setState(() {
                        highlightedSurahNumber = newSurah;
                        highlightedVerseNumber = newVerse;
                      });
                    }
                  },
                );
              }
            }
          });
        } else if (!widget.isWeb) {
          // For mobile, show the bottom sheet
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted &&
                highlightedSurahNumber != null &&
                highlightedVerseNumber != null) {
              showVerseBottomSheet(
                context,
                index,
                highlightedSurahNumber!,
                highlightedVerseNumber!,
                onClose: () {
                  // Keep the verse highlighted after closing
                },
              );
            }
          });
        }

        // Continue with the blinking effect for better visibility
        timer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
          if (mounted) {
            setState(() {
              shouldHighlightText = !shouldHighlightText;
            });
          }

          // After 3 cycles, stop the blinking but keep verse highlighted
          if (timer.tick == 3) {
            if (mounted) {
              setState(() {
                highlightVerse = "";
                shouldHighlightText = false;
              });
            }
            timer.cancel();
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    index = widget.pageNumber;
    _pageController = PageController(initialPage: index);

    // Initialize with the provided surah name if available
    if (widget.initialSurahName.isNotEmpty) {
      _currentSurahName = widget.initialSurahName;
    }

    // Setup highlighting and automatically show bottom sheet
    highlightVerseFunction();

    // Parse highlightVerse to set up highlighting for selected verse
    if (widget.shouldHighlightText && widget.highlightVerse.isNotEmpty) {
      List<String> verseParts = widget.highlightVerse.split(':');
      if (verseParts.length == 2) {
        highlightedSurahNumber = int.tryParse(verseParts[0]);
        highlightedVerseNumber = int.tryParse(verseParts[1]);
      }
    }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Set up audio player completion listener
    _pageAudioPlayer.playerStateStream.listen((state) {
      if (_isDisposed) return;

      if (state.processingState == ProcessingState.completed) {
        _playNextVerse();
      }
    });

    // Add this listener for playback state to handle the loading->playing transition
    _pageAudioPlayer.playbackEventStream.listen((event) {
      if (_isDisposed) return;

      // When audio is actually playing and we're still showing loading
      if (_pageAudioPlayer.playing && _isLoadingAudio) {
        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }
      }
    });

    // Initialize the cluster data
    _initializeClusterData();

    // Set up timer to track reading progress - update every 5 seconds
    _readingProgressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateReadingProgress();
    });

    // Force update to display surah name correctly - needed when navigating from home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // This refresh ensures correct surah name display
        });
      }
    });

    // Setup a delayed task to ensure the UI correctly shows the surah name
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          // If no initial surah name was provided, try to determine it
          if (_currentSurahName.isEmpty) {
            _currentSurahName = _getSurahName(index);
          }
          print("Setting surah name: $_currentSurahName for page $index");
        });
      }
    });
  }

  // Method to highlight a verse and show the web verse popup
  void highlightAndShowWebVersePopup(int surahNumber, int verseNumber) {
    if (!widget.isWeb || !mounted) return;

    print("Highlighting verse $surahNumber:$verseNumber in web view");

    // Set the highlight state
    setState(() {
      highlightedSurahNumber = surahNumber;
      highlightedVerseNumber = verseNumber;
      shouldHighlightText = true;
      highlightVerse = "$surahNumber:$verseNumber";
    });

    // Use a delayed future to find the verse element
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Find the RenderBox element containing our verse
      RenderBox? findVerseRenderBox() {
        // Find matching verse elements
        for (int i = 0; i < richTextKeys.length; i++) {
          if (richTextKeys[i].currentContext == null) continue;

          try {
            // Get the RenderBox for this key
            final renderBox = richTextKeys[i].currentContext!.findRenderObject()
                as RenderBox?;
            if (renderBox != null) {
              return renderBox;
            }
          } catch (e) {
            print("Error finding render box: $e");
          }
        }
        return null;
      }

      final renderBox = findVerseRenderBox();

      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);

        // Calculate center position
        final centerPosition = Offset(position.dx + renderBox.size.width / 2,
            position.dy + renderBox.size.height / 2);

        // Show web popup with verse change callback
        showWebVersePopup(
          context,
          index,
          surahNumber,
          verseNumber,
          centerPosition,
          onClose: () {
            // Clear highlight after popup closes
            if (mounted) {
              setState(() {
                highlightedSurahNumber = null;
                highlightedVerseNumber = null;
              });
            }
          },
          onVerseChange: (newSurah, newVerse) {
            // When verse changes in popup, update highlight on page
            if (mounted) {
              setState(() {
                highlightedSurahNumber = newSurah;
                highlightedVerseNumber = newVerse;
              });
            }
          },
        );

        // After a delay, ensure highlighting is stable
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              shouldHighlightText = false;
            });
          }
        });
      } else {
        print("Could not find verse render box");
      }
    });
  }

  // Method to update the user's reading progress
  void _updateReadingProgress() async {
    if (index > 0) {
      // Only update if on an actual Quran page (not cover)
      try {
        await _quranService.updateLastReadPage(index);
      } catch (e) {
        print('Error updating reading progress: $e');
        // Don't show error to user as this is a background operation
      }
    }
  }

  // Method to load and initialize cluster data
  Future<void> _initializeClusterData() async {
    // Get cluster colors from AppStyles instead of defining them inline
    _clusterColors = AppStyles.clusterColors;

    try {
      // Load the JSON file
      String jsonString =
          await rootBundle.loadString('assets/utils/df_final.json');
      List<dynamic> clusterData = jsonDecode(jsonString);

      // Populate the verse-cluster map
      for (var item in clusterData) {
        int surah = item['sura'];
        int ayah = item['ayah'];
        int cluster = item['cluster'];

        // Create a key like "1:2" for surah 1, ayah 2
        String key = "$surah:$ayah";
        _verseClusterMap[key] = cluster;
      }

      if (mounted) {
        setState(() {
          _isClusterDataLoaded = true;
        });
      }
    } catch (e) {
      print("Error loading cluster data: $e");
    }
  }

  // Helper method to get verse color based on its cluster
  Color? _getVerseColor(int surah, int ayah) {
    if (!_isColoringEnabled || !_isClusterDataLoaded) return null;

    String key = "$surah:$ayah";
    int? cluster = _verseClusterMap[key];

    if (cluster == null) return null;

    return _clusterColors[cluster];
  }

  @override
  void didUpdateWidget(QuranViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pageNumber != widget.pageNumber) {
      setState(() {
        index = widget.pageNumber;
      });
      _pageController.jumpToPage(index);
    }

    if (widget.shouldHighlightText && widget.highlightVerse.isNotEmpty) {
      highlightVerseFunction(); // Highlight and show verse sheet
    }
  }

  @override
  void dispose() {
    // Ensure clean disposal - more robust version
    _cleanupResources();
    super.dispose();
  }

  // Safely clean up all resources - separate method for reuse
  void _cleanupResources() {
    _isDisposed = true;

    // Cancel the reading progress timer
    if (_readingProgressTimer != null && _readingProgressTimer!.isActive) {
      _readingProgressTimer!.cancel();
    }

    // Cancel any active timers - safely check if timer exists and is active
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }

    // Safely stop and dispose audio player
    try {
      _pageAudioPlayer.stop().then((_) {
        try {
          _pageAudioPlayer.dispose();
        } catch (e) {
          // Ignore disposal errors
          print("Error disposing audio player: $e");
        }
      }).catchError((error) {
        try {
          _pageAudioPlayer.dispose();
        } catch (e) {
          // Ignore disposal errors
          print("Error disposing audio player after stop error: $e");
        }
      });
    } catch (e) {
      // If direct stop fails, try to dispose anyway
      try {
        _pageAudioPlayer.dispose();
      } catch (innerError) {
        // Final fallback - ignore and continue
        print("Error in resource cleanup: $innerError");
      }
    }

    // Update reading progress one last time before leaving
    _updateReadingProgress();
  }

  // Navigate to bookmarks screen
  void _navigateToBookmarks() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookmarksScreen(
          jsonData: widget.jsonData,
          isWeb: widget
              .isWeb, // Pass the widget.isWeb flag to indicate web platform
        ),
      ),
    );
  }

  // Method to prepare the list of verses on the current page
  void _preparePageVerses() {
    _pageVerses = [];
    final pageData = getPageData(index);

    for (var surahData in pageData) {
      int surahNumber = surahData["surah"];
      for (int verseNumber = surahData["start"];
          verseNumber <= surahData["end"];
          verseNumber++) {
        _pageVerses.add({
          "surah": surahNumber,
          "verse": verseNumber,
        });
      }
    }
  }

  // Method to start playing the entire page - MODIFIED
  void _playPage() async {
    // If already playing, pause playback
    if (_isPlayingPage) {
      await _pausePlayback();
      return;
    }

    // If paused, resume from current position
    if (_isPaused) {
      setState(() {
        _isPlayingPage = true;
        _isPaused = false;
        _isLoadingAudio = true;
      });
      _playCurrentVerse();
      return;
    }

    // If starting fresh, prepare verses and play from beginning
    _preparePageVerses();

    if (_pageVerses.isEmpty) return;

    setState(() {
      _isPlayingPage = true;
      _isLoadingAudio = true;
      _currentPlayingVerseIndex = 0;
    });

    // Start playing from the first verse
    _playCurrentVerse();
  }

  // Method to play the current verse in the sequence
  void _playCurrentVerse() async {
    if (_currentPlayingVerseIndex >= _pageVerses.length || _isDisposed) {
      await _stopPlayback();
      return;
    }

    final currentVerse = _pageVerses[_currentPlayingVerseIndex];
    final surahNumber = currentVerse["surah"];
    final verseNumber = currentVerse["verse"];

    // Highlight the current verse
    setState(() {
      highlightedSurahNumber = surahNumber;
      highlightedVerseNumber = verseNumber;
      _isLoadingAudio = true;
    });

    try {
      // Get audio URL for current verse using preferred reciter
      final audioUrl = getAudioURLByVerse(surahNumber, verseNumber,
          ReciterManager.lastSelectedReciter // Use the last selected reciter
          );

      // Set and play the audio
      await _pageAudioPlayer.setUrl(audioUrl);

      // Start playing - the loading icon will be updated by the playbackEventStream listener
      await _pageAudioPlayer.play();

      // We're not updating _isLoadingAudio here anymore
      // That's now handled by the playbackEventStream listener
    } catch (e) {
      // If there's an error, try to move to the next verse
      print("Error playing verse: $e");
      _playNextVerse();
    }
  }

  // Method to play the next verse in the sequence
  void _playNextVerse() {
    if (_isDisposed) return;

    setState(() {
      _currentPlayingVerseIndex++;
    });

    if (_currentPlayingVerseIndex < _pageVerses.length) {
      _playCurrentVerse();
    } else {
      // We've reached the end of the page
      _stopPlayback();
    }
  }

  // New method to pause playback (instead of stopping)
  Future<void> _pausePlayback() async {
    if (_isDisposed) return;

    await _pageAudioPlayer.pause();
    setState(() {
      _isPlayingPage = false;
      _isPaused = true;
      _isLoadingAudio = false;
    });
  }

  // Method to stop playback - keep for full reset when needed
  Future<void> _stopPlayback() async {
    if (_isDisposed) return;

    await _pageAudioPlayer.stop();
    setState(() {
      _isPlayingPage = false;
      _isPaused = false;
      _isLoadingAudio = false;
      _currentPlayingVerseIndex = 0;
      highlightedSurahNumber = null;
      highlightedVerseNumber = null;
    });
  }

  // Show dialog to select reciter for page playback
  void _showReciterSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use different styles for web and mobile
        final isWeb = widget.isWeb;

        final titleStyle = TextStyle(
          fontFamily: 'Taha',
          fontSize: isWeb ? 16 : 20.sp, // Smaller size for web
          fontWeight: FontWeight.bold,
          color: AppStyles.darkPurple,
        );

        final textStyle = TextStyle(
          fontFamily: 'Taha',
          fontSize: isWeb ? 14 : 16.sp, // Smaller size for web
        );

        final buttonStyle = TextStyle(
          fontFamily: 'Taha',
          fontSize: isWeb ? 14 : 16.sp, // Smaller size for web
          color: Colors.grey,
        );

        // Calculate max height - much smaller for web
        final maxHeight =
            MediaQuery.of(context).size.height * (isWeb ? 0.25 : 0.35);

        // Calculate dialog width - constrained for web
        final dialogWidth = isWeb
            ? min(MediaQuery.of(context).size.width * 0.3, 300.0)
            : // Max 300px for web
            double.maxFinite; // Full width for mobile

        return AlertDialog(
          title: Text(
            'اختر القارئ',
            textAlign: TextAlign.center,
            style: titleStyle,
          ),
          content: Container(
            width: dialogWidth,
            // Add a fixed height constraint - smaller for web
            constraints: BoxConstraints(
              maxHeight: maxHeight,
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
                      fontSize: isWeb ? 14 : 16.sp, // Smaller size for web
                      fontWeight:
                          ReciterManager.lastSelectedReciter == reciterId
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: ReciterManager.lastSelectedReciter == reciterId
                          ? AppStyles.txtFieldColor
                          : AppStyles.black,
                    ),
                  ),
                  selected: ReciterManager.lastSelectedReciter == reciterId,
                  onTap: () {
                    setState(() {
                      ReciterManager.lastSelectedReciter = reciterId;
                    });
                    Navigator.of(context).pop();
                  },
                  tileColor: ReciterManager.lastSelectedReciter == reciterId
                      ? AppStyles.lightPurple.withOpacity(0.2)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // More compact for web
                  dense: isWeb,
                  visualDensity: isWeb
                      ? VisualDensity(horizontal: 0, vertical: -2)
                      : VisualDensity.standard,
                  contentPadding: isWeb
                      ? EdgeInsets.symmetric(horizontal: 8, vertical: 0)
                      : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'إلغاء',
                style: buttonStyle,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          // Make dialog more compact for web
          insetPadding:
              isWeb ? EdgeInsets.symmetric(horizontal: 40, vertical: 24) : null,
          buttonPadding:
              isWeb ? EdgeInsets.symmetric(horizontal: 8, vertical: 8) : null,
        );
      },
    );
  }

  // Method to adjust font size for web
  double getWebAdjustedFontSize(double mobileSize) {
    return widget.isWeb ? mobileSize * 0.35 : mobileSize;
  }

  // Method to adjust line height for web
  double getWebAdjustedLineHeight(double mobileHeight) {
    // Reduce from 0.95 to 0.75 (very compressed spacing)
    return widget.isWeb ? mobileHeight * 0.75 : mobileHeight;
  }

  // Improved method to get surah name with fallbacks
  String _getSurahName(int index) {
    try {
      // Cover page has no surah name
      if (index == 0) return "";

      final pageData = getPageData(index);

      // Check if pageData has content
      if (pageData.isEmpty) return "";

      // Get the surah number
      final surahNumber = pageData[0]["surah"];

      // First try to get name directly from the Quran package
      String name = getSurahNameArabic(surahNumber);
      if (name.isNotEmpty) {
        return name;
      }

      // Fall back to jsonData if the direct method failed
      if (widget.jsonData != null) {
        final surahIndex = surahNumber - 1;
        if (surahIndex >= 0 && surahIndex < widget.jsonData.length) {
          name = widget.jsonData[surahIndex]["name"]?.toString() ?? "";
          if (name.isNotEmpty) {
            return name;
          }
        }
      }

      // Fallback: Just return the surah number if we can't get the name
      return "سورة $surahNumber";
    } catch (e) {
      print('Error getting surah name: $e');
      return "";
    }
  }

  // Update current surah name when page changes
  void _updateCurrentPage(int newIndex) {
    if (index != newIndex) {
      setState(() {
        index = newIndex;
        selectedSpan = "";
        _currentSurahName = _getSurahName(newIndex);

        // Stop any playing audio when page changes
        if (_isPlayingPage || _isPaused) {
          _stopPlayback();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Wrap Scaffold with WillPopScope to handle back button press safely
    return WillPopScope(
      // Handle back button press by stopping any audio playback first
      onWillPop: () async {
        // More robust way to handle pop
        if (!_isDisposed) {
          _cleanupResources();
          // Small delay to ensure cleanup completes
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return true;
      },
      child: Scaffold(
        // Only show AppBar on mobile, not on web
        appBar: widget.isWeb
            ? null
            : const CustomAppBar(
                title: "القرآن الكريم",
                showAddButton: false,
                showBackButton: false,
                titleFontFamily: 'thuluth',
              ),
        body: Stack(
          children: [
            // Main PageView content
            PageView.builder(
              reverse: true,
              scrollDirection: Axis.horizontal,
              onPageChanged: (a) {
                _updateCurrentPage(a);
              },
              controller: _pageController,
              // onPageChanged: _onPageChanged,
              itemCount:
                  totalPagesCount + 1 /* specify the total number of pages */,
              itemBuilder: (context, index) {
                bool isEvenPage = index.isEven;

                if (index == 0) {
                  return Container(
                    color: AppStyles.white,
                    child: Image.asset(
                      "assets/images/quran_cover_2.png",
                      fit: BoxFit.fill,
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppStyles.bgColor,
                  ),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    backgroundColor: AppStyles.trans,
                    body: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0, left: 12),
                        child: SingleChildScrollView(
                          // physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(
                                width: screenSize.width,
                                child: Row(
                                  children: [
                                    // Left side: Back button (mobile) and Bookmarks - Fixed width
                                    SizedBox(
                                      width: screenSize.width * 0.3,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Only show back button on mobile with reduced padding
                                          if (!widget.isWeb)
                                            IconButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(
                                                Icons.arrow_back_ios,
                                                size: 24,
                                              ),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity(
                                                  horizontal: -4, vertical: 0),
                                              constraints: BoxConstraints(),
                                            ),

                                          // Add fullscreen toggle button for web only
                                          if (widget.isWeb &&
                                              widget.onToggleFullscreen != null)
                                            IconButton(
                                              onPressed:
                                                  widget.onToggleFullscreen,
                                              icon: Icon(
                                                widget.isFullscreen
                                                    ? Icons.fullscreen_exit
                                                    : Icons.fullscreen,
                                                size: 22,
                                                color: AppStyles.txtFieldColor,
                                              ),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity(
                                                  horizontal: -4, vertical: 0),
                                              constraints: BoxConstraints(),
                                              tooltip: widget.isFullscreen
                                                  ? 'إظهار الفهرس'
                                                  : 'إخفاء الفهرس',
                                            ),

                                          // Surah name - use the state variable that persists across rebuilds
                                          Flexible(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  left: !widget.isWeb ? 0 : 8),
                                              child: Text(
                                                index == this.index
                                                    ? _currentSurahName
                                                    : _getSurahName(index),
                                                style: const TextStyle(
                                                  fontFamily: "Taha",
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Center: Page number - Fixed center with equal spacing
                                    Expanded(
                                      child: Center(
                                        child: EasyContainer(
                                          borderRadius: 12,
                                          color: AppStyles.txtFieldColor,
                                          showBorder: true,
                                          height: 20,
                                          width: 120,
                                          padding: 0,
                                          customMargin: EdgeInsets.zero,
                                          child: Center(
                                            child: Text(
                                              "${"الصفحة"} $index ",
                                              style: TextStyle(
                                                fontFamily: 'aldahabi',
                                                fontSize: 12,
                                                color: AppStyles.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Right side: Action buttons - Fixed width to match left
                                    SizedBox(
                                      width: screenSize.width * 0.3,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Add the new toggle button for verse coloring
                                          IconButton(
                                            onPressed: _isClusterDataLoaded
                                                ? () {
                                                    setState(() {
                                                      _isColoringEnabled =
                                                          !_isColoringEnabled;
                                                    });
                                                  }
                                                : null,
                                            icon: Icon(
                                              _isColoringEnabled
                                                  ? FlutterIslamicIcons
                                                      .solidQuran
                                                  : FlutterIslamicIcons.quran,
                                              color: AppStyles.txtFieldColor,
                                              size: widget.isWeb ? 24 : 22,
                                            ),
                                            tooltip: _isColoringEnabled
                                                ? 'إيقاف تلوين الآيات'
                                                : 'تلوين الآيات حسب المجموعة',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            visualDensity: VisualDensity(
                                                horizontal: -4, vertical: -4),
                                          ),

                                          // Smaller spacing
                                          SizedBox(width: widget.isWeb ? 8 : 0),

                                          // Play Page Audio button - Updated with paused state
                                          IconButton(
                                            onPressed:
                                                index == 0 ? null : _playPage,
                                            icon: _isLoadingAudio
                                                ? SizedBox(
                                                    width:
                                                        widget.isWeb ? 24 : 22,
                                                    height:
                                                        widget.isWeb ? 24 : 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth:
                                                          widget.isWeb ? 3 : 2,
                                                      color: AppStyles
                                                          .txtFieldColor,
                                                    ),
                                                  )
                                                : Icon(
                                                    _isPlayingPage
                                                        ? Icons.pause_circle
                                                        : _isPaused
                                                            ? Icons.play_circle
                                                            : Icons
                                                                .play_circle_outline,
                                                    color:
                                                        AppStyles.txtFieldColor,
                                                    size:
                                                        widget.isWeb ? 24 : 22,
                                                  ),
                                            tooltip: _isPlayingPage
                                                ? 'إيقاف مؤقت للقراءة'
                                                : _isPaused
                                                    ? 'استئناف القراءة'
                                                    : 'قراءة الصفحة',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            visualDensity: VisualDensity(
                                                horizontal: -4, vertical: -4),
                                          ),

                                          // Smaller spacing
                                          SizedBox(width: widget.isWeb ? 8 : 0),

                                          // Settings button - now opens reciter selection
                                          IconButton(
                                            onPressed: () =>
                                                _showReciterSelectionDialog(),
                                            tooltip: 'اختيار القارئ',
                                            icon: Icon(
                                              Icons.settings,
                                              size: widget.isWeb ? 24 : 22,
                                              color: AppStyles.txtFieldColor,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            visualDensity: VisualDensity(
                                                horizontal: -4, vertical: -4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if ((index == 1 || index == 2))
                                SizedBox(
                                  height: (screenSize.height * .05),
                                ),
                              const SizedBox(
                                height: 10,
                              ),
                              Directionality(
                                  textDirection: m.TextDirection.rtl,
                                  child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: RichText(
                                        key: richTextKeys[index - 1],
                                        textDirection: m.TextDirection.rtl,
                                        textAlign: (index == 1 ||
                                                index == 2 ||
                                                index > 570)
                                            ? TextAlign.center
                                            : TextAlign.center,
                                        softWrap: true,
                                        locale: const Locale("ar"),
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: AppStyles.black,
                                            fontSize: getWebAdjustedFontSize(
                                                23.sp.toDouble()),
                                          ),
                                          children:
                                              getPageData(index).expand((e) {
                                            List<InlineSpan> spans = [];
                                            for (var i = e["start"];
                                                i <= e["end"];
                                                i++) {
                                              // Header with isWeb flag passed
                                              if (i == 1) {
                                                spans.add(WidgetSpan(
                                                  child: HeaderWidget(
                                                    e: e,
                                                    jsonData: widget.jsonData,
                                                    isWeb: widget
                                                        .isWeb, // Pass isWeb flag to header
                                                  ),
                                                ));

                                                // Add a line break after the header for Surah Al-Fatiha (surah 1)
                                                if (e["surah"] == 1) {
                                                  spans.add(WidgetSpan(
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      height: widget.isWeb
                                                          ? 10
                                                          : 20.h,
                                                    ),
                                                  ));
                                                }

                                                if (index != 187 &&
                                                    index != 1) {
                                                  spans.add(WidgetSpan(
                                                    child: Basmallah(index: 0),
                                                  ));
                                                }
                                                if (index == 187) {
                                                  spans.add(WidgetSpan(
                                                    child: Container(
                                                      height: 10.h,
                                                    ),
                                                  ));
                                                }
                                              }

                                              // Verses - Modified for web/mobile detection AND color by cluster
                                              spans.add(TextSpan(
                                                recognizer: widget.isWeb
                                                    ? (TapGestureRecognizer()
                                                      ..onTap = () {
                                                        // Set the highlighted verse for visual feedback
                                                        setState(() {
                                                          highlightedSurahNumber =
                                                              e["surah"];
                                                          highlightedVerseNumber =
                                                              i;
                                                        });

                                                        // Calculate position for popup
                                                        final RenderBox?
                                                            renderBox =
                                                            richTextKeys[index -
                                                                        1]
                                                                    .currentContext
                                                                    ?.findRenderObject()
                                                                as RenderBox?;
                                                        if (renderBox != null) {
                                                          final position =
                                                              renderBox
                                                                  .localToGlobal(
                                                                      Offset
                                                                          .zero);

                                                          // Show web popup
                                                          showWebVersePopup(
                                                            context,
                                                            index,
                                                            e["surah"],
                                                            i,
                                                            Offset(
                                                                position.dx +
                                                                    renderBox
                                                                            .size
                                                                            .width /
                                                                        2,
                                                                position.dy +
                                                                    renderBox
                                                                            .size
                                                                            .height /
                                                                        4),
                                                            onClose: () {
                                                              // Clear highlight when popup closes
                                                              if (mounted) {
                                                                setState(() {
                                                                  highlightedSurahNumber =
                                                                      null;
                                                                  highlightedVerseNumber =
                                                                      null;
                                                                });
                                                              }
                                                            },
                                                          );
                                                        }
                                                      })
                                                    // For mobile - keep long press gesture
                                                    : (LongPressGestureRecognizer()
                                                      ..onLongPress = () {
                                                        // Set the highlighted verse
                                                        setState(() {
                                                          highlightedSurahNumber =
                                                              e["surah"];
                                                          highlightedVerseNumber =
                                                              i;
                                                        });

                                                        // Show the bottom sheet
                                                        showVerseBottomSheet(
                                                          context,
                                                          index,
                                                          e["surah"],
                                                          i,
                                                          onClose: () {
                                                            // Clear highlight when sheet closes
                                                            if (mounted) {
                                                              setState(() {
                                                                highlightedSurahNumber =
                                                                    null;
                                                                highlightedVerseNumber =
                                                                    null;
                                                              });
                                                            }
                                                          },
                                                        );
                                                      }
                                                      ..onLongPressDown =
                                                          (details) {
                                                        setState(() {
                                                          selectedSpan =
                                                              " ${e["surah"]}$i";
                                                        });
                                                      }
                                                      ..onLongPressUp = () {
                                                        setState(() {
                                                          selectedSpan = "";
                                                        });
                                                      }
                                                      ..onLongPressCancel =
                                                          () => setState(() {
                                                                selectedSpan =
                                                                    "";
                                                              })),
                                                text: i == e["start"]
                                                    ? "${getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(0, 1)}\u200A${getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(1)}"
                                                    : getVerseQCF(e["surah"], i)
                                                        .replaceAll(' ', ''),
                                                style: TextStyle(
                                                  // Keep text color as black (or highlighted if needed)
                                                  color: (highlightedSurahNumber ==
                                                              e["surah"] &&
                                                          highlightedVerseNumber ==
                                                              i)
                                                      ? AppStyles
                                                          .buttonColor // Highlight color (priority 1)
                                                      : AppStyles
                                                          .black, // Normal color always black
                                                  height: (index == 1 ||
                                                          index == 2)
                                                      ? getWebAdjustedLineHeight(
                                                          2.h)
                                                      : getWebAdjustedLineHeight(
                                                          1.95.h),
                                                  letterSpacing: 0.w,
                                                  wordSpacing: 0,
                                                  fontFamily:
                                                      "QCF_P${index.toString().padLeft(3, "0")}",
                                                  fontSize: getWebAdjustedFontSize(
                                                      index == 1 || index == 2
                                                          ? 28.sp
                                                          : index == 145 ||
                                                                  index == 201
                                                              ? index == 532 ||
                                                                      index ==
                                                                          533
                                                                  ? 22.5.sp
                                                                  : 17.9.sp
                                                              : 17.9.sp),
                                                  // Apply cluster colors to background instead of text
                                                  backgroundColor:
                                                      _isColoringEnabled
                                                          ? _getVerseColor(
                                                                  e["surah"], i)
                                                              ?.withOpacity(
                                                                  0.2) // More transparent background
                                                          : AppStyles
                                                              .trans, // Transparent when not coloring
                                                ),
                                              ));
                                            }
                                            return spans;
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ))
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Add left and right navigation arrows only in web mode
            if (widget.isWeb) ...[
              // Left navigation arrow - Now navigates left (next page since we're in RTL)
              Positioned(
                left: 10,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: FloatingActionButton(
                  heroTag: 'prevPage',
                  backgroundColor: AppStyles.grey
                      .withOpacity(0.1), // Much more transparent grey
                  mini: true,
                  elevation: 1, // Reduced elevation for subtlety
                  onPressed: () {
                    if (index < totalPagesCount) {
                      // For next page (moving left in RTL)
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(Icons.arrow_back_ios,
                      color: AppStyles.white), // Swapped icon
                ),
              ),

              // Right navigation arrow - Now navigates right (previous page since we're in RTL)
              Positioned(
                right: 10,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: FloatingActionButton(
                  heroTag: 'nextPage',
                  backgroundColor: AppStyles.grey
                      .withOpacity(0.1), // Much more transparent grey
                  mini: true,
                  elevation: 1, // Reduced elevation for subtlety
                  onPressed: () {
                    if (index > 1) {
                      // For previous page (moving right in RTL)
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(Icons.arrow_forward_ios,
                      color: AppStyles.white), // Swapped icon
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
