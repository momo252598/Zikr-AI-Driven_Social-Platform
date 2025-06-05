import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SheikhVerificationService {
  late final String _baseUrl;

  SheikhVerificationService() {
    // Set base URL based on platform
    final host = kIsWeb ? '127.0.0.1' : '192.168.1.18';
    _baseUrl = 'http://$host:8000';
  }

  // Check if user has pending verification requests
  Future<bool> hasExistingPendingVerification(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/accounts/check-verification-status/$userId/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['has_pending_request'] ?? false;
      } else {
        print('Failed to check verification status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print("Error checking verification status: $e");
      return false;
    }
  }

  // Upload sheikh certification images
  Future<List<String>> uploadCertifications(List<XFile> images) async {
    List<String> uploadedUrls = [];

    try {
      // Upload each image
      for (var image in images) {
        var url = await uploadCertificationImage(image);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      return uploadedUrls;
    } catch (e) {
      print("Error uploading certifications: $e");
      throw Exception("Failed to upload certification images: $e");
    }
  } // Upload a single certification image

  Future<String?> uploadCertificationImage(XFile image) async {
    try {
      // Create multipart request
      var uri = Uri.parse('$_baseUrl/api/accounts/upload-certification/');
      var request = http.MultipartRequest('POST', uri);

      // During signup we don't have auth tokens yet, so just set the content type
      request.headers['Content-Type'] = 'multipart/form-data';

      // Read file as bytes
      final bytes = await image.readAsBytes();

      // Get file extension
      String extension = path.extension(image.path).toLowerCase();
      if (extension.isEmpty) {
        extension = '.jpg'; // Default to jpg if no extension
      }

      // Create a unique filename
      final fileName =
          'sheikh_cert_${DateTime.now().millisecondsSinceEpoch}$extension';
      // Add file to request
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType('image', extension.replaceFirst('.', '')),
      ));

      // Add debug info
      print('Uploading file: $fileName with size ${bytes.length} bytes');
      print('To URL: ${uri.toString()}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 201 && response.statusCode != 200) {
        print(
            'Image upload failed with status ${response.statusCode}: ${response.body}');
        print('Request URL: ${uri.toString()}');
        return null;
      }

      // Parse response
      print('Image upload successful with status ${response.statusCode}');
      final responseData = json.decode(response.body);
      return responseData['file_url'];
    } catch (e) {
      print("Error uploading certification image: $e");
      return null;
    }
  } // Submit sheikh certifications for verification

  Future<bool> submitSheikhCertifications(
      String email, List<String> certificationUrls) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/accounts/submit-sheikh-certifications/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
          'certification_urls': certificationUrls,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Successfully submitted certifications');
        return true;
      } else {
        print(
            'Certification submission failed with status ${response.statusCode}: ${response.body}');
        print(
            'Request URL: ${Uri.parse('$_baseUrl/api/accounts/submit-sheikh-certifications/')}');
        return false;
      }
    } catch (e) {
      print("Error submitting certifications: $e");
      return false;
    }
  }
}
