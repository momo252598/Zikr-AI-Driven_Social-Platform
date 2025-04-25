import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/models/user.dart';
import 'package:intl/intl.dart';
import 'package:software_graduation_project/screens/profile/edit_profile.dart';
import 'package:software_graduation_project/screens/profile/change_password.dart';
import 'package:software_graduation_project/screens/profile/account_settings.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
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
  User? _user;
  List<dynamic>? _userPosts;
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isOwnProfile = true; // Default to true, will be set properly in init

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
        // Loading own profile
        user = await _authService.getUserData();
        _isOwnProfile = true;
      } else {
        // FIX HERE: We need to fetch the other user's data
        // For now we'll simulate it by altering the current user's data
        // In a real implementation, you would call a proper API endpoint
        var currentUser = await _authService.getUserData();

        // This is a temporary solution to demonstrate another user's profile
        // In production, implement a proper getUserById API call
        if (widget.userId != currentUser?.id.toString()) {
          // Clone the user and modify some details to simulate another user
          user = User(
            id: int.tryParse(widget.userId!) ?? 0,
            username: "user${widget.userId}",
            email: "user${widget.userId}@example.com",
            name: "User ${widget.userId}",
            phoneNumber: "",
            profilePicture: "",
            userType: "user",
            isVerified: false,
            gender: currentUser?.gender ?? "",
            birthDate: currentUser?.birthDate != null
                ? DateTime.tryParse(currentUser!.birthDate.toString())
                : null,
            createdAt: currentUser?.createdAt != null
                ? DateTime.parse(currentUser!.createdAt.toString())
                : DateTime.now(),
            lastLogin: currentUser?.lastLogin != null
                ? DateTime.parse(currentUser!.lastLogin.toString())
                : DateTime.now(),
            sheikhProfile: null,
          );
          _isOwnProfile = false;
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
      // TODO: Replace with actual API call to get user's posts
      // For now we'll just use the general posts endpoint
      final posts = await _socialService.getPosts();

      // In a real implementation, you would filter posts by user ID
      // But for now, let's simulate it with the existing posts
      final userPosts = posts
          .where((post) =>
              post['author_details'] != null &&
              _user != null &&
              post['author_details']['username'] == _user!.username)
          .toList();

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

  // Show comments bottom sheet
  void _showCommentsSheet(BuildContext context, dynamic post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyles.trans,
      builder: (context) => CommentsSheet(
        post: post,
        onCommentAdded: (newCommentCount) {
          // Update post's comment count without full reload
          setState(() {
            final postIndex = _userPosts!
                .indexWhere((p) => p['id'].toString() == post['id'].toString());
            if (postIndex >= 0) {
              _userPosts![postIndex]['comments_count'] = newCommentCount;
            }
          });
        },
      ),
    );
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

  // Helper method to format DateTime objects
  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير متوفر';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return 'غير متوفر';
    }
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
                controller: widget
                    .scrollController, // Use provided controller if available
                slivers: [
                  // Modify the app bar for overlay mode
                  widget.isOverlay
                      ? SliverAppBar(
                          floating: true,
                          snap: true,
                          title: Text(_user?.name ?? 'الملف الشخصي'),
                          backgroundColor: AppStyles.purple,
                          automaticallyImplyLeading: false,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.close),
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
                          // Show settings button only if it's the user's own profile
                          actions: [
                            if (_isOwnProfile)
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: _navigateToAccountSettings,
                                tooltip: 'إعدادات الحساب',
                              ),
                          ],
                        ),

                  // Add profile header for overlay mode
                  if (widget.isOverlay)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
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
                                          fontSize: 30,
                                          color: AppStyles.bgColor),
                                    )
                                  : null,
                            ),
                            SizedBox(height: 8),
                            Text(
                              _user!.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppStyles.purple,
                              ),
                            ),
                            Text(
                              _user!.username,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppStyles.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // User's posts section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOwnProfile
                                ? 'منشوراتي'
                                : 'منشورات ${_user!.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),

                  // Posts content
                  _isLoadingPosts
                      ? SliverToBoxAdapter(
                          child: Center(
                              child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          )),
                        )
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
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = _userPosts![index];
                                  return _buildPostCard(post);
                                },
                                childCount: _userPosts!.length,
                              ),
                            ),

                  // Logout button at the bottom (only for own profile)
                  if (_isOwnProfile)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
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
                      ),
                    ),

                  // Extra space at the bottom
                  SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              );

    // Return the content in a Scaffold only if not in overlay mode
    return widget.isOverlay
        ? content
        : Scaffold(
            backgroundColor: AppStyles.bgColor,
            body: content,
          );
  }

  Widget _buildPostCard(dynamic post) {
    try {
      // Safely extract values with proper type conversions
      final postId = post['id'];
      final bool isLiked = post['is_liked'] == true;
      final int likesCount = post['likes_count'] is int
          ? post['likes_count']
          : (int.tryParse(post['likes_count']?.toString() ?? '0') ?? 0);
      final int commentsCount = post['comments_count'] is int
          ? post['comments_count']
          : (int.tryParse(post['comments_count']?.toString() ?? '0') ?? 0);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header (user and date)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppStyles.lightPurple.withOpacity(0.2),
                    child: Text(
                      (post['author_details'] != null &&
                              post['author_details']['username'] != null)
                          ? post['author_details']['username']
                              .toString()
                              .substring(0, 1)
                          : "?",
                      style: TextStyle(
                        color: AppStyles.darkPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (post['author_details'] != null)
                              ? post['author_details']['username']
                                      ?.toString() ??
                                  "Unknown User"
                              : "Unknown User",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(post['created_at']),
                          style: TextStyle(
                            color: AppStyles.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Post text content
            if (post['content'] != null &&
                post['content'].toString().isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  post['content'].toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            // Post images
            if (post['media'] != null &&
                post['media'] is List &&
                (post['media'] as List).isNotEmpty)
              _buildImageGallery(_extractMediaUrls(post['media'])),

            // Post actions (like, comment) - Updated to be functional
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => _likePost(postId),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppStyles.lightPurple,
                    ),
                    label: Text(
                      likesCount.toString(),
                      style: TextStyle(
                          color: isLiked ? Colors.red : AppStyles.lightPurple),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _showCommentsSheet(context, post),
                    icon: Icon(
                      Icons.comment_outlined,
                      color: AppStyles.darkPurple,
                    ),
                    label: Text(
                      commentsCount.toString(),
                      style: TextStyle(color: AppStyles.darkPurple),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error rendering post card: $e");
      // Return a fallback UI when there's an error
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "حدث خطأ في عرض المنشور: $e",
            style: TextStyle(color: AppStyles.red),
          ),
        ),
      );
    }
  }

  // Helper method to safely extract media URLs
  List<String> _extractMediaUrls(dynamic mediaList) {
    try {
      if (mediaList == null || !(mediaList is List)) return [];

      return List<String>.from((mediaList as List).map((m) {
        if (m == null || !(m is Map) || m['file_url'] == null) return "";
        return m['file_url'].toString();
      }).where((url) => url.isNotEmpty));
    } catch (e) {
      print("Error extracting media URLs: $e");
      return [];
    }
  }

  Widget _buildImageGallery(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Helper function to handle image display with error handling
    Widget displayImage(String imageUrl) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Image error: $error");
          return Container(
            color: AppStyles.grey.withOpacity(0.2),
            child: Center(
              child: Icon(Icons.image_not_supported,
                  color: AppStyles.darkPurple.withOpacity(0.5), size: 40),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    if (imageUrls.length == 1) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        width: double.infinity,
        child: displayImage(imageUrls[0].toString()),
      );
    } else {
      return Container(
        height: 300,
        width: double.infinity,
        child: PageView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return displayImage(imageUrls[index].toString());
          },
        ),
      );
    }
  }
}

// Add CommentsSheet widget to the profile page
class CommentsSheet extends StatefulWidget {
  final dynamic post;
  final Function(int) onCommentAdded;

  const CommentsSheet(
      {Key? key, required this.post, required this.onCommentAdded})
      : super(key: key);

  @override
  _CommentsSheetState createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final SocialService _socialService = SocialService();
  List<dynamic>? _comments;
  bool _isLoading = true;
  String? _error;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post['comments_count'] ?? 0;
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final postId = widget.post['id'];

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final comments =
          await _socialService.getPostComments(postId, parentOnly: true);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment(dynamic postId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      // Convert string ID to integer if needed
      final int postIdInt =
          postId is int ? postId : int.parse(postId.toString());

      // Dismiss keyboard immediately
      FocusScope.of(context).unfocus();

      // Show inline loading indicator while adding comment
      final comment = _commentController.text.trim();
      _commentController.clear();

      // Optimistic UI update - add temporary comment to list
      final tempComment = {
        'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
        'content': comment,
        'author_details': {
          'username': 'You'
        }, // Will be replaced with real data
        'created_at': DateTime.now().toIso8601String(),
        'likes_count': 0,
        'is_liked': false,
        'is_adding': true, // Flag to show loading state
      };

      setState(() {
        _comments = [...(_comments ?? []), tempComment];
        _commentCount++;
      });

      // Notify parent widget to update count
      widget.onCommentAdded(_commentCount);

      // Actually send to API
      final result = await _socialService.createComment(postIdInt, comment);

      // Remove temp comment and add real one
      setState(() {
        _comments!.removeWhere((c) => c['id'] == tempComment['id']);
        _comments!.add(result);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> _likeComment(dynamic commentId) async {
    try {
      final int commentIdInt =
          commentId is int ? commentId : int.parse(commentId.toString());
      final isLiked = await _socialService.toggleCommentLike(commentIdInt);

      setState(() {
        final commentIndex = _comments!
            .indexWhere((c) => c['id'].toString() == commentId.toString());
        if (commentIndex >= 0) {
          _comments![commentIndex]['is_liked'] = isLiked;
          _comments![commentIndex]['likes_count'] = isLiked
              ? (_comments![commentIndex]['likes_count'] ?? 0) + 1
              : (_comments![commentIndex]['likes_count'] ?? 1) - 1;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Map<String, dynamic> _safeComment(dynamic comment) {
    if (comment is Map<String, dynamic>) {
      return comment;
    }
    if (comment is Map) {
      return Map<String, dynamic>.from(comment);
    }
    return {};
  }

  Widget _buildCommentItem(dynamic comment, {required Function onLike}) {
    try {
      final safeComment = _safeComment(comment);
      final bool isLiked = safeComment['is_liked'] == true;
      final bool isAdding = safeComment['is_adding'] == true;

      final int likesCount = safeComment['likes_count'] is int
          ? safeComment['likes_count']
          : (int.tryParse(safeComment['likes_count']?.toString() ?? '0') ?? 0);

      final authorDetails = safeComment['author_details'] is Map
          ? safeComment['author_details']
          : {};

      final String username =
          authorDetails != null && authorDetails['username'] != null
              ? authorDetails['username'].toString()
              : "Unknown";

      final String firstLetter = username.isNotEmpty ? username[0] : "?";
      final String commentContent = safeComment['content']?.toString() ?? "";
      final String createdAt = safeComment['created_at']?.toString() ??
          DateTime.now().toIso8601String();

      if (isAdding) {
        // Show a special style for comments being added
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppStyles.lightPurple.withOpacity(0.2),
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: AppStyles.darkPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'يتم الإرسال...',
                          style: TextStyle(
                            color: AppStyles.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commentContent,
                      style: TextStyle(
                        color: AppStyles.grey.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Regular comment display
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppStyles.lightPurple.withOpacity(0.2),
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: AppStyles.darkPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: AppStyles.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(commentContent),

                  // Like button for comments
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => onLike(),
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : AppStyles.grey,
                          size: 16,
                        ),
                        label: Text(
                          likesCount.toString(),
                          style: TextStyle(
                            color: isLiked ? Colors.red : AppStyles.grey,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("حدث خطأ في عرض التعليق: $e",
            style: TextStyle(color: AppStyles.red)),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'اليوم';
      } else if (difference.inDays == 1) {
        return 'الأمس';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} أيام';
      } else {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: AppStyles.greyShaded300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'التعليقات ($_commentCount)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'فشل في تحميل التعليقات: $_error',
                              style: TextStyle(color: AppStyles.red),
                              textAlign: TextAlign.center,
                            ),
                            ElevatedButton(
                              onPressed: _loadComments,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _comments == null || _comments!.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد تعليقات بعد',
                              style: TextStyle(
                                color: AppStyles.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _comments!.length,
                            itemBuilder: (context, index) {
                              final comment = _comments![index];
                              return _buildCommentItem(
                                comment,
                                onLike: () => _likeComment(comment['id']),
                              );
                            },
                          ),
          ),
          // Add comment section
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              left: 16,
              right: 16,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: AppStyles.white,
              boxShadow: [
                BoxShadow(
                  color: AppStyles.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textDirection:
                        ui.TextDirection.rtl, // Changed from RTL to rtl
                    decoration: InputDecoration(
                      hintText: 'أضف تعليقًا...',
                      hintTextDirection: ui.TextDirection.rtl,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppStyles.greyShaded100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final comment = _commentController.text.trim();
                    if (comment.isNotEmpty) {
                      _addComment(widget.post['id'], comment);
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppStyles.darkPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: AppStyles.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
