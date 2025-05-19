import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb import
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:software_graduation_project/utils/verification_badge.dart'; // Import for sheikh badges
import 'package:intl/intl.dart';
import 'package:software_graduation_project/screens/profile/edit_profile.dart';
import 'package:software_graduation_project/screens/profile/change_password.dart';
import 'package:software_graduation_project/screens/profile/request_sheikh_verification.dart'; // Add this import
import 'package:software_graduation_project/services/sheikh_verification_service.dart'; // Import the service
import 'dart:ui' as ui;

class AccountSettingsPage extends StatefulWidget {
  final User user;

  const AccountSettingsPage({Key? key, required this.user}) : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _navigateToEditProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _user),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        _user = updatedUser;
      });
      // Remove this line to prevent going back to profile page immediately
      // Navigator.pop(context, updatedUser);
    }
  }

  Future<void> _navigateToChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordPage(),
      ),
    );
  }

  // Add new navigation method for sheikh verification
  Future<void> _navigateToSheikhVerification() async {
    // Show loading indicator
    _showLoadingDialog('جاري التحقق من طلباتك السابقة...');

    try {
      final sheikhService = SheikhVerificationService();
      final hasPendingRequest =
          await sheikhService.hasExistingPendingVerification(_user.id);

      // Dismiss the loading dialog
      Navigator.pop(context);

      if (hasPendingRequest) {
        // Show message if there's already a pending request
        _showPendingRequestDialog();
      } else {
        // If no pending requests, navigate to the verification page
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestSheikhVerificationPage(user: _user),
          ),
        );
        // No need to update user state, as that's handled elsewhere
      }
    } catch (e) {
      // Dismiss the loading dialog in case of error
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التحقق من طلبات التوثيق السابقة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper dialog to show pending request message
  void _showPendingRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('طلب قيد المراجعة'),
          ],
        ),
        content: const Text(
          'لديك بالفعل طلب توثيق كشيخ قيد المراجعة. يرجى الانتظار حتى يتم مراجعة طلبك الحالي قبل تقديم طلب جديد.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // Helper dialog to show loading indicator
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppStyles.buttonColor),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // Helper method to format DateTime objects
  String _formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth > 768;

    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: const CustomAppBar(
          title: 'إعدادات الحساب', showAddButton: false, showBackButton: true),
      body: Center(
        // Center the content
        child: ConstrainedBox(
          // Add constraint box
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 1000 : double.infinity, // Wider for web layout
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use Row for web layout or Column for mobile
                if (isWideScreen)
                  // Web layout - cards side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Card
                      Expanded(
                        flex: 1,
                        child: _buildPersonalInfoCard(),
                      ),
                      const SizedBox(width: 16),
                      // Account Information Card
                      Expanded(
                        flex: 1,
                        child: _buildAccountInfoCard(),
                      ),
                    ],
                  )
                else
                  // Mobile layout - cards stacked
                  Column(
                    children: [
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 16),
                      _buildAccountInfoCard(),
                    ],
                  ),

                // Display Sheikh profile if exists
                if (_user.userType == 'sheikh' &&
                    _user.sheikhProfile != null) ...[
                  const SizedBox(height: 16),
                  _buildSheikhProfileCard(),
                ],

                const SizedBox(height: 24),

                // Edit Profile Button
                Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل الملف الشخصي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.txtFieldColor,
                          foregroundColor: AppStyles.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _navigateToChangePassword,
                        icon: const Icon(Icons.lock),
                        label: const Text('تغيير كلمة المرور'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.txtFieldColor,
                          foregroundColor: AppStyles.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),

                      // Add Sheikh Verification request button if user is not a sheikh
                      if (_user.userType != 'sheikh')
                        ElevatedButton.icon(
                          onPressed: _navigateToSheikhVerification,
                          icon: const Icon(Icons.verified_user),
                          label: const Text('طلب التحقق كشيخ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.purple,
                            foregroundColor: AppStyles.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Extract card building to separate methods
  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppStyles.txtFieldColor),
                const SizedBox(width: 8),
                const Text(
                  'المعلومات الشخصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('الاسم الكامل', _user.name,
                showBadge: _user.userType == 'sheikh'),
            _buildInfoRow('اسم المستخدم', _user.username),
            _buildInfoRow('رقم الهاتف',
                _user.phoneNumber.isNotEmpty ? _user.phoneNumber : 'غير متوفر'),
            _buildInfoRow(
                'الجنس',
                _translateGender(
                    _user.gender.isEmpty ? 'غير محدد' : _user.gender)),
            _buildInfoRow('تاريخ الميلاد', _formatDate(_user.birthDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: AppStyles.txtFieldColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الحساب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('البريد الإلكتروني', _user.email),
            _buildInfoRow('نوع المستخدم', _user.userType),
            _buildInfoRow('الحساب موثق', _user.isVerified ? 'نعم' : 'لا'),
            _buildInfoRow('تاريخ الإنشاء', _formatDate(_user.createdAt)),
            _buildInfoRow('آخر تسجيل دخول', _formatDate(_user.lastLogin)),
          ],
        ),
      ),
    );
  }

  Widget _buildSheikhProfileCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mosque, color: AppStyles.purple),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الشيخ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('المسجد', _user.sheikhProfile!.mosque),
            _buildInfoRow('الشهادة', _user.sheikhProfile!.certification),
            _buildInfoRow('التخصص', _user.sheikhProfile!.specialization),
            _buildInfoRow('التقييم', '${_user.sheikhProfile!.rating}'),
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value, {bool showBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textDirection:
                        ui.TextDirection.ltr, // Ensure emails display correctly
                  ),
                ),
                // Show verification badge if needed
                if (showBadge)
                  const VerificationBadge(
                    isVerifiedSheikh: true,
                    size: 14.0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to translate gender values
  String _translateGender(String gender) {
    if (gender.toLowerCase() == 'male') return 'ذكر';
    if (gender.toLowerCase() == 'female') return 'أنثى';
    return gender; // Return original if not matching
  }
}
