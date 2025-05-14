import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/profile/profile.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'dart:ui' as ui;

/// A reusable widget for displaying social posts
class PostCard extends StatelessWidget {
  final dynamic post;
  final Function(dynamic) onLike;
  final Function(BuildContext, dynamic) onComment;
  final Function(dynamic)? onUserTap; // Optional callback for username tap
  final bool useRtlText; // Parameter for RTL text direction

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onUserTap,
    this.useRtlText = true, // Default to RTL for Arabic content
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

      final authorDetails = post['author_details'];

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header (user and date)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Make avatar clickable with the same onUserTap callback
                    GestureDetector(
                      onTap: onUserTap != null
                          ? () => onUserTap!(authorDetails)
                          : null,
                      child: CircleAvatar(
                        backgroundColor: AppStyles.lightPurple.withOpacity(0.2),
                        child: Text(
                          (authorDetails != null &&
                                  authorDetails['username'] != null)
                              ? authorDetails['username']
                                  .toString()
                                  .substring(0, 1)
                              : "?",
                          style: TextStyle(
                            color: AppStyles.darkPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Make username clickable
                          GestureDetector(
                            onTap: onUserTap != null
                                ? () => onUserTap!(authorDetails)
                                : null,
                            child: Text(
                              (authorDetails != null)
                                  ? _getDisplayName(authorDetails)
                                  : "مستخدم غير معروف",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            PostUtils.formatDate(post['created_at'] ??
                                DateTime.now().toIso8601String()),
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

              // Post text content with explicit RTL settings
              if (post['content'] != null &&
                  post['content'].toString().isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    post['content'].toString(),
                    style: const TextStyle(fontSize: 16),
                    textDirection: ui.TextDirection.rtl, // Explicit RTL
                    textAlign: TextAlign.right, // Force right alignment
                  ),
                ),

              // Post images
              if (post['media'] != null &&
                  post['media'] is List &&
                  (post['media'] as List).isNotEmpty)
                _buildImageGallery(PostUtils.extractMediaUrls(post['media'])),

              // Post actions (like, comment)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => onLike(postId),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : AppStyles.lightPurple,
                      ),
                      label: Text(
                        likesCount.toString(),
                        style: TextStyle(
                            color:
                                isLiked ? Colors.red : AppStyles.lightPurple),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => onComment(context, post),
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

  Widget _buildImageGallery(List<dynamic> media) {
    if (media.isEmpty) {
      return SizedBox.shrink();
    }

    // Extract image URLs from media objects
    List<String> imageUrls = [];
    for (var item in media) {
      if (item is Map &&
          item.containsKey('file_url') &&
          item['file_type'] == 'image') {
        imageUrls.add(item['file_url']);
      }
    }

    if (imageUrls.isEmpty) {
      return SizedBox.shrink();
    }

    // Display a single image or grid of images
    if (imageUrls.length == 1) {
      return Builder(
        builder: (context) => Container(
          margin: EdgeInsets.only(top: 8),
          constraints: BoxConstraints(maxHeight: 300),
          width: double.infinity,
          child: GestureDetector(
            onTap: () => _openPhotoViewer(context, imageUrls, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      // Grid layout for multiple images (up to 4 visible)
      return Container(
        margin: EdgeInsets.only(top: 8),
        child: _buildPhotoGrid(imageUrls),
      );
    }
  }

  // Helper method to build a photo grid
  Widget _buildPhotoGrid(List<String> imageUrls) {
    final int totalImages = imageUrls.length;
    final int imagesToShow = totalImages > 4 ? 4 : totalImages;

    // Calculate aspect ratio based on number of images
    double aspectRatio = totalImages == 2 ? 2 : 1;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(totalImages),
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: imagesToShow,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(context, imageUrls, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
                // Show overlay with count for the 4th image if there are more than 4 images
                if (index == 3 && totalImages > 4)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        "+${totalImages - 4}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper to determine grid cross-axis count based on number of images
  int _getGridCrossAxisCount(int imageCount) {
    if (imageCount == 1) return 1;
    if (imageCount == 2) return 2;
    return 2; // For 3 or more images, use a 2x2 grid
  }

  // Open full-screen photo viewer
  void _openPhotoViewer(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerPage(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Helper method to get display name from author details
  String _getDisplayName(dynamic authorDetails) {
    // Try to use first and last name
    final String firstName = authorDetails['first_name']?.toString() ?? '';
    final String lastName = authorDetails['last_name']?.toString() ?? '';

    // If both are available, combine them
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }

    // Use name if available (some APIs might return a combined name)
    final String name = authorDetails['name']?.toString() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    // Fallback to username
    return authorDetails['username']?.toString() ?? "مستخدم غير معروف";
  }
}

/// A reusable bottom sheet for displaying and adding comments
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

  // Helper method to get display name from author details
  String _getDisplayName(dynamic authorDetails) {
    // Try to use first and last name
    final String firstName = authorDetails['first_name']?.toString() ?? '';
    final String lastName = authorDetails['last_name']?.toString() ?? '';

    // If both are available, combine them
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }

    // Use name if available (some APIs might return a combined name)
    final String name = authorDetails['name']?.toString() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    // Fallback to username
    return authorDetails['username']?.toString() ?? "مستخدم غير معروف";
  }

// Navigate to user profile when username is clicked - updated to use overlay
  void _navigateToUserProfile(dynamic authorDetails) {
    if (authorDetails != null && authorDetails['id'] != null) {
      // Show profile overlay instead of navigating to a new screen
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize:
              0.92, // Almost full screen but keeps app bar visible
          minChildSize: 0.5, // Allow drag to half screen
          maxChildSize: 0.92,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: AppStyles.bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: ProfilePage(
                userId: authorDetails['id'].toString(),
                scrollController: scrollController,
                isOverlay: true,
              ),
            ),
          ),
        ),
      );
    }
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

      // Replace username with display name using the helper method
      final String displayName = _getDisplayName(authorDetails);

      // Still use the first letter of the username for avatar
      final String firstLetter = displayName.isNotEmpty ? displayName[0] : "?";
      final String commentContent = safeComment['content']?.toString() ?? "";
      final String createdAt = safeComment['created_at']?.toString() ??
          DateTime.now().toIso8601String();

      if (isAdding) {
        // Comment being added with clickable avatar and name
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            textDirection: ui.TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToUserProfile(authorDetails),
                child: CircleAvatar(
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: ui.TextDirection.rtl,
                  children: [
                    Row(
                      textDirection: ui.TextDirection.rtl,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToUserProfile(authorDetails),
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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
                      textDirection: ui.TextDirection.rtl,
                      textAlign: TextAlign.right,
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

      // Regular comment display with clickable avatar and name
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          textDirection: ui.TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _navigateToUserProfile(authorDetails),
              child: CircleAvatar(
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: ui.TextDirection.rtl,
                children: [
                  Row(
                    textDirection: ui.TextDirection.rtl,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(authorDetails),
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        PostUtils.formatDate(createdAt),
                        style: TextStyle(
                          color: AppStyles.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commentContent,
                    textDirection: ui.TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),

                  // Fixed like button for RTL alignment - custom arrangement instead of TextButton.icon
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => onLike(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: ui.TextDirection.rtl,
                          children: [
                            Text(
                              likesCount.toString(),
                              style: TextStyle(
                                color: isLiked ? Colors.red : AppStyles.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : AppStyles.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
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
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
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
            // Comments list with RTL direction
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
            // Add comment section - make sure it follows RTL
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
                textDirection: ui.TextDirection.rtl,
                children: [
                  // Send button first in RTL
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textDirection: ui.TextDirection.rtl,
                      textAlign: TextAlign.center, // Center align text
                      decoration: InputDecoration(
                        hintText: 'أضف تعليقًا...',
                        hintTextDirection: ui.TextDirection.rtl,
                        // TextField's textAlign property already centers the hint text
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppStyles.grey,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

/// A utility class for post-related helper functions
class PostUtils {
  // Helper method to format dates consistently across the app
  static String formatDate(String dateString) {
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

  // Helper method to safely extract media URLs
  static List<dynamic> extractMediaUrls(dynamic mediaList) {
    try {
      if (mediaList == null || !(mediaList is List)) {
        print("MediaList is null or not a list: $mediaList");
        return [];
      }

      // Return the complete media objects from the API, not just URLs
      return mediaList as List;
    } catch (e) {
      print("Error extracting media URLs: $e");
      return [];
    }
  }

  // Helper method to show comments in a bottom sheet
  static void showCommentsSheet(
      BuildContext context, dynamic post, Function(int) onCommentAdded) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        post: post,
        onCommentAdded: onCommentAdded,
      ),
    );
  }
}

// Add a new PhotoViewerPage widget for displaying enlarged photos
class PhotoViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PhotoViewerPage({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _PhotoViewerPageState createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "${_currentIndex + 1}/${widget.imageUrls.length}",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Main photo viewer with zoom capabilities
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white60, size: 64),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Navigation arrows if there are multiple photos
            if (widget.imageUrls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
