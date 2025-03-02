import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/res/utils/tafseer.dart';

/// Shows a dialog with tafseer content optimized for web
void showWebTafseerDialog(
  BuildContext context, {
  required int surahNumber,
  required int verseNumber,
  required String tafseerEdition,
}) {
  // Create the dialog as an overlay for better web experience
  final screenSize = MediaQuery.of(context).size;
  final dialogWidth =
      screenSize.width < 900 ? screenSize.width * 0.8 : screenSize.width * 0.6;
  final dialogHeight = screenSize.height * 0.7;

  showDialog(
    context: context,
    builder: (context) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: AppStyles.bgColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: WebTafseerDialogContent(
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            tafseerEdition: tafseerEdition,
          ),
        ),
      ),
    ),
  );
}

class WebTafseerDialogContent extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String tafseerEdition;

  const WebTafseerDialogContent({
    Key? key,
    required this.surahNumber,
    required this.verseNumber,
    required this.tafseerEdition,
  }) : super(key: key);

  @override
  State<WebTafseerDialogContent> createState() =>
      _WebTafseerDialogContentState();
}

class _WebTafseerDialogContentState extends State<WebTafseerDialogContent> {
  bool _isLoading = true;
  String _tafseerText = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTafseer();
  }

  // Helper method to get font size based on screen size
  double getFontSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth < 600 ? 0.8 : 1.0;
    return baseSize * scaleFactor;
  }

  Future<void> _loadTafseer() async {
    try {
      final tafseerText = await TafseerService.getTafseer(
        editionSlug: widget.tafseerEdition,
        surahNumber: widget.surahNumber,
        verseNumber: widget.verseNumber,
      );

      if (mounted) {
        setState(() {
          _tafseerText = tafseerText;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تحميل التفسير: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tafseerName = TafseerService.getTafseerName(widget.tafseerEdition);

    // Create a ScrollController to manage the scrollbar
    final ScrollController scrollController = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with title and close button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppStyles.darkPurple,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    "$tafseerName - سورة ${getSurahNameArabic(widget.surahNumber)} - الآية ${widget.verseNumber}",
                    style: TextStyle(
                      fontSize: getFontSize(16),
                      fontWeight: FontWeight.bold,
                      fontFamily: "Taha",
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Verse text
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppStyles.lightPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              getVerse(widget.surahNumber, widget.verseNumber),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: getFontSize(16),
                fontFamily: "QCF_BSML",
                color: Colors.black,
              ),
            ),
          ),
        ),

        // Tafseer content with added Scrollbar
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: getFontSize(14),
                            fontFamily: "Taha",
                            color: Colors.red,
                          ),
                        ),
                      )
                    : Directionality(
                        textDirection: TextDirection.rtl,
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true, // Always show scrollbar
                          thickness:
                              6.0, // Make scrollbar slightly thicker for better visibility
                          radius: Radius.circular(
                              10), // Rounded corners on the scrollbar thumb
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Text(
                              _tafseerText,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: getFontSize(14),
                                fontFamily: "Taha",
                                color: Colors.black,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}
