import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/chat/all_chats.dart';
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:software_graduation_project/screens/community/create_post.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocialService _socialService = SocialService();
  List<dynamic>? _posts;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();

    // Set up scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          !_isLoadingMore &&
          _hasMorePages) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _fetchPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _socialService.getPosts();

      // Debug: Print the first post structure
      if (posts.isNotEmpty) {
        print("First post structure: ${json.encode(posts.first)}");
      }

      setState(() {
        _posts = posts;
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final morePosts = await _socialService.getPosts(page: nextPage);

      if (morePosts.isNotEmpty) {
        setState(() {
          _posts?.addAll(morePosts);
          _currentPage = nextPage;
        });
      } else {
        _hasMorePages = false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المزيد من المنشورات: $e')),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _likePost(dynamic postId) async {
    try {
      final isLiked = await _socialService.togglePostLike(postId);

      setState(() {
        // Use toString() on both sides to ensure consistent comparison
        final postIndex =
            _posts!.indexWhere((p) => p['id'].toString() == postId.toString());
        if (postIndex >= 0) {
          _posts![postIndex]['is_liked'] = isLiked;
          _posts![postIndex]['likes_count'] = isLiked
              ? (_posts![postIndex]['likes_count'] ?? 0) + 1
              : (_posts![postIndex]['likes_count'] ?? 1) - 1;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<List<dynamic>> _fetchComments(dynamic postId) async {
    try {
      print("Fetching comments for post ID: $postId");
      final comments =
          await _socialService.getPostComments(postId, parentOnly: true);

      // Debug
      if (comments.isNotEmpty) {
        print("First comment structure: ${comments.first}");
      } else {
        print("No comments returned");
      }

      // Update the post with comments
      setState(() {
        final postIndex =
            _posts!.indexWhere((p) => p['id'].toString() == postId.toString());
        if (postIndex >= 0) {
          _posts![postIndex]['commentsList'] = comments;
        }
      });

      return comments;
    } catch (e) {
      print("Error fetching comments: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments: $e')),
      );
      return [];
    }
  }

  Future<void> _addComment(dynamic postId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      // Convert string ID to integer if needed
      final int postIdInt =
          postId is int ? postId : int.parse(postId.toString());

      await _socialService.createComment(postIdInt, content);
      _commentController.clear();

      // Refresh comments
      await _fetchComments(
          postId); // Pass the original postId for consistent lookups
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> _likeComment(dynamic commentId, dynamic postId) async {
    try {
      // Convert string ID to integer if needed
      final int commentIdInt =
          commentId is int ? commentId : int.parse(commentId.toString());

      await _socialService.toggleCommentLike(commentIdInt);

      // Refresh comments to update UI
      await _fetchComments(
          postId); // Pass the original postId for consistent lookups
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  String _formatDate(String dateString) {
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
  }

  // Add this helper method to safely extract comment data
  Map<String, dynamic> _safeComment(dynamic comment) {
    if (comment is Map<String, dynamic>) {
      return comment;
    }
    // Convert to Map<String, dynamic> if it's a different type of map
    if (comment is Map) {
      return Map<String, dynamic>.from(comment);
    }
    // Return empty map as fallback
    return {};
  }

  // Replace your _showCommentsSheet method with this:
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
            final postIndex = _posts!
                .indexWhere((p) => p['id'].toString() == post['id'].toString());
            if (postIndex >= 0) {
              _posts![postIndex]['comments_count'] = newCommentCount;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              // Navigate to different chat pages based on platform
              if (kIsWeb) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BrowserChatLayout(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllChatsPage(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostPage(),
                ),
              );

              if (result == true) {
                // Post was created successfully, refresh the list
                _fetchPosts();
              }
            },
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 700 : double.infinity,
          ),
          child: RefreshIndicator(
            onRefresh: _fetchPosts,
            child: _isLoading && (_posts == null || _posts!.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _error != null && (_posts == null || _posts!.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'حدث خطأ: $_error',
                              style: TextStyle(color: AppStyles.red),
                              textAlign: TextAlign.center,
                            ),
                            ElevatedButton(
                              onPressed: _fetchPosts,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _posts == null || _posts!.isEmpty
                        ? const Center(
                            child: Text('لا توجد منشورات'),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thickness: 8.0,
                            radius: const Radius.circular(10.0),
                            thumbVisibility: kIsWeb,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  _posts!.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                try {
                                  if (index >= _posts!.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final post = _posts![index];
                                  return _buildPostCard(post);
                                } catch (e) {
                                  print(
                                      "Error rendering post at index $index: $e");
                                  return Card(
                                    margin: const EdgeInsets.all(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text("حدث خطأ في عرض هذا المنشور"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
          ),
        ),
      ),
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

      // Debug print to see the structure
      print("Post ID: $postId, Type: ${postId.runtimeType}");

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: kIsWeb ? 3 : 2,
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
                          _formatDate(post['created_at'] ??
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

            // Post actions (like, comment)
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
          // Fallback to a placeholder if the image can't be loaded
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
      // Single image - no change needed
      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        width: double.infinity,
        child:
            displayImage(imageUrls[0].toString()), // Ensure string conversion
      );
    } else {
      // Multi-image gallery using PageView
      return StatefulBuilder(
        builder: (context, setState) {
          final PageController pageController = PageController();
          final ValueNotifier<int> currentPage = ValueNotifier(0);

          return Container(
            height: 300,
            width: double.infinity,
            child: Stack(
              children: [
                // Image PageView
                PageView.builder(
                  controller: pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) {
                    currentPage.value = index;
                  },
                  itemBuilder: (context, index) {
                    // Make sure to convert to string
                    return displayImage(imageUrls[index].toString());
                  },
                ),
                // Rest of your widget...
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Add this new widget class inside your file (outside the main class)
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

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
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
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'أضف تعليقًا...',
                      hintTextDirection: TextDirection.rtl,
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
}
