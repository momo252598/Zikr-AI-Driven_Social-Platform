import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Class to handle fetching and managing Tafseer data
class TafseerService {
  // In-memory cache to avoid repeated network requests
  static final Map<String, String> _tafseerCache = {};

  /// Available tafseer editions with their correct API slugs
  static const Map<String, String> tafseerEditions = {
    'ar-tafseer-al-saddi': 'تفسير السعدي',
    'ar-tafsir-ibn-kathir': 'تفسير ابن كثير',
    'ar-tafsir-al-tabari': 'تفسير الطبري',
    'ar-tafsir-muyassar': 'التفسير الميسر',
  };

  /// Fetches tafseer for a specific verse
  ///
  /// [editionSlug] - Identifier for the tafseer edition (e.g., 'muyassar')
  /// [surahNumber] - The surah number (1-114)
  /// [verseNumber] - The verse number within the surah
  ///
  /// Returns a Future<String> with the tafseer text or error message
  static Future<String> getTafseer({
    required String editionSlug,
    required int surahNumber,
    required int verseNumber,
  }) async {
    // Validate parameters
    if (surahNumber < 1 || surahNumber > 114) {
      return 'رقم السورة غير صحيح. يجب أن يكون بين 1 و 114.';
    }

    if (!tafseerEditions.containsKey(editionSlug)) {
      return 'نسخة التفسير غير متوفرة.';
    }

    // Create a cache key
    final cacheKey = '${editionSlug}_${surahNumber}_${verseNumber}';

    // Check if we have this tafseer cached
    if (_tafseerCache.containsKey(cacheKey)) {
      return _tafseerCache[cacheKey]!;
    }

    // Construct the API URL
    final url =
        'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/$editionSlug/$surahNumber/$verseNumber.json';

    try {
      // Make the API request
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('انتهت مهلة الطلب. تحقق من اتصالك بالإنترنت.'),
          );

      // Check for successful response
      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extract and cache the tafseer text
        final String tafseerText = data['text'] as String;
        _tafseerCache[cacheKey] = tafseerText;

        return tafseerText;
      } else {
        if (response.statusCode == 404) {
          return 'التفسير غير متوفر لهذه الآية.';
        }
        return 'حدث خطأ أثناء تحميل التفسير. (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error fetching tafseer: $e');
      return 'تعذر تحميل التفسير. ${e.toString()}';
    }
  }

  /// Clears the tafseer cache
  static void clearCache() {
    _tafseerCache.clear();
  }

  /// Gets the friendly name of a tafseer edition
  static String getTafseerName(String editionSlug) {
    return tafseerEditions[editionSlug] ?? 'تفسير غير معروف';
  }
}
