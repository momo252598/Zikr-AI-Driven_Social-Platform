import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart'; // Add import for CustomAppBar

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

  // All posts will be public by default
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
      // First create the post
      final postData = await _socialService.createPost(
        _contentController.text.trim(),
        _visibility,
      );

      final postId = postData['id'];

      // Then upload each image if any
      if (_selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري رفع الصور...')),
        );

        for (var image in _selectedImages) {
          await _socialService.addMediaToPost(
            postId,
            image,
            'image', // Always image for now
          );
        }
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
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: 'إنشاء منشور جديد',
        showAddButton: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.trans,
                foregroundColor: AppStyles.white,
                shape: const CircleBorder(),
                elevation: 0,
                padding: const EdgeInsets.all(12),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppStyles.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // Set RTL for Arabic
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card for post content
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content text field
                        TextField(
                          controller: _contentController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'بماذا تفكر؟',
                            hintStyle: TextStyle(
                              color: AppStyles.greyShaded600,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppStyles.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Image selection button
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppStyles.lightPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.photo_library_rounded,
                              color: AppStyles.lightPurple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'إضافة صور',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppStyles.darkPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Display selected images
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الصور المُختارة (${_selectedImages.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppStyles.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppStyles.lightPurple
                                            .withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
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
                                    top: 4,
                                    left: 4, // Position on left for RTL layout
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppStyles.darkPurple,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
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
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _isPosting
          ? Container(
              height: 4,
              width: double.infinity,
              child: LinearProgressIndicator(
                backgroundColor: AppStyles.whitePurple,
                valueColor: AlwaysStoppedAnimation<Color>(AppStyles.darkPurple),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
