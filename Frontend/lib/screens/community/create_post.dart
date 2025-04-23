import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import 'package:device_info_plus/device_info_plus.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final _imagePicker = ImagePicker();
  final _socialService = SocialService();
  bool _isPosting = false;
  String _visibility = 'public';

  Future<void> _pickImage() async {
    try {
      // Request permissions first
      if (await _requestPermissions()) {
        final ImagePicker picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage();

        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى السماح بالوصول إلى الصور للمتابعة'),
          ),
        );
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار الصور: ${e.toString()}'),
        ),
      );
    }
  }

  // Add this helper method to request permissions
  Future<bool> _requestPermissions() async {
    // For Android 13+ (API level 33+)
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
    }

    // For older Android versions and iOS
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن نشر منشور فارغ')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // First, create the post
      final postData = await _socialService.createPost(
        _contentController.text.trim(),
        _visibility,
      );

      final postId = postData['id'];

      // Then upload each image if any
      for (var image in _selectedImages) {
        // Upload to a storage service and get URL
        final fileUrl = await _socialService.uploadImage(image);

        // Add media to post
        await _socialService.addMediaToPost(
          postId,
          fileUrl,
          'image',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر المنشور بنجاح')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Same UI implementation as before...
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء منشور جديد'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('نشر'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text field for post content
              TextField(
                controller: _contentController,
                textDirection: TextDirection.rtl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'بماذا تفكر؟',
                  hintTextDirection: TextDirection.rtl,
                  border: InputBorder.none,
                ),
              ),

              // Display selected images
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'الصور المُختارة:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppStyles.grey.withOpacity(0.5)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedImages[index].path,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Image.file(
                                    File(_selectedImages[index].path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppStyles.darkPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Post visibility selector
              Row(
                children: [
                  const Text('إظهار المنشور لـ:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _visibility,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _visibility = newValue;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'public',
                        child: Text('الجميع'),
                      ),
                      DropdownMenuItem(
                        value: 'followers',
                        child: Text('المتابعين فقط'),
                      ),
                      DropdownMenuItem(
                        value: 'private',
                        child: Text('أنا فقط'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Add image button
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('إضافة صورة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.lightPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
