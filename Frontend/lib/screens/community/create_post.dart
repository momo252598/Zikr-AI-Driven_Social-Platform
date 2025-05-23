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
  bool _isLoadingTags = true;
  List<dynamic> _tags = [];
  List<dynamic> _filteredTags = [];
  List<int> _selectedTagIds = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  final List<String> _categories = [
    'religious',
    'practice',
    'lifestyle',
    'contemporary',
    'community',
    'suggestions',
    'other'
  ];

  // All posts will be public by default
  String _visibility = 'public';

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      setState(() {
        _isLoadingTags = true;
      });

      final tags = await _socialService.getTags();

      if (!mounted) return;

      setState(() {
        _tags = tags;
        _filteredTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      print('Error loading tags: $e');
      if (!mounted) return;

      setState(() {
        _isLoadingTags = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل الوسوم: $e')),
      );
    }
  }

  void _filterTags() {
    setState(() {
      _filteredTags = _tags.where((tag) {
        bool matchesCategory =
            _selectedCategory.isEmpty || tag['category'] == _selectedCategory;
        bool matchesSearch = _searchQuery.isEmpty ||
            tag['name'].toString().contains(_searchQuery) ||
            (tag['display_name_ar'] != null &&
                tag['display_name_ar'].toString().contains(_searchQuery));
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _toggleTagSelection(dynamic tag) {
    final int tagId = tag['id'];
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        await _pickImageWeb();
      } else {
        // Mobile implementation
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

  Future<void> _pickImageWeb() async {
    final ImagePicker picker = ImagePicker();
    // On web, we'll use pickMultiImage directly without permission checking
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      print('Error picking images on web: $e');
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
        tagIds: _selectedTagIds,
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

                // Image selection button - moved above tags
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
                                    left: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
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
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Tags Section
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
                          'إختر الوسوم المناسبة لمنشورك',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppStyles.darkPurple,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Search bar for tags
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'بحث عن وسوم...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppStyles.lightPurple),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color:
                                      AppStyles.lightPurple.withOpacity(0.5)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _filterTags();
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Category filter
                        Text(
                          'تصفية حسب الفئات',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppStyles.darkPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // "All" option
                            FilterChip(
                              label: Text('الكل'),
                              selected: _selectedCategory.isEmpty,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = '';
                                  _filterTags();
                                });
                              },
                              backgroundColor:
                                  AppStyles.lightPurple.withOpacity(0.2),
                              selectedColor:
                                  AppStyles.lightPurple.withOpacity(0.7),
                              checkmarkColor: AppStyles.white,
                              labelStyle: TextStyle(
                                color: _selectedCategory.isEmpty
                                    ? AppStyles.white
                                    : AppStyles.black,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),

                            // Category options
                            ...List.generate(
                              _categories.length,
                              (index) {
                                final category = _categories[index];
                                final String label =
                                    _getCategoryDisplayName(category);

                                return FilterChip(
                                  label: Text(label),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory =
                                          selected ? category : '';
                                      _filterTags();
                                    });
                                  },
                                  backgroundColor:
                                      AppStyles.lightPurple.withOpacity(0.2),
                                  selectedColor:
                                      AppStyles.lightPurple.withOpacity(0.7),
                                  checkmarkColor: AppStyles.white,
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == category
                                        ? AppStyles.white
                                        : AppStyles.black,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Selected tags display
                        if (_selectedTagIds.isNotEmpty) ...[
                          Text(
                            'الوسوم المختارة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppStyles.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _tags
                                .where((tag) =>
                                    _selectedTagIds.contains(tag['id']))
                                .map<Widget>((tag) {
                              return Chip(
                                label: Text(
                                  tag['display_name_ar'] ?? tag['name'],
                                  style: TextStyle(
                                    color: AppStyles.darkPurple,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    AppStyles.lightPurple.withOpacity(0.2),
                                deleteIconColor: AppStyles.darkPurple,
                                onDeleted: () => _toggleTagSelection(tag),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Tags list
                        _isLoadingTags
                            ? Center(child: CircularProgressIndicator())
                            : _filteredTags.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'لا توجد وسوم متطابقة مع بحثك',
                                        style: TextStyle(
                                          color: AppStyles.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    children: _filteredTags.map<Widget>((tag) {
                                      final bool isSelected =
                                          _selectedTagIds.contains(tag['id']);
                                      return ActionChip(
                                        label: Text(
                                          tag['display_name_ar'] ?? tag['name'],
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppStyles.white
                                                : AppStyles.darkPurple,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: isSelected
                                            ? AppStyles.darkPurple
                                            : AppStyles.lightPurple
                                                .withOpacity(0.2),
                                        onPressed: () =>
                                            _toggleTagSelection(tag),
                                      );
                                    }).toList(),
                                  ),
                      ],
                    ),
                  ),
                ),

                // ...existing code... (remove the old image selection section that was below tags)
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

  // Helper method to convert category code to display name
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'religious':
        return 'معرفة دينية';
      case 'practice':
        return 'عبادات يومية';
      case 'lifestyle':
        return 'حياة إسلامية';
      case 'contemporary':
        return 'قضايا معاصرة';
      case 'community':
        return 'المجتمع';
      case 'suggestions':
        return 'المقترحات';
      case 'other':
        return 'أخرى';
      default:
        return category;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
