import 'dart:convert';
import 'package:http/http.dart' as http;

class RagService {
  static const String _apiKey = 't7PH3qjn.tT6zHZc1KnWlVI2TkyEOBFr00iVmJyjn';
  static const String _baseUrl =
      'https://payload.vextapp.com/hook/W1IVUJCU6Z/catch/';

  // You can customize the channel token or make it configurable
  static const String _channelToken = 'default';

  // Session storage for chatbot messages (persists during app session)
  static List<Map<String, dynamic>> _sessionMessages = [];

  /// Get session messages
  List<Map<String, dynamic>> getSessionMessages() {
    return List.from(_sessionMessages);
  }

  /// Add message to session storage
  void addMessageToSession(Map<String, dynamic> message) {
    _sessionMessages.add(message);
  }

  /// Clear session messages (useful for testing or if needed)
  void clearSessionMessages() {
    _sessionMessages.clear();
  }

  /// Initialize with welcome message if session is empty
  void initializeSessionIfEmpty() {
    if (_sessionMessages.isEmpty) {
      _sessionMessages.add({
        'content':
            'السلام عليكم! أنا مساعد ذكي للإجابة على أسئلتكم الدينية. كيف يمكنني مساعدتك اليوم؟',
        'isBot': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Sends a query to the RAG chatbot and returns the response
  Future<Map<String, dynamic>> sendQuery(String query) async {
    try {
      final url = Uri.parse('$_baseUrl$_channelToken');

      final headers = {
        'Content-Type': 'application/json',
        'Apikey': 'Api-Key $_apiKey',
      };

      final body = json.encode({
        'payload': query,
        'env': 'dev',
      });

      print('Sending RAG query: $query');
      print('URL: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('RAG API Response Status: ${response.statusCode}');
      print('RAG API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'text': responseData['text'] ?? 'تم استلام رد فارغ',
          'citation': responseData['citation'],
          'request_id': responseData['request_id'],
        };
      } else {
        print('RAG API Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'فشل في الاتصال بالخدمة. رمز الخطأ: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('RAG Service Exception: $e');
      return {
        'success': false,
        'error': 'حدث خطأ في الاتصال: $e',
      };
    }
  }

  /// Test method to verify the service is working
  Future<bool> testConnection() async {
    try {
      final result = await sendQuery('مرحبا');
      return result['success'] == true;
    } catch (e) {
      print('RAG Service Test Failed: $e');
      return false;
    }
  }
}
