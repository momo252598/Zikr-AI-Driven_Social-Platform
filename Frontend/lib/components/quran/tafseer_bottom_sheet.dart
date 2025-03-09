import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/res/utils/tafseer.dart';

/// Shows a bottom sheet with tafseer content
void showTafseerBottomSheet(
  BuildContext context, {
  required int surahNumber,
  required int verseNumber,
  required String tafseerEdition,
  Function? onClose,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      maxWidth: MediaQuery.of(context).size.width,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return TafseerBottomSheetContent(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        tafseerEdition: tafseerEdition,
      );
    },
  ).then((_) {
    if (onClose != null) {
      onClose();
    }
  });
}

class TafseerBottomSheetContent extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String tafseerEdition;

  const TafseerBottomSheetContent({
    Key? key,
    required this.surahNumber,
    required this.verseNumber,
    required this.tafseerEdition,
  }) : super(key: key);

  @override
  State<TafseerBottomSheetContent> createState() =>
      _TafseerBottomSheetContentState();
}

class _TafseerBottomSheetContentState extends State<TafseerBottomSheetContent> {
  bool _isLoading = true;
  String _tafseerText = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTafseer();
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

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
              margin: const EdgeInsets.only(top: 10, bottom: 5),
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
                  "الآية ${widget.verseNumber} - $tafseerName",
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

          const SizedBox(height: 10),

          // Verse text in bordered container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppStyles.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppStyles.lightPurple.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppStyles.boxShadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                getVerse(widget.surahNumber, widget.verseNumber),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: "QCF_BSML", // Using Quran font
                  color: AppStyles.black,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Content - Shows loading, error, or tafseer text
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontFamily: "Taha",
                              color: AppStyles.red,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _tafseerText,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontFamily: "Taha",
                                color: AppStyles.black,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
            ),
          ),

          // Bottom padding
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}
