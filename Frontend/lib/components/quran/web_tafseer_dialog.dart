import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import '../../base/res/styles/app_styles.dart';
import '../../base/res/utils/tafseer.dart';

/// Shows a dialog with tafseer content for web users
void showWebTafseerDialog(
  BuildContext context, {
  required int surahNumber,
  required int verseNumber,
  required String tafseerEdition,
}) {
  showDialog(
    context: context,
    builder: (context) => WebTafseerDialog(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      tafseerEdition: tafseerEdition,
    ),
  );
}

class WebTafseerDialog extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String tafseerEdition;

  const WebTafseerDialog({
    Key? key,
    required this.surahNumber,
    required this.verseNumber,
    required this.tafseerEdition,
  }) : super(key: key);

  @override
  State<WebTafseerDialog> createState() => _WebTafseerDialogState();
}

class _WebTafseerDialogState extends State<WebTafseerDialog> {
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  "سورة ${getSurahNameArabic(widget.surahNumber)} - الآية ${widget.verseNumber}",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "Taha",
                    fontWeight: FontWeight.bold,
                    color: AppStyles.darkPurple,
                  ),
                ),
                Text(
                  tafseerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Taha",
                    color: AppStyles.txtFieldColor,
                  ),
                ),
              ],
            ),

            Divider(),

            // Verse text
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyles.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppStyles.lightPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                getVerse(widget.surahNumber, widget.verseNumber),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "QCF_BSML", // Using Quran font
                  color: AppStyles.black,
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
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
                                fontSize: 16,
                                fontFamily: "Taha",
                                color: AppStyles.black,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
