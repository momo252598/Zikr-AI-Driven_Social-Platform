import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/chat/all_chats.dart';
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic>? _posts;

  Future<List<dynamic>> _loadPosts() async {
    if (_posts != null) return _posts!;

    // Load sample data from JSON asset
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/utils/posts.json');
    _posts = json.decode(jsonString);
    // sort posts, newest first
    _posts!.sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return _posts!;
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

  void _showCommentsSheet(BuildContext context, dynamic post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyles.trans,
      builder: (context) => Container(
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
                    'التعليقات (${post['comments']})',
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
              child: post['commentsList'] != null &&
                      (post['commentsList'] as List).isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: post['commentsList'].length,
                      itemBuilder: (context, index) {
                        final comment = post['commentsList'][index];
                        return _buildCommentItem(comment);
                      },
                    )
                  : Center(
                      child: Text(
                        'لا توجد تعليقات بعد',
                        style: TextStyle(
                          color: AppStyles.grey,
                          fontSize: 16,
                        ),
                      ),
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
                    onTap: () => _addComment(post),
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
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppStyles.lightPurple.withOpacity(0.2),
            child: Text(
              comment['username'].toString().substring(0, 1),
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
                      comment['username'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment['date']),
                      style: TextStyle(
                        color: AppStyles.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['text']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addComment(dynamic post) {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      // Initialize commentsList if it doesn't exist
      if (post['commentsList'] == null) {
        post['commentsList'] = [];
      }

      // Add new comment
      post['commentsList'].add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'username': 'أنا',
        'text': _commentController.text.trim(),
        'date': DateTime.now().toIso8601String(),
      });

      // Update comment count
      post['comments'] = (post['commentsList'] as List).length;
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(
        // title: const Text('المجتمع'),
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
            onPressed: () {
              // Create post functionality to be implemented later
            },
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 700 : double.infinity,
          ),
          child: FutureBuilder<List<dynamic>>(
            future: _loadPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'خطأ في تحميل المنشورات: ${snapshot.error}',
                    style: TextStyle(color: AppStyles.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('لا توجد منشورات'),
                );
              }

              final posts = snapshot.data!;
              return Scrollbar(
                controller: _scrollController,
                thickness: 8.0,
                radius: const Radius.circular(10.0),
                thumbVisibility: kIsWeb, // Always visible on web
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    // Initialize commentsList if it doesn't exist
    if (post['commentsList'] == null) {
      post['commentsList'] = [];
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: kIsWeb
          ? 3
          : 2, // Slightly more elevation for better visibility on web
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
                    post['username'].toString().substring(0, 1),
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
                        post['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(post['date']),
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

          // Post text content (if any)
          if (post['text'] != null && post['text'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                post['text'],
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // Post images (if any)
          if (post['images'] != null && (post['images'] as List).isNotEmpty)
            _buildImageGallery(post['images']),

          // Post actions (like, comment)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_border,
                    color: AppStyles.lightPurple,
                  ),
                  label: Text(
                    post['likes'].toString(),
                    style: TextStyle(color: AppStyles.lightPurple),
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
                    post['comments'].toString(),
                    style: TextStyle(color: AppStyles.darkPurple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<dynamic> images) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    // Helper function to handle image display with error handling
    Widget displayImage(String imagePath) {
      try {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a placeholder if the image can't be loaded
            return Container(
              color: AppStyles.grey.withOpacity(0.2),
              child: Center(
                child: Icon(Icons.image_not_supported,
                    color: AppStyles.darkPurple.withOpacity(0.5), size: 40),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: AppStyles.grey.withOpacity(0.2),
          child: Center(
            child: Icon(Icons.error,
                color: AppStyles.darkPurple.withOpacity(0.5), size: 40),
          ),
        );
      }
    }

    if (images.length == 1) {
      // Single image - no change needed
      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        width: double.infinity,
        child: displayImage(images[0]),
      );
    } else {
      // Completely redesigned multi-image gallery using PageView
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
                  itemCount: images.length,
                  onPageChanged: (index) {
                    currentPage.value = index;
                  },
                  itemBuilder: (context, index) {
                    return displayImage(images[index]);
                  },
                ),

                // Right arrow shows Previous (left movement)
                if (kIsWeb && images.length > 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: currentPage,
                        builder: (context, index, _) {
                          return Visibility(
                            visible: index > 0,
                            child: Material(
                              color: AppStyles.darkPurple.withOpacity(0.5),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (index > 0) {
                                    pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons
                                        .arrow_back_ios, // Changed to arrow_back_ios
                                    color: AppStyles.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Left arrow shows Next (right movement)
                if (kIsWeb && images.length > 1)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: currentPage,
                        builder: (context, index, _) {
                          return Visibility(
                            visible: index < images.length - 1,
                            child: Material(
                              color: AppStyles.darkPurple.withOpacity(0.5),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (index < images.length - 1) {
                                    pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons
                                        .arrow_forward_ios, // Changed to arrow_forward_ios
                                    color: AppStyles.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Bottom page indicator
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: currentPage,
                    builder: (context, index, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (dotIndex) {
                            return Container(
                              width: dotIndex == index ? 12 : 8,
                              height: dotIndex == index ? 12 : 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotIndex == index
                                    ? AppStyles.darkPurple
                                    : AppStyles.grey.withOpacity(0.5),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
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
