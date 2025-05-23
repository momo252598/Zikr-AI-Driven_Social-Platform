import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../base/res/styles/app_styles.dart';
import '../../services/sheikh_verification_service.dart';

class SignUpSheikhVerify extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onNext;
  final VoidCallback? onSkip;

  const SignUpSheikhVerify({
    Key? key,
    required this.userData,
    required this.onNext,
    this.onSkip,
  }) : super(key: key);

  @override
  _SignUpSheikhVerifyState createState() => _SignUpSheikhVerifyState();
}

class _SignUpSheikhVerifyState extends State<SignUpSheikhVerify> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  final List<XFile> _selectedImages = [];
  final _imagePicker = ImagePicker();
  final _sheikhService = SheikhVerificationService();

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        await _pickImageWeb();
      } else {
        // Mobile implementation
        final List<XFile> images = await _imagePicker.pickMultiImage();

        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء اختيار الصور: ${e.toString()}';
      });
    }
  }

  Future<void> _pickImageWeb() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      print('Error picking image on web: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء اختيار الصور: ${e.toString()}';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التقاط الصورة: $e';
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitCertifications() async {
    if (_selectedImages.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء اختيار صور الشهادات أولاً';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload the certification images
      final uploadedUrls =
          await _sheikhService.uploadCertifications(_selectedImages);

      if (uploadedUrls.isEmpty) {
        throw Exception('فشل في رفع الصور');
      }

      // Submit the URLs to the backend
      final success = await _sheikhService.submitSheikhCertifications(
        widget.userData['email'],
        uploadedUrls,
      );

      if (success) {
        // Continue to verification step
        widget.onNext();
      } else {
        setState(() {
          _errorMessage =
              'فشل في حفظ بيانات الشهادات. الرجاء المحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء رفع الشهادات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with verification icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppStyles.darkPurple,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'تحقق من هوية الشيخ',
                  style: TextStyle(
                    color: AppStyles.darkPurple,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Information message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppStyles.whitePurple,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppStyles.lightPurple.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppStyles.darkPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لتأكيد هويتك كشيخ، يرجى تقديم صور للشهادات أو الوثائق ذات الصلة',
                          style: TextStyle(
                            color: AppStyles.darkPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.face, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'مطلوب: صورة واحدة على الأقل تحتوي على وجهك مع الشهادة في نفس الصورة',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم مراجعة الوثائق خلال 24-48 ساعة',
                    style: TextStyle(
                      color: AppStyles.greyShaded600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Error message if any
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppStyles.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppStyles.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppStyles.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppStyles.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    icon: Icons.photo_library,
                    label: 'اختر من المعرض',
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildButton(
                    icon: Icons.camera_alt,
                    label: 'التقاط صورة',
                    onPressed: _takePhoto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preview of selected images
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'الصور المُختارة (${_selectedImages.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppStyles.darkPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppStyles.whitePurple.withOpacity(0.5),
                ),
                child: GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                            border: Border.all(color: AppStyles.lightPurple),
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
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppStyles.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: AppStyles.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 30),

            // Submit button
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppStyles.buttonColor),
                    const SizedBox(height: 16),
                    Text(
                      'جاري رفع الشهادات...',
                      style: TextStyle(
                        color: AppStyles.darkPurple,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [AppStyles.buttonColor, AppStyles.darkPurple],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.buttonColor.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _submitCertifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'رفع الشهادات والمتابعة',
                    style: TextStyle(
                      color: AppStyles.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Skip button with warning
            Column(
              children: [
                Text(
                  'إذا تخطيت هذه الخطوة، سيتم تسجيلك كمستخدم عادي',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: widget.onSkip ?? widget.onNext,
                  child: Text(
                    'تخطي التحقق والمتابعة كمستخدم عادي',
                    style: TextStyle(
                      color: AppStyles.darkPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppStyles.buttonColor.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppStyles.white),
        label: Text(
          label,
          style: TextStyle(color: AppStyles.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
