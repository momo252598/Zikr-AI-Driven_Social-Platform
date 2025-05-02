import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:software_graduation_project/models/quran_models.dart';
import 'package:software_graduation_project/services/api_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';

class QuranService {
  final ApiService _apiService = ApiService();

  // Get all bookmarks for the current user
  Future<List<QuranBookmark>> getBookmarks() async {
    try {
      final response = await _apiService.get('/quran/bookmarks/');

      if (response is List) {
        // Properly cast each map item to Map<String, dynamic> before creating QuranBookmark objects
        return response.map((item) {
          // Explicitly convert the dynamic map to Map<String, dynamic>
          Map<String, dynamic> bookmarkMap = Map<String, dynamic>.from(item);
          return QuranBookmark.fromJson(bookmarkMap);
        }).toList();
      } else {
        throw Exception('Unexpected response format from bookmarks API');
      }
    } catch (e) {
      print('Error getting bookmarks: $e');
      throw e;
    }
  }

  // Add a bookmark
  Future<QuranBookmark> addBookmark(int surah, int verse, int page,
      {String? notes}) async {
    try {
      // Create the data map properly
      final Map<String, dynamic> data = {
        'surah': surah,
        'verse': verse,
        'page': page,
      };

      // Only add notes if it's not null (and notes is already a String)
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      final response = await _apiService.post('/quran/bookmarks/', data);
      return QuranBookmark.fromJson(response);
    } catch (e) {
      print('Error adding bookmark: $e');
      throw e;
    }
  }

  // Remove a bookmark
  Future<void> removeBookmark(int surah, int verse) async {
    try {
      // First, get all bookmarks to find the ID
      final bookmarks = await getBookmarks();
      final bookmark = bookmarks.firstWhere(
        (b) => b.surah == surah && b.verse == verse,
        orElse: () => throw Exception('Bookmark not found'),
      );

      await _apiService.delete('/quran/bookmarks/${bookmark.id}/delete/');
    } catch (e) {
      print('Error removing bookmark: $e');
      throw e;
    }
  }

  // Get the last read page
  Future<int> getLastReadPage() async {
    try {
      final response = await _apiService.get('/quran/reading-progress/');

      return response['last_page'] ?? 1;
    } catch (e) {
      print('Error getting last read page: $e');
      // Default to page 1 if there's an error
      return 1;
    }
  }

  // Update the last read page
  Future<void> updateLastReadPage(int page) async {
    try {
      await _apiService.post('/quran/reading-progress/', {'last_page': page});
    } catch (e) {
      print('Error updating last read page: $e');
      throw e;
    }
  }
}
