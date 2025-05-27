import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb import
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:software_graduation_project/utils/verification_badge.dart'; // Import for sheikh badges
import 'package:intl/intl.dart';
import 'package:software_graduation_project/screens/profile/edit_profile.dart';
import 'package:software_graduation_project/screens/profile/change_password.dart';
import 'package:software_graduation_project/screens/profile/account_settings.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:software_graduation_project/components/community/post.dart';
import 'package:software_graduation_project/services/chat_api_service.dart'; // Add chat service
import 'package:software_graduation_project/screens/chat/chat.dart'; // Use existing chat page
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart'; // Use existing chat page
import 'dart:ui' as ui;
// import 'package:software_graduation_project/layouts/browser_chat_layout.dart'; // Import for web chat layout

class ProfilePage extends StatefulWidget {
  final String? userId; // Optional parameter to view other users' profiles
  final ScrollController? scrollController; // For when used in overlay mode
  final bool isOverlay; // Flag to indicate if shown as overlay

  const ProfilePage({
    Key? key,
    this.userId,
    this.scrollController,
    this.isOverlay = false,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Add SingleTickerProviderStateMixin
  final AuthService _authService = AuthService();
  final SocialService _socialService = SocialService();
  final ChatApiService _chatApiService = ChatApiService();
  User? _user;
  List<dynamic>? _userPosts;
  List<dynamic>? _likedPosts; // Add liked posts list
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isLoadingLikedPosts = false; // Add loading state for liked posts
  bool _isOwnProfile = true;
  bool _isStartingChat = false; // Add loading state for chat button
  int? _currentUserId; // Track current user ID for delete functionality

  // Add tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize tab controller
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose tab controller
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current user ID for delete functionality
      _currentUserId = await _authService.getCurrentUserId();

      User? user;

      if (widget.userId == null) {
        // Loading own profile - keep existing code
        user = await _authService.getUserData();
        _isOwnProfile = true;
      } else {
        // Get current user to check if this is our own profile
        var currentUser = await _authService.getUserData();

        if (widget.userId != currentUser?.id.toString()) {
          // Fetch other user's profile using the new API
          try {
            user = await _socialService.getUserProfileById(widget.userId!);
            _isOwnProfile = false;
            print('Successfully loaded user profile: ${user.name}');
          } catch (e) {
            print('Error fetching user profile: $e');

            // Show a more specific error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل تحميل الملف الشخصي: $e')),
            );

            // If API fails, show an error
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          // If the userId matches the current user, show current user profile
          user = currentUser;
          _isOwnProfile = true;
        }
      }

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });

      // After user data is loaded, fetch their posts
      _loadUserPosts();
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }
  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });
    try {
      if (_user == null) {
        setState(() {
          _isLoadingPosts = false;
        });
        return;
      }

      // Get posts from API filtered by the specific user
      final postsResponse = await _socialService.getPosts(authorId: _user!.id);
      final userPosts = postsResponse['results'] as List<dynamic>;

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _userPosts = userPosts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isLoadingPosts = false;
      });
      print('Error loading user posts: $e');
    }
  }

  // Add method to load liked posts
  Future<void> _loadLikedPosts() async {
    // Only load liked posts for own profile
    if (!_isOwnProfile) return;

    setState(() {
      _isLoadingLikedPosts = true;
    });

    try {
      final likedPosts = await _socialService.getLikedPosts();

      if (!mounted) return;

      setState(() {
        _likedPosts = likedPosts;
        _isLoadingLikedPosts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLikedPosts = false;
      });
      print('Error loading liked posts: $e');
    }
  }

  // Add like post functionality
  Future<void> _likePost(dynamic postId) async {
    try {
      final isLiked = await _socialService.togglePostLike(postId);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        final postIndex = _userPosts!
            .indexWhere((p) => p['id'].toString() == postId.toString());
        if (postIndex >= 0) {
          _userPosts![postIndex]['is_liked'] = isLiked;
          _userPosts![postIndex]['likes_count'] = isLiked
              ? (_userPosts![postIndex]['likes_count'] ?? 0) + 1
              : (_userPosts![postIndex]['likes_count'] ?? 1) - 1;
        }
      });
    } catch (e) {
      // Only show snackbar if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  // Delete post functionality
  Future<void> _deletePost(dynamic post) async {
    try {
      final postId = post['id'];
      await _socialService.deletePost(postId);

      if (!mounted) return;

      setState(() {
        _userPosts!.removeWhere((p) => p['id'].toString() == postId.toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف المنشور بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف المنشور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show comments sheet - now using the shared utility method
  void _showCommentsSheet(BuildContext context, dynamic post) {
    PostUtils.showCommentsSheet(context, post, (newCommentCount) {
      // Update post's comment count without full reload
      setState(() {
        final postIndex = _userPosts!
            .indexWhere((p) => p['id'].toString() == post['id'].toString());
        if (postIndex >= 0) {
          _userPosts![postIndex]['comments_count'] = newCommentCount;
        }
      });
    });
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تسجيل الخروج',
            textAlign: TextAlign.right,
            textDirection: ui.TextDirection.rtl,
          ),
          content: Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج؟',
            textAlign: TextAlign.right,
            textDirection: ui.TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('تسجيل الخروج'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        );
      },
    );

    // If user didn't confirm or dialog was dismissed, don't proceed
    if (confirm != true) return;

    try {
      await _authService.logout();
      // Navigate to login page - use /login instead of /
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الخروج: $e')),
      );
    }
  }

  void _navigateToAccountSettings() {
    if (_user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccountSettingsPage(user: _user!),
        ),
      ).then((updatedUser) {
        if (updatedUser != null) {
          setState(() {
            _user = updatedUser;
          });
        }
      });
    }
  }

  // Helper method to format DateTime objects - keep this as it's used for other dates
  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير متوفر';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return 'غير متوفر';
    }
  }

  // Updated method to handle starting or opening a conversation
  Future<void> _startOrOpenChat() async {
    if (_user == null) return;

    setState(() {
      _isStartingChat = true;
    });

    try {
      // Use username or email instead of ID as the API expects
      String recipientIdentifier;
      if (_user!.username != null && _user!.username.isNotEmpty) {
        recipientIdentifier = _user!.username;
      } else if (_user!.email != null && _user!.email.isNotEmpty) {
        recipientIdentifier = _user!.email;
      } else {
        // Fallback to a field that the API recognizes - try username_slug if available
        recipientIdentifier = _user!.username ?? _user!.id.toString();
      }

      print('Starting chat with recipient: $recipientIdentifier');

      final result = await _chatApiService.startConversation(
        recipientIdentifier,
        '', // Empty initial message
      );

      if (!mounted) return;

      setState(() {
        _isStartingChat = false;
      });

      // Extract the conversation ID
      int? conversationId;
      if (result.containsKey('conversation') && result['conversation'] is Map) {
        conversationId = result['conversation']['id'];
      } else {
        conversationId = result['id'] ?? result['conversation_id'];
      }

      if (conversationId == null) {
        throw Exception('Could not determine conversation ID from response');
      }

      // --- WEB: Use BrowserChatLayout and select the chat ---
      if (kIsWeb) {
        // Pop the overlay/modal if present
        Navigator.of(context).pop();
        // Push the browser chat layout and select the conversation
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BrowserChatLayoutInitialSelectedChat(
              initialChatId: conversationId!,
            ),
          ),
        );
        return;
      }

      // --- MOBILE: Keep existing behavior ---
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: conversationId!,
            onMessageUpdate: (String message) {
              // Optional callback if you need to update anything
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isStartingChat = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في بدء المحادثة: $e')),
      );
      print('Error starting conversation: $e');
    }
  }

  // Add a navigation method for user profiles
  void _navigateToUserProfile(dynamic userDetails) {
    if (userDetails == null || !(userDetails is Map)) return;

    String? userId = userDetails['id']?.toString();
    if (userId == null) return;

    // Navigate to the profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userId: userId,
        ),
      ),
    );
  }

  // Add tab button builder similar to azkar screen
  Widget _buildTabButtons() {
    // Only show tabs for own profile
    if (!_isOwnProfile) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.lightPurple.withOpacity(0.1),
            AppStyles.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppStyles.purple.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppStyles.lightPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final isSelected = _tabController.index == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppStyles.darkPurple,
                                  AppStyles.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppStyles.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'المنشورات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? AppStyles.white : AppStyles.purple,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabController.animateTo(1);
                  // Load liked posts when tab is selected
                  if (_likedPosts == null && !_isLoadingLikedPosts) {
                    _loadLikedPosts();
                  }
                },
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final isSelected = _tabController.index == 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppStyles.darkPurple,
                                  AppStyles.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppStyles.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'المنشورات المعجب بها',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? AppStyles.white : AppStyles.purple,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add method to build posts list for each tab
  Widget _buildPostsList(
      List<dynamic>? posts, bool isLoading, String emptyMessage) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (posts == null || posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.post_add,
                size: 64,
                color: AppStyles.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: AppStyles.grey,
                ),
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: kIsWeb ? 700 : double.infinity,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: PostCard(
                post: post,
                onLike: _likePost,
                onComment: _showCommentsSheet,
                onUserTap: _navigateToUserProfile,
                onDelete: _isOwnProfile ? _deletePost : null,
                currentUserId: _currentUserId,
                useRtlText: true,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _user == null
            ? const Center(
                child: Text(
                  'معلومات المستخدم غير متوفرة',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              )
            : CustomScrollView(
                controller: widget.scrollController,
                slivers: <Widget>[
                  // Enhanced app bar for overlay mode - removed the name from title
                  widget.isOverlay
                      ? SliverAppBar(
                          floating: true,
                          snap: true,
                          backgroundColor: AppStyles.txtFieldColor,
                          elevation: 2,
                          automaticallyImplyLeading: false,
                          // Removed name from title
                          title: Text(
                            'الملف الشخصي',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          centerTitle: true,
                          actions: [
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        )
                      : SliverAppBar(
                          expandedHeight: 200.0,
                          floating: false,
                          pinned: true,
                          backgroundColor: AppStyles.trans,
                          flexibleSpace: FlexibleSpaceBar(
                            title: null,
                            background: Container(
                              color: AppStyles.bgColor,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppStyles.txtFieldColor,
                                      backgroundImage: _user!
                                              .profilePicture.isNotEmpty
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
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _user!.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppStyles.purple,
                                          ),
                                        ),
                                        // Show verification badge for sheikh users
                                        if (_user!.userType == 'sheikh')
                                          const VerificationBadge(
                                            isVerifiedSheikh: true,
                                            size: 16.0,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Show settings and logout buttons only if it's the user's own profile
                          actions: [
                            if (_isOwnProfile) ...[
                              IconButton(
                                icon: const Icon(Icons.logout),
                                onPressed: _handleLogout,
                                tooltip: 'تسجيل الخروج',
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: _navigateToAccountSettings,
                                tooltip: 'إعدادات الحساب',
                              ),
                            ],
                          ], // <-- FIXED: changed ',' to ']'
                        ),

                  // Simplified profile header for overlay mode
                  if (widget.isOverlay)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: AppStyles.txtFieldColor,
                                backgroundImage:
                                    _user!.profilePicture.isNotEmpty
                                        ? NetworkImage(_user!.profilePicture)
                                        : null,
                                child: _user!.profilePicture.isEmpty
                                    ? Text(
                                        _user!.name.isNotEmpty
                                            ? _user!.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            fontSize: 36,
                                            color: AppStyles.bgColor),
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _user!.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppStyles.purple,
                                  ),
                                ),
                                // Show verification badge for sheikh users
                                if (_user!.userType == 'sheikh')
                                  const VerificationBadge(
                                    isVerifiedSheikh: true,
                                    size: 16.0,
                                  ),
                              ],
                            ),
                            // Add chat button only when viewing other profiles in overlay mode
                            if (!_isOwnProfile && widget.isOverlay)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ElevatedButton(
                                  onPressed:
                                      _isStartingChat ? null : _startOrOpenChat,
                                  child: _isStartingChat
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(Icons.chat),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppStyles.txtFieldColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    shape: CircleBorder(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Add tab buttons
                  SliverToBoxAdapter(
                    child: _buildTabButtons(),
                  ),

                  // Posts content with TabBarView
                  SliverFillRemaining(
                    child: _isOwnProfile
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              // User's posts tab
                              _buildPostsList(_userPosts, _isLoadingPosts,
                                  'ليس لديك أي منشورات بعد'),
                              // Liked posts tab
                              _buildPostsList(_likedPosts, _isLoadingLikedPosts,
                                  'لم تعجب بأي منشورات بعد'),
                            ],
                          )
                        : _buildPostsList(_userPosts, _isLoadingPosts,
                            'لا توجد منشورات لهذا المستخدم'),
                  ),
                ],
              );

    // Return the appropriate widget based on overlay mode
    return widget.isOverlay
        ? Material(
            color: AppStyles.bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            child: content,
          )
        : Scaffold(
            backgroundColor: AppStyles.bgColor,
            body: content,
          );
  }
}
