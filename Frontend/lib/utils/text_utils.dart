import 'dart:convert';

class TextUtils {
  /// Fixes encoding issues with Arabic text.
  /// This is particularly useful when:
  /// 1. Text comes from an API with incorrect encoding
  /// 2. Text is stored in a database with incorrect encoding
  static String fixArabicEncoding(String? text) {
    if (text == null || text.isEmpty) {
      return '';
    }

    try {
      // Debug original text
      print('Fixing Arabic encoding for: "$text"');

      // Check for common patterns that indicate incorrectly encoded Arabic
      if (text.contains('Ø') ||
          text.contains('Ù') ||
          text.contains('Ú') ||
          text.contains('Û') ||
          text.contains('Ý') ||
          text.contains('Þ') ||
          text.contains('á') ||
          text.contains('à') ||
          text.contains('æ') ||
          text.contains('ÿ') ||
          text.contains('ã')) {
        // Convert to Latin-1 bytes then decode as UTF-8
        List<int> latinBytes = [];
        for (int i = 0; i < text.length; i++) {
          latinBytes.add(text.codeUnitAt(i) & 0xFF);
        }
        String decoded = utf8.decode(latinBytes);

        print('First level decoding: "$decoded"');

        // Sometimes we need double decoding if text was double-encoded
        if (decoded.contains('Ø') ||
            decoded.contains('Ù') ||
            decoded.contains('Ú') ||
            decoded.contains('Ý') ||
            decoded.contains('Þ')) {
          List<int> doubleLatinBytes = [];
          for (int i = 0; i < decoded.length; i++) {
            doubleLatinBytes.add(decoded.codeUnitAt(i) & 0xFF);
          }
          String doubleDecoded = utf8.decode(doubleLatinBytes);
          print('Double decoding: "$doubleDecoded"');
          return doubleDecoded;
        }

        return decoded;
      }

      // If text looks like proper Arabic already (contains Arabic code points)
      if (_containsArabicCharacters(text)) {
        print('Text already contains Arabic: "$text"');
        return text; // Already proper Arabic
      }

      // Try another common encoding problem resolution
      try {
        String result = utf8.decode(latin1.encode(text));
        print('Alternative decoding: "$result"');

        // If result looks better (has Arabic chars), return it
        if (!_containsArabicCharacters(text) &&
            _containsArabicCharacters(result)) {
          return result;
        }

        return text; // Original looks better
      } catch (e) {
        // Fallback
        return text;
      }
    } catch (e) {
      print('Error fixing Arabic encoding: $e');
      return text; // Return original on failure
    }
  }

  /// Check if the text contains Arabic characters
  static bool _containsArabicCharacters(String text) {
    // Arabic Unicode range (approximate)
    RegExp arabicPattern =
        RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+');
    return arabicPattern.hasMatch(text);
  }

  /// Ensures text is properly encoded for sending to APIs
  static String prepareForSending(String? text) {
    if (text == null || text.isEmpty) {
      return '';
    }

    try {
      // First make sure text is properly decoded
      final decoded = fixArabicEncoding(text);

      // Encode it properly for sending
      return decoded;
    } catch (e) {
      print('Error preparing text for sending: $e');
      return text;
    }
  }
}
