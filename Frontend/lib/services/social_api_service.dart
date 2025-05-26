import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import './api_service.dart';
import '../models/user.dart';
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType

class SocialService {
  final ApiService _apiService = ApiService(); // Get all posts with pagination
  Future<List<dynamic>> getPosts({int? page, int? tagId}) async {
    try {
      String endpoint = '/social/posts/';
      List<String> params = [];

      if (page != null) {
        params.add('page=$page');
      }

      if (tagId != null) {
        params.add('tag=$tagId');
      }

      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }

      print("Fetching posts from endpoint: $endpoint");

      final response = await _apiService.get(endpoint);
      print("Response type: ${response.runtimeType}");

      // Handle different response structures safely
      if (response is Map && response.containsKey('results')) {
        return response['results'] as List<dynamic>? ?? [];
      } else if (response is List) {
        return response;
      } else {
        print("Unexpected response format: $response");
        return [];
      }
    } catch (e) {
      print("Error in getPosts: $e");
      return []; // Return empty list instead of crashing
    }
  }

  // Get a single post by ID
  Future<Map<String, dynamic>> getPost(int postId) async {
    final response = await _apiService.get('/social/posts/$postId/');
    return response;
  }

  // Create a new post
  Future<Map<String, dynamic>> createPost(String content, String visibility,
      {List<int> tagIds = const []}) async {
    final data = {
      'content': content,
      'visibility': visibility,
      'tag_ids': tagIds,
    };

    final response = await _apiService.post('/social/posts/', data);
    return response;
  }

  // Get all available tags
  Future<List<dynamic>> getTags({String? category, String? search}) async {
    try {
      String endpoint = '/social/tags/';
      List<String> params = [];

      if (category != null) {
        params.add('category=$category');
      }

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }

      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }

      final response = await _apiService.get(endpoint);

      if (response is List) {
        return response;
      } else if (response is Map && response.containsKey('results')) {
        return response['results'] as List<dynamic>? ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print("Error in getTags: $e");
      return [];
    }
  }

  // Like or unlike a post
  Future<bool> togglePostLike(dynamic postId) async {
    final int postIdInt = postId is int ? postId : int.parse(postId.toString());
    final response =
        await _apiService.post('/social/posts/$postIdInt/like/', {});
    return response['status'] == 'liked';
  }

  // Delete a post
  Future<bool> deletePost(dynamic postId) async {
    try {
      final int postIdInt =
          postId is int ? postId : int.parse(postId.toString());
      await _apiService.delete('/social/posts/$postIdInt/');
      return true; // If no exception is thrown, deletion was successful
    } catch (e) {
      print("Error deleting post: $e");
      return false;
    }
  }

  // Add media to a post
  Future<Map<String, dynamic>> addMediaToPost(
      dynamic postId, XFile image, String fileType) async {
    try {
      final int postIdInt =
          postId is int ? postId : int.parse(postId.toString());

      // Create multipart request
      var uri = Uri.parse(
          '${_apiService.baseUrl}/social/posts/$postIdInt/add_media/');
      var request = http.MultipartRequest('POST', uri);

      // Add authorization headers
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Read file as bytes
      final bytes = await image.readAsBytes();

      // Add file to request
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
        contentType: MediaType('image', 'jpeg'), // Adjust based on file type
      ));

      // Add file type
      request.fields['file_type'] = fileType;

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('Failed to upload image: ${response.body}');
      }

      // Parse response
      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Failed to upload image: $e");
    }
  }

  // Get comments for a post
  Future<List<dynamic>> getPostComments(dynamic postId,
      {bool? parentOnly}) async {
    try {
      // Ensure postId is converted to int
      final int postIdInt =
          postId is int ? postId : int.parse(postId.toString());
      String endpoint = '/social/comments/?post=$postIdInt';

      if (parentOnly == true) {
        endpoint += '&parent=null';
      }

      final response = await _apiService.get(endpoint);

      // Debug the response
      print("Comments response type: ${response.runtimeType}");
      if (response is Map && response.containsKey('results')) {
        return response['results'] as List<dynamic>? ?? [];
      } else if (response is List) {
        return response;
      } else {
        print("Unexpected comments response format: $response");
        return [];
      }
    } catch (e) {
      print("Error in getPostComments: $e");
      return []; // Return empty list on error
    }
  }

  // Create a new comment
  Future<Map<String, dynamic>> createComment(dynamic postId, String content,
      {dynamic parentId}) async {
    final int postIdInt = postId is int ? postId : int.parse(postId.toString());
    final data = {
      'post': postIdInt,
      'content': content,
    };

    if (parentId != null) {
      final int parentIdInt =
          parentId is int ? parentId : int.parse(parentId.toString());
      data['parent'] = parentIdInt;
    }

    final response = await _apiService.post('/social/comments/', data);
    return response; // This should be the created comment with all details
  }

  // Like or unlike a comment
  Future<bool> toggleCommentLike(dynamic commentId) async {
    try {
      final int commentIdInt =
          commentId is int ? commentId : int.parse(commentId.toString());
      final response =
          await _apiService.post('/social/comments/$commentIdInt/like/', {});
      return response['status'] == 'liked';
    } catch (e) {
      print("Error liking comment: $e");
      return false;
    }
  }

  // Helper method to upload an image to a storage service
  Future<String> uploadImage(XFile image) async {
    try {
      // In a real app, you would upload to a server
      // This is a simplified example that just returns the local path

      // For a real implementation, use an upload service like Firebase Storage
      // Get file bytes
      final bytes = await image.readAsBytes();

      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real implementation, you would upload bytes here
      // Example:
      // final ref = firebase_storage.FirebaseStorage.instance.ref().child('uploads/${DateTime.now().millisecondsSinceEpoch}.jpg');
      // await ref.putData(bytes);
      // return await ref.getDownloadURL();

      // For now, just return a dummy URL
      return "https://example.com/uploads/${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.jpg";
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<User> getUserProfileById(String userId) async {
    try {
      // Make the API call to fetch user profile
      final dynamic responseData =
          await _apiService.get('/accounts/user-profile/$userId/');

      // Debug the response data
      print('User profile data: $responseData');

      // Convert from Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> data = {};
      if (responseData is Map) {
        responseData.forEach((key, value) {
          data[key.toString()] = value;
        });
      } else {
        throw Exception('Unexpected response format: $responseData');
      }

      // Convert the response data to a User object
      return User.fromJson(data);
    } catch (e) {
      print('Error in getUserProfileById: $e');
      rethrow; // Make sure to rethrow so it can be caught in the UI
    }
  }
}
