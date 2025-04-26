import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/chat/all_chats.dart';
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:software_graduation_project/screens/community/create_post.dart';
import 'package:software_graduation_project/screens/profile/profile.dart';
import 'package:software_graduation_project/components/community/post.dart'; // Import the shared post components

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  final SocialService _socialService = SocialService();
  List<dynamic>? _posts;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final Set<dynamic> _loadedPostIds = <dynamic>{};

  @override
  void initState() {
    super.initState();
    _fetchPosts();

    // Set up scroll listener for pagination
    _scrollController.addListener(() {
      // Only trigger loading more if we're near the bottom, not already loading, and have more pages
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

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
        _currentPage = 1;
        // Reset loaded post IDs and populate with current posts
        _loadedPostIds.clear();
        for (final post in posts) {
          if (post['id'] != null) {
            _loadedPostIds.add(post['id'].toString());
          }
        }
      });
    } catch (e) {
      print("Error fetching posts: $e");

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    // Guard clauses to prevent unnecessary API calls
    if (_isLoadingMore) return;
    if (!_hasMorePages) {
      print("No more pages to load - skipping API call");
      return;
    }

    print(
        "Loading more posts - Current page: $_currentPage, Next page to load: ${_currentPage + 1}");
    print("Currently loaded post IDs: ${_loadedPostIds.length}");

    // Check if widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final morePosts = await _socialService.getPosts(page: nextPage);

      // Check if we got any posts
      print("Received ${morePosts.length} posts from page $nextPage");

      // Filter out duplicates
      final List<dynamic> newPosts = [];
      for (final post in morePosts) {
        if (post['id'] != null &&
            !_loadedPostIds.contains(post['id'].toString())) {
          newPosts.add(post);
          _loadedPostIds.add(post['id'].toString());
        } else {
          print("Skipping duplicate post ID: ${post['id']}");
        }
      }

      print("After filtering duplicates: ${newPosts.length} new posts to add");

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        if (newPosts.isNotEmpty) {
          // Add only non-duplicate posts
          _posts?.addAll(newPosts);
          _currentPage = nextPage;
        } else {
          // If no new unique posts were found, end pagination
          _hasMorePages = false;
          print("No more unique posts available - reached the end");
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      print("Error loading more posts: $e");

      // Only show snackbar if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل المزيد من المنشورات: $e')),
      );

      setState(() {
        _hasMorePages = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _likePost(dynamic postId) async {
    try {
      final isLiked = await _socialService.togglePostLike(postId);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

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
      // Only show snackbar if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
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
                              itemCount: _posts!.length +
                                  (_isLoadingMore && _hasMorePages ? 1 : 0),
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

                                  // Use the reusable PostCard component
                                  return PostCard(
                                    post: post,
                                    onLike: _likePost,
                                    onComment: (context, post) {
                                      PostUtils.showCommentsSheet(
                                        context,
                                        post,
                                        (newCommentCount) {
                                          // Update post's comment count without full reload
                                          setState(() {
                                            final postIndex = _posts!
                                                .indexWhere((p) =>
                                                    p['id'].toString() ==
                                                    post['id'].toString());
                                            if (postIndex >= 0) {
                                              _posts![postIndex]
                                                      ['comments_count'] =
                                                  newCommentCount;
                                            }
                                          });
                                        },
                                      );
                                    },
                                    onUserTap: _navigateToUserProfile,
                                  );
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
