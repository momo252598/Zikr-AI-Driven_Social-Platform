import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add kIsWeb import
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:intl/intl.dart';
import 'package:software_graduation_project/screens/profile/edit_profile.dart';
import 'package:software_graduation_project/screens/profile/change_password.dart';
import 'package:software_graduation_project/screens/profile/account_settings.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:software_graduation_project/components/community/post.dart';
import 'package:software_graduation_project/services/chat_api_service.dart'; // Add chat service
import 'package:software_graduation_project/screens/chat/chat.dart'; // Use existing chat page
import 'dart:ui' as ui;

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

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final SocialService _socialService = SocialService();
  final ChatApiService _chatApiService = ChatApiService(); // Add chat service
  User? _user;
  List<dynamic>? _userPosts;
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isOwnProfile = true;
  bool _isStartingChat = false; // Add loading state for chat button

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
      // Get posts from API
      final posts = await _socialService.getPosts();

      // Filter posts to only show the selected user's posts
      final userPosts = posts.where((post) {
        // Check if post belongs to the user we're viewing
        return post['author_details'] != null &&
            _user != null &&
            post['author_details']['id'].toString() == _user!.id.toString();
      }).toList();

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

      // Navigate to existing ChatPage with the conversation data
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
                  // Add explicit <Widget> type to the list
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
                                    Text(
                                      _user!.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppStyles.purple,
                                      ),
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
                          ],
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
                            Text(
                              _user!.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppStyles.purple,
                              ),
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

                  // User's posts section with improved styling
                  SliverToBoxAdapter(
                    child: Center(
                      // Center the content
                      child: ConstrainedBox(
                        // Add constraint box
                        constraints: BoxConstraints(
                          maxWidth: kIsWeb
                              ? 700
                              : double.infinity, // Limit width on web
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppStyles.purple.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _isOwnProfile
                                      ? 'منشوراتي'
                                      : 'منشورات ${_user!.name}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppStyles.purple,
                                  ),
                                  textDirection: ui.TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Posts content with RTL direction and width constraint
                  _isLoadingPosts
                      ? SliverToBoxAdapter(
                          child: Center(
                              child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        )))
                      : _userPosts == null || _userPosts!.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
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
                                        _isOwnProfile
                                            ? 'ليس لديك أي منشورات بعد'
                                            : 'لا توجد منشورات لهذا المستخدم',
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
                              ),
                            )
                          : SliverToBoxAdapter(
                              child: Center(
                                // Center the ListView
                                child: ConstrainedBox(
                                  // Add constraint box
                                  constraints: BoxConstraints(
                                    maxWidth: kIsWeb
                                        ? 700
                                        : double.infinity, // Limit width on web
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: _userPosts!.length,
                                    itemBuilder: (context, index) {
                                      final post = _userPosts![index];
                                      return Directionality(
                                        textDirection: ui.TextDirection.rtl,
                                        child: PostCard(
                                          post: post,
                                          onLike: _likePost,
                                          onComment: _showCommentsSheet,
                                          onUserTap: _navigateToUserProfile,
                                          useRtlText: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                  // Extra space at the bottom
                  SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              );

    // Improved container for overlay mode
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
