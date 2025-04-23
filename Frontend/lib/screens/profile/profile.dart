import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:intl/intl.dart';
import 'package:software_graduation_project/screens/profile/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: $e')),
      );
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_user != null) {
      final updatedUser = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(user: _user!),
        ),
      );

      if (updatedUser != null) {
        setState(() {
          _user = updatedUser;
        });
      }
    }
  }

  // Helper method to format DateTime objects
  String _formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text(
                    'معلومات المستخدم غير متوفرة',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // App Bar with profile header
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: AppStyles.purple,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(_user!.name),
                        background: Container(
                          color: AppStyles.bgColor,
                          child: Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppStyles.txtFieldColor,
                              backgroundImage: _user!.profilePicture.isNotEmpty
                                  ? NetworkImage(_user!.profilePicture)
                                  : null,
                              child: _user!.profilePicture.isEmpty
                                  ? Text(
                                      _user!.name.isNotEmpty
                                          ? _user!.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                          fontSize: 40,
                                          color: AppStyles.bgColor),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _navigateToEditProfile,
                          tooltip: 'تعديل الملف الشخصي',
                        ),
                      ],
                    ),

                    // Profile content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personal Information Section
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            color: AppStyles.txtFieldColor),
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
                                    _buildInfoRow('الاسم الكامل', _user!.name),
                                    _buildInfoRow(
                                        'اسم المستخدم', _user!.username),
                                    _buildInfoRow(
                                        'رقم الهاتف',
                                        _user!.phoneNumber.isNotEmpty
                                            ? _user!.phoneNumber
                                            : 'غير متوفر'),
                                    _buildInfoRow(
                                        'الجنس', _user!.gender ?? 'غير محدد'),
                                    _buildInfoRow('تاريخ الميلاد',
                                        _formatDate(_user!.birthDate)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Account Information Section
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.account_circle,
                                            color: AppStyles.txtFieldColor),
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
                                    _buildInfoRow(
                                        'البريد الإلكتروني', _user!.email),
                                    _buildInfoRow(
                                        'نوع المستخدم', _user!.userType),
                                    _buildInfoRow('الحساب موثق',
                                        _user!.isVerified ? 'نعم' : 'لا'),
                                    _buildInfoRow('تاريخ الإنشاء',
                                        _formatDate(_user!.createdAt)),
                                    _buildInfoRow('آخر تسجيل دخول',
                                        _formatDate(_user!.lastLogin)),
                                  ],
                                ),
                              ),
                            ),

                            // Display Sheikh profile if exists
                            if (_user!.userType == 'sheikh' &&
                                _user!.sheikhProfile != null) ...[
                              const SizedBox(height: 16),
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.mosque,
                                              color: AppStyles.purple),
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
                                      _buildInfoRow('المسجد',
                                          _user!.sheikhProfile!.mosque),
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
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
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
