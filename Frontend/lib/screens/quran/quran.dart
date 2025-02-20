import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart'; // new dependency
import 'package:flutter/foundation.dart';
import '../../base/res/styles/app_styles.dart'; // new import for compute()

// Helper function: converts English digits to Arabic display digits.
String convertToArabic(String number) {
  const Map<String, String> arabicDigits = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };
  return number.split('').map((d) => arabicDigits[d] ?? d).join();
}

// Updated computeSplitPages to return pages as List<List<Map<String,dynamic>>>
List<List<Map<String, dynamic>>> computeSplitPages(
    Map<String, dynamic> params) {
  String jsonString = params['jsonString'];
  int maxWordsPerPage = params['maxWordsPerPage'];
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  final List<dynamic> surahs = jsonData['quran']['surahs'];
  List<List<Map<String, dynamic>>> pages = [];
  for (var surah in surahs) {
    String header = "سورة ${surah['num']}: ${surah['name']}";
    int headerCount = header.trim().split(RegExp(r'\s+')).length;
    // Initialize first page with header chunk (no gesture for header)
    List<Map<String, dynamic>> currentPageChunks = [
      {'text': header + " ", 'surah': null, 'ayah': null}
    ];
    int currentWords = headerCount;
    for (var ayah in surah['ayahs']) {
      // Add surah info to each ayah
      ayah['surah'] = surah['num'];
      String ayahNumStr =
          ayah['num'].toString(); // skipping converting for isolate simplicity
      String fullText = "${ayah['text']} {${ayahNumStr}} ";
      List<String> words = fullText.trim().split(RegExp(r'\s+'));
      int wordIndex = 0;
      while (wordIndex < words.length) {
        int remaining = maxWordsPerPage - currentWords;
        if (remaining <= 0) {
          pages.add(currentPageChunks);
          currentPageChunks = [];
          currentWords = 0;
          remaining = maxWordsPerPage;
        }
        int available = words.length - wordIndex;
        int takeCount = available < remaining ? available : remaining;
        String chunk =
            words.sublist(wordIndex, wordIndex + takeCount).join(" ") + " ";
        // Include gesture metadata for this chunk
        currentPageChunks.add({
          'text': chunk,
          'surah': ayah['surah'],
          'ayah': ayah['num'],
        });
        currentWords += takeCount;
        wordIndex += takeCount;
      }
    }
    if (currentPageChunks.isNotEmpty) pages.add(currentPageChunks);
  }
  return pages;
}

// Modify _loadPages to remove the context parameter and fetch pages only once.
Future<List<List<Map<String, dynamic>>>> _loadPages() async {
  final String jsonString =
      await rootBundle.loadString('assets/utils/data-uthmani.json');
  const int maxWordsPerPage = 150;
  List<List<Map<String, dynamic>>> pagesChunks =
      await compute(computeSplitPages, {
    'jsonString': jsonString,
    'maxWordsPerPage': maxWordsPerPage,
  });
  return pagesChunks;
}

// Helper function to build a page from its chunks using current highlight state.
Widget _buildPage(
    BuildContext context,
    List<Map<String, dynamic>> pageChunks,
    Map<String, dynamic>? selectedAyah,
    Function(Map<String, dynamic>?) onChunkLongPress) {
  // Build spans with conditional background for highlighted chunks.
  List<InlineSpan> buildSpans(List<Map<String, dynamic>> chunks) {
    return chunks.map((chunk) {
      bool isHighlighted = selectedAyah != null &&
          chunk['surah'] != null &&
          chunk['ayah'] != null &&
          selectedAyah['surah'] == chunk['surah'] &&
          selectedAyah['ayah'] == chunk['ayah'];

      return TextSpan(
        text: chunk['text'],
        style:
            isHighlighted ? TextStyle(backgroundColor: AppStyles.grey) : null,
        recognizer: (chunk['surah'] != null && chunk['ayah'] != null)
            ? (LongPressGestureRecognizer()
              ..onLongPress = () {
                print("Surah: ${chunk['surah']}, Ayah: ${chunk['ayah']}");
                onChunkLongPress({
                  'surah': chunk['surah'],
                  'ayah': chunk['ayah'],
                });
              })
            : null,
      );
    }).toList();
  }

  // If page starts with header chunk.
  if (pageChunks.first['surah'] == null) {
    final headerText = pageChunks.first['text'];
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onChunkLongPress(null),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  headerText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 24, fontFamily: 'othman') ??
                      const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontFamily: 'othman'),
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 24, fontFamily: 'othman') ??
                      const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontFamily: 'othman'),
                  children: buildSpans(pageChunks.skip(1).toList()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    // Page without header
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onChunkLongPress(null),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 24, fontFamily: 'othman') ??
                  const TextStyle(
                      fontSize: 24, color: Colors.black, fontFamily: 'othman'),
              children: buildSpans(pageChunks),
            ),
          ),
        ),
      ),
    );
  }
}

// Convert QuranPage to a StatefulWidget to manage highlight state and cache loaded pages.
class QuranPage extends StatefulWidget {
  const QuranPage({Key? key}) : super(key: key);

  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  Map<String, dynamic>? selectedAyah;
  late Future<List<List<Map<String, dynamic>>>> pagesFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future so that pages are loaded only once.
    pagesFuture = _loadPages();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: pagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("Error loading Quran text")),
          );
        }
        final pagesData = snapshot.data!;
        return Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: PageView.builder(
                itemCount: pagesData.length,
                itemBuilder: (context, index) {
                  return _buildPage(
                    context,
                    pagesData[index],
                    selectedAyah,
                    (newHighlight) {
                      setState(() {
                        selectedAyah = newHighlight;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
