import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/admin_service.dart';
import 'package:software_graduation_project/utils/text_utils.dart'; // Import TextUtils
import 'dart:ui' as ui;

class SheikhApprovePage extends StatefulWidget {
  const SheikhApprovePage({Key? key}) : super(key: key);

  @override
  _SheikhApprovePageState createState() => _SheikhApprovePageState();
}

class _SheikhApprovePageState extends State<SheikhApprovePage> {
  final AdminService _adminService = AdminService();
  List<dynamic> _pendingVerifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingVerifications();
  }

  Future<void> _fetchPendingVerifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pendingVerifications =
          await _adminService.getPendingSheikhVerifications();

      setState(() {
        _pendingVerifications = pendingVerifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            TextUtils.fixArabicEncoding('حدث خطأ أثناء جلب طلبات التوثيق: $e');
        _isLoading = false;
      });
    }
  }

  Future<void> _approveVerification(int verificationId, int index) async {
    final notes = await _showNotesDialog(
        context, TextUtils.fixArabicEncoding("إضافة ملاحظات (اختياري)"), true);

    if (notes == null) {
      // User canceled
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _adminService.approveSheikhVerification(
        verificationId,
        notes: notes.isEmpty ? null : notes,
      );

      if (success) {
        // Remove from the list
        setState(() {
          _pendingVerifications.removeAt(index);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  TextUtils.fixArabicEncoding('تم قبول طلب التوثيق بنجاح'),
                  style: TextStyle(fontFamily: 'Cairo'))),
        );
      } else {
        setState(() {
          _errorMessage = TextUtils.fixArabicEncoding('فشل قبول طلب التوثيق');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            TextUtils.fixArabicEncoding('حدث خطأ أثناء قبول طلب التوثيق: $e');
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectVerification(int verificationId, int index) async {
    final notes = await _showNotesDialog(
        context, TextUtils.fixArabicEncoding("سبب الرفض (مطلوب)"), false);

    if (notes == null || notes.isEmpty) {
      // User canceled or didn't provide reason
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(TextUtils.fixArabicEncoding('يجب إدخال سبب الرفض'),
                style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _adminService.rejectSheikhVerification(
        verificationId,
        notes: notes,
      );

      if (success) {
        // Remove from the list
        setState(() {
          _pendingVerifications.removeAt(index);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(TextUtils.fixArabicEncoding('تم رفض طلب التوثيق'),
                  style: TextStyle(fontFamily: 'Cairo'))),
        );
      } else {
        setState(() {
          _errorMessage = TextUtils.fixArabicEncoding('فشل رفض طلب التوثيق');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            TextUtils.fixArabicEncoding('حدث خطأ أثناء رفض طلب التوثيق: $e');
        _isLoading = false;
      });
    }
  }

  Future<String?> _showNotesDialog(
      BuildContext context, String title, bool isOptional) async {
    final TextEditingController controller = TextEditingController();
    final bool isWebView = MediaQuery.of(context).size.width > 900;

    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, style: TextStyle(fontFamily: 'Cairo')),
          content: Container(
            width: isWebView ? 400 : null,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: isOptional
                    ? TextUtils.fixArabicEncoding(
                        'اترك هذا الحقل فارغًا إذا لم تكن هناك ملاحظات')
                    : TextUtils.fixArabicEncoding('أدخل سبب رفض طلب التوثيق'),
                hintStyle: TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(TextUtils.fixArabicEncoding('إلغاء'),
                    style: TextStyle(
                        fontFamily: 'Cairo', color: AppStyles.black))),
            ElevatedButton(
              onPressed: () {
                if (!isOptional && controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            TextUtils.fixArabicEncoding('يجب إدخال سبب الرفض'),
                            style: TextStyle(fontFamily: 'Cairo'))),
                  );
                } else {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
              ),
              child: Text(TextUtils.fixArabicEncoding('موافق'),
                  style:
                      TextStyle(fontFamily: 'Cairo', color: AppStyles.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewCertificationImages(BuildContext context, List<dynamic> imageUrls) {
    final bool isWebView = MediaQuery.of(context).size.width > 900;

    showDialog(
        context: context,
        builder: (context) => Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Dialog(
                child: Container(
                  width: isWebView ? 700 : double.infinity,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TextUtils.fixArabicEncoding('صور الشهادات'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.darkPurple,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      TextUtils.fixArabicEncoding(
                                          'الصورة ${index + 1}:'),
                                      style: TextStyle(fontFamily: 'Cairo')),
                                  SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrls[index],
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      // On web view, limit the image height
                                      height: isWebView ? 400 : null,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 200,
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: Icon(Icons.broken_image,
                                                size: 64),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(TextUtils.fixArabicEncoding('إغلاق'),
                              style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TextUtils.fixArabicEncoding('طلبات توثيق الشيوخ'),
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppStyles.bgColor,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchPendingVerifications,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWebView = constraints.maxWidth > 900;

          Widget content = _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.red, fontFamily: 'Cairo'),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchPendingVerifications,
                            child: Text(
                                TextUtils.fixArabicEncoding('إعادة المحاولة'),
                                style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    )
                  : _pendingVerifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: AppStyles.lightPurple,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                TextUtils.fixArabicEncoding(
                                    'لا توجد طلبات توثيق معلقة'),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.darkPurple,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _pendingVerifications.length,
                          itemBuilder: (context, index) {
                            final verification = _pendingVerifications[index];

                            // Fix Arabic encoding for user data
                            final firstName = TextUtils.fixArabicEncoding(
                                verification['first_name'] ?? '');
                            final lastName = TextUtils.fixArabicEncoding(
                                verification['last_name'] ?? '');
                            final username = TextUtils.fixArabicEncoding(
                                verification['username'] ?? '');
                            final email = verification['email'] ?? '';

                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User information section
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppStyles.lightPurple
                                              .withOpacity(0.3),
                                          radius: 24,
                                          child: Text(
                                            (firstName.isNotEmpty
                                                    ? firstName[0]
                                                    : ' ')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: AppStyles.darkPurple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$firstName $lastName',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppStyles.darkPurple,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                username,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    Divider(height: 24),

                                    // Submission date
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 8),
                                        Text(
                                          TextUtils.fixArabicEncoding(
                                              'تاريخ الطلب: ${DateTime.parse(verification['submitted_at']).toLocal().toString().split(' ')[0]}'),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),

                                    // Number of certification images
                                    Row(
                                      children: [
                                        Icon(Icons.photo_library,
                                            size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 8),
                                        Text(
                                          TextUtils.fixArabicEncoding(
                                              'عدد الصور: ${(verification['certification_urls'] as List).length}'),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16),

                                    // Action buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _viewCertificationImages(
                                              context,
                                              verification[
                                                  'certification_urls'],
                                            ),
                                            icon: Icon(Icons.visibility),
                                            label: Text(
                                                TextUtils.fixArabicEncoding(
                                                    'عرض الشهادات'),
                                                style: TextStyle(
                                                    fontFamily: 'Cairo')),
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _approveVerification(
                                              verification['id'],
                                              index,
                                            ),
                                            icon: Icon(Icons.check),
                                            label: Text(
                                                TextUtils.fixArabicEncoding(
                                                    'قبول'),
                                                style: TextStyle(
                                                    fontFamily: 'Cairo')),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _rejectVerification(
                                              verification['id'],
                                              index,
                                            ),
                                            icon: Icon(Icons.close),
                                            label: Text(
                                                TextUtils.fixArabicEncoding(
                                                    'رفض'),
                                                style: TextStyle(
                                                    fontFamily: 'Cairo')),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

          // If it's a web view, center the content with max width constraint
          if (isWebView) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              ),
            );
          }

          // If it's mobile, return the content with original directionality
          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: content,
          );
        },
      ),
    );
  }
}
