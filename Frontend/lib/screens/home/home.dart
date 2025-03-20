import 'package:flutter/material.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getUserData();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      // Navigate to login page
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      print('Error during logout: $e');
      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: $e')),
      );
    }
  }

  // Helper method to format DateTime objects
  String _formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      // appBar: AppBar(
      //   title: const Text('معلومات المستخدم'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: _handleLogout,
      //       tooltip: 'تسجيل الخروج',
      //     ),
      //   ],
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text(
                    'معلومات المستخدم غير متوفرة',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _user!.profilePicture.isNotEmpty
                                  ? NetworkImage(_user!.profilePicture)
                                  : null,
                              child: _user!.profilePicture.isEmpty
                                  ? Text(
                                      _user!.name.isNotEmpty
                                          ? _user!.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 40),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _user!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _user!.bio.isNotEmpty
                                  ? _user!.bio
                                  : 'لا توجد معلومات إضافية',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User details in a card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'معلومات الحساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow('معرف المستخدم', '${_user!.id}'),
                              _buildInfoRow('اسم المستخدم', _user!.username),
                              _buildInfoRow('البريد الالكتروني', _user!.email),
                              _buildInfoRow('نوع المستخدم', _user!.userType),
                              _buildInfoRow('الاسم الأول', _user!.firstName),
                              _buildInfoRow('الاسم الأخير', _user!.lastName),
                              _buildInfoRow('رقم الهاتف', _user!.phoneNumber),
                              _buildInfoRow(
                                  'تاريخ الميلاد',
                                  _user!.birthDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(_user!.birthDate!)
                                      : 'غير متوفر'),
                              _buildInfoRow(
                                  'الجنس', _user!.gender ?? 'غير محدد'),
                              _buildInfoRow('الحساب موثق',
                                  _user!.isVerified ? 'نعم' : 'لا'),
                              _buildInfoRow('تاريخ الإنشاء',
                                  _formatDate(_user!.createdAt)),
                              _buildInfoRow('تاريخ الانضمام',
                                  _formatDate(_user!.dateJoined)),
                              _buildInfoRow('آخر تسجيل دخول',
                                  _formatDate(_user!.lastLogin)),
                            ],
                          ),
                        ),
                      ),

                      // Display Sheikh profile if exists
                      if (_user!.sheikhProfile != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'معلومات الشيخ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                    'المسجد', _user!.sheikhProfile!.mosque),
                                _buildInfoRow('الشهادة',
                                    _user!.sheikhProfile!.certification),
                                _buildInfoRow('التخصص',
                                    _user!.sheikhProfile!.specialization),
                                _buildInfoRow('التقييم',
                                    '${_user!.sheikhProfile!.rating}'),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      // Logout button at the bottom
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('تسجيل الخروج'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
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
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
