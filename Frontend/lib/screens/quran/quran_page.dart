import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart'; // Add this import
import 'package:easy_container/easy_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart';
import 'package:software_graduation_project/base/res/media.dart';
// import 'package:quran_tutorial/globalhelpers/constants.dart';
import 'package:software_graduation_project/components/quran/basmallah.dart';
import 'package:software_graduation_project/components/quran/header_widget.dart';
import 'package:software_graduation_project/components/quran/verse_bottom_sheet.dart';
import 'package:software_graduation_project/components/quran/web_verse.dart';
// import 'package:wakelock/wakelock.dart';
import '../../base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';

class QuranViewPage extends StatefulWidget {
  final int pageNumber;
  final dynamic jsonData;
  final bool shouldHighlightText;
  final String highlightVerse;
  final bool isWeb;

  const QuranViewPage({
    Key? key,
    required this.pageNumber,
    required this.jsonData,
    required this.shouldHighlightText,
    required this.highlightVerse,
    this.isWeb = false,
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
  List<GlobalKey> richTextKeys = List.generate(
    604, // Replace with the number of pages in your PageView
    (_) => GlobalKey(),
  );

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

  highlightVerseFunction() {
    setState(() {
      shouldHighlightText = widget.shouldHighlightText;
    });
    if (widget.shouldHighlightText) {
      setState(() {
        highlightVerse = widget.highlightVerse;
      });

      timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
        // Now we're assigning to the class property
        if (mounted) {
          setState(() {
            shouldHighlightText = false;
          });
        }
        Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              shouldHighlightText = true;
            });
          }
          if (timer.tick == 4) {
            if (mounted) {
              setState(() {
                highlightVerse = "";
                shouldHighlightText = false;
              });
            }
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    index = widget.pageNumber;
    _pageController = PageController(initialPage: index);
    highlightVerseFunction();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Set up audio player completion listener
    _pageAudioPlayer.playerStateStream.listen((state) {
      if (_isDisposed) return;

      if (state.processingState == ProcessingState.completed) {
        _playNextVerse();
      }
    });
  }

  @override
  void didUpdateWidget(QuranViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the page number changes, update the controller
    if (oldWidget.pageNumber != widget.pageNumber) {
      setState(() {
        index = widget.pageNumber;
      });
      // Jump to the new page
      _pageController.jumpToPage(index);
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
      await _pageAudioPlayer.play();
      setState(() {
        _isLoadingAudio = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Keep font size as is (0.35)
    double getWebAdjustedFontSize(double mobileSize) {
      return widget.isWeb ? mobileSize * 0.35 : mobileSize;
    }

    // Drastically reduce line height - make it much more compressed
    double getWebAdjustedLineHeight(double mobileHeight) {
      // Reduce from 0.95 to 0.75 (very compressed spacing)
      return widget.isWeb ? mobileHeight * 0.75 : mobileHeight;
    }

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
                title: "تطبيق القرآن الكريم",
                showAddButton: false,
                showBackButton: false,
              ),
        body: Stack(
          children: [
            // Main PageView content
            PageView.builder(
              reverse: true,
              scrollDirection: Axis.horizontal,
              onPageChanged: (a) {
                setState(() {
                  selectedSpan = "";
                  // Stop any playing audio and reset position when page changes
                  if (_isPlayingPage || _isPaused) {
                    _stopPlayback();
                  }
                });
                index = a;
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: (screenSize.width * .27),
                                      child: Row(
                                        children: [
                                          // Only show back button on mobile
                                          if (!widget.isWeb)
                                            IconButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              icon: const Icon(
                                                Icons.arrow_back_ios,
                                                size: 24,
                                              ),
                                            ),
                                          // Keep the text in both mobile and web
                                          Text(
                                              widget.jsonData[
                                                  getPageData(index)[0]
                                                          ["surah"] -
                                                      1]["name"],
                                              style: const TextStyle(
                                                  fontFamily: "Taha",
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    EasyContainer(
                                      borderRadius: 12,
                                      color: AppStyles.txtFieldColor,
                                      showBorder: true,
                                      height: 20,
                                      width: 120,
                                      padding: 0,
                                      margin: 0,
                                      child: Center(
                                        child: Text(
                                          "${"page"} $index ",
                                          style: TextStyle(
                                            fontFamily: 'aldahabi',
                                            fontSize: 12,
                                            color: AppStyles.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: (screenSize.width * .27),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Play Page Audio button - Updated with paused state
                                          IconButton(
                                            onPressed:
                                                index == 0 ? null : _playPage,
                                            icon: _isLoadingAudio
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
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
                                                    size: 24,
                                                  ),
                                            tooltip: _isPlayingPage
                                                ? 'إيقاف مؤقت للقراءة'
                                                : _isPaused
                                                    ? 'استئناف القراءة'
                                                    : 'قراءة الصفحة',
                                          ),
                                          // Settings button - now opens reciter selection
                                          IconButton(
                                            onPressed: () =>
                                                _showReciterSelectionDialog(),
                                            tooltip: 'اختيار القارئ',
                                            icon: Icon(
                                              Icons.settings,
                                              size: 24,
                                              color: AppStyles.txtFieldColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
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

                                              // Verses - Modified for web/mobile detection
                                              spans.add(TextSpan(
                                                // For web - use tap gesture
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
                                                  // Highlight the verse if selected
                                                  color: (highlightedSurahNumber ==
                                                              e["surah"] &&
                                                          highlightedVerseNumber ==
                                                              i)
                                                      ? AppStyles
                                                          .buttonColor // Highlight color
                                                      : AppStyles
                                                          .black, // Normal color
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
                                                  backgroundColor:
                                                      AppStyles.trans,
                                                ),
                                                children: const <TextSpan>[
                                                  // TextSpan(
                                                  //   text: getVerseQCF(e["surah"], i).substring(getVerseQCF(e["surah"], i).length - 1),
                                                  //   style:  TextStyle(
                                                  //     color: isVerseStarred(
                                                  //                                                     e[
                                                  //                                                         "surah"],
                                                  //                                                     i)
                                                  //                                                 ? Colors
                                                  //                                                     .amber
                                                  //                                                 : secondaryColors[getValue("quranPageolorsIndex")] // Change color here
                                                  //   ),
                                                  // ),
                                                ],
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
