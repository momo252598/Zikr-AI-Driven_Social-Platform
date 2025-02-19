import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart'; // new dependency
import 'package:flutter/foundation.dart'; // new import for compute()

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

// Modify _loadPages to rebuild widgets with interactive chunks.
Future<List<Widget>> _loadPages(BuildContext context) async {
  final String jsonString =
      await rootBundle.loadString('assets/utils/data-uthmani.json');
  const int maxWordsPerPage = 150;
  // Offload splitting work to a separate isolate.
  List<List<Map<String, dynamic>>> pagesChunks =
      await compute(computeSplitPages, {
    'jsonString': jsonString,
    'maxWordsPerPage': maxWordsPerPage,
  });

  // On main thread, rebuild widgets with RichText using desired style.
  List<Widget> pages = pagesChunks.map((pageChunks) {
    // Check if the first chunk is a header (surah title)
    if (pageChunks.first['surah'] == null) {
      final headerText = pageChunks.first['text'];
      List<InlineSpan> spans = pageChunks.skip(1).map((chunk) {
        return TextSpan(
          text: chunk['text'],
          recognizer: (chunk['surah'] != null && chunk['ayah'] != null)
              ? (LongPressGestureRecognizer()
                ..onLongPress = () {
                  print("Surah: ${chunk['surah']}, Ayah: ${chunk['ayah']}");
                })
              : null,
        );
      }).toList();
      return Padding(
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
                          ?.copyWith(fontSize: 24) ??
                      const TextStyle(fontSize: 24, color: Colors.black),
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
                          ?.copyWith(fontSize: 24) ??
                      const TextStyle(fontSize: 24, color: Colors.black),
                  children: spans,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Page without header chunk: build one RichText for all chunks.
      List<InlineSpan> spans = pageChunks.map((chunk) {
        return TextSpan(
          text: chunk['text'],
          recognizer: (chunk['surah'] != null && chunk['ayah'] != null)
              ? (LongPressGestureRecognizer()
                ..onLongPress = () {
                  print("Surah: ${chunk['surah']}, Ayah: ${chunk['ayah']}");
                })
              : null,
        );
      }).toList();
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 24) ??
                  const TextStyle(fontSize: 24, color: Colors.black),
              children: spans,
            ),
          ),
        ),
      );
    }
  }).toList();
  return pages;
}

class QuranPage extends StatelessWidget {
  const QuranPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
      future: _loadPages(context),
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
        final pagesWidgets = snapshot.data!;
        return Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              // replaced LayoutBuilder with SizedBox using MediaQuery for height
              height: MediaQuery.of(context).size.height,
              child: PageView.builder(
                itemCount: pagesWidgets.length,
                itemBuilder: (context, index) => pagesWidgets[index],
                // physics: ClampingScrollPhysics(),
              ),
            ),
          ),
        );
      },
    );
  }
}
