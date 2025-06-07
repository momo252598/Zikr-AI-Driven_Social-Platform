import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/screens/chat/all_chats.dart';
import 'package:software_graduation_project/screens/chat/browser_chat_layout.dart';
import 'package:software_graduation_project/services/social_api_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/screens/community/create_post.dart';
import 'package:software_graduation_project/screens/profile/profile.dart';
import 'package:software_graduation_project/components/community/post.dart';
import 'package:software_graduation_project/services/unread_messages_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  final SocialService _socialService = SocialService();
  final AuthService _authService = AuthService();
  List<dynamic>? _posts;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingTags = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final Set<dynamic> _loadedPostIds = <dynamic>{};
  int? _currentUserId; // Track current user ID for delete functionality

  // Tag filtering
  List<dynamic> _tags = [];
  List<dynamic> _filteredTags = [];
  List<int> _selectedTagIds = [];
  String _selectedCategory = '';
  String _tagSearchQuery = '';
  bool _isFilterExpanded = false;
  bool _useLatestOrdering = false; // New field for time-based ordering
  final List<String> _categories = [
    'religious',
    'practice',
    'lifestyle',
    'contemporary',
    'community',
    'other'
  ];
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadTags();
    _fetchPosts();

    _scrollController.addListener(() {
      if (kIsWeb) {
        // For web, use a more sensitive threshold
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200 &&
            !_isLoading &&
            !_isLoadingMore &&
            _hasMorePages) {
          _loadMorePosts();
        }
      } else {
        // Original mobile logic
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent * 0.8 &&
            !_isLoading &&
            !_isLoadingMore &&
            _hasMorePages) {
          _loadMorePosts();
        }
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUserId = await _authService.getCurrentUserId();
    } catch (e) {
      print('Error loading current user ID: $e');
    }
  }

  Future<void> _loadTags() async {
    try {
      setState(() {
        _isLoadingTags = true;
      });

      final tags = await _socialService.getTags();

      if (!mounted) return;

      setState(() {
        _tags = tags;
        _filteredTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      print('Error loading tags: $e');
      if (!mounted) return;

      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  void _filterTags() {
    setState(() {
      _filteredTags = _tags.where((tag) {
        bool matchesCategory =
            _selectedCategory.isEmpty || tag['category'] == _selectedCategory;
        bool matchesSearch = _tagSearchQuery.isEmpty ||
            tag['name'].toString().contains(_tagSearchQuery) ||
            (tag['display_name_ar'] != null &&
                tag['display_name_ar'].toString().contains(_tagSearchQuery));
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _toggleTagSelection(dynamic tag) {
    final int tagId = tag['id'];
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });

    // Refresh posts with new tag filter
    _fetchPosts();
  }

  void _clearTagFilters() {
    setState(() {
      _selectedTagIds.clear();
      _selectedCategory = '';
      _tagSearchQuery = '';
      _useLatestOrdering = false; // Reset ordering as well
      _filteredTags = _tags;
    });

    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      List<dynamic> posts;
      if (_selectedTagIds.isNotEmpty) {
        Map<String, dynamic> uniquePosts = {};
        for (int tagId in _selectedTagIds) {
          final tagPosts = await _socialService.getPostsForTag(tagId);
          for (var post in tagPosts) {
            if (post['id'] != null) {
              uniquePosts[post['id'].toString()] = post;
            }
          }
        }

        posts = uniquePosts.values.toList();
        // For tag filtering, disable pagination as we're merging results
        _hasMorePages = false;
      } else {
        final response = await _socialService.getPosts(
          page: 1,
          ordering: _useLatestOrdering ? 'latest' : null,
        );
        posts = response['results'] as List<dynamic>;

        // Check if there are more pages
        _hasMorePages = response['next'] != null;
        print("Has more pages: $_hasMorePages");
        print("Total posts count: ${response['count']}");
      }

      if (posts.isNotEmpty) {
        print("First post structure: ${json.encode(posts.first)}");
      }

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
        _currentPage = 1;
        _loadedPostIds.clear();
        for (final post in posts) {
          if (post['id'] != null) {
            _loadedPostIds.add(post['id'].toString());
          }
        }
      });
    } catch (e) {
      print("Error fetching posts: $e");

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;
    if (!_hasMorePages) {
      print("No more pages to load - skipping API call");
      return;
    }

    if (_selectedTagIds.isNotEmpty) {
      setState(() {
        _hasMorePages = false;
      });
      return;
    }

    print(
        "Loading more posts - Current page: $_currentPage, Next page to load: ${_currentPage + 1}");
    print("Currently loaded post IDs: ${_loadedPostIds.length}");

    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _socialService.getPosts(
        page: nextPage,
        ordering: _useLatestOrdering ? 'latest' : null,
      );
      final morePosts = response['results'] as List<dynamic>;

      print("Received ${morePosts.length} posts from page $nextPage");

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

      if (!mounted) return;

      setState(() {
        if (newPosts.isNotEmpty) {
          _posts?.addAll(newPosts);
          _currentPage = nextPage;
        }

        // Check if there are more pages based on API response
        _hasMorePages = response['next'] != null;
        if (!_hasMorePages) {
          print("No more pages available - reached the end");
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      print("Error loading more posts: $e");

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

      if (!mounted) return;

      setState(() {
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> _deletePost(dynamic post) async {
    try {
      final postId = post['id'];
      await _socialService.deletePost(postId);

      if (!mounted) return;

      setState(() {
        _posts!.removeWhere((p) => p['id'].toString() == postId.toString());
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

  Widget _buildChatIconWithBadge() {
    return StreamBuilder<int>(
      stream: UnreadMessagesService().unreadCountStream,
      initialData: UnreadMessagesService().unreadCount,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount.toString()),
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.chat),
        );
      },
    );
  }

  void _showComments(BuildContext context, dynamic post) {
    PostUtils.showCommentsSheet(context, post, (newCount) {
      setState(() {
        final postIndex = _posts!
            .indexWhere((p) => p['id'].toString() == post['id'].toString());
        if (postIndex >= 0) {
          _posts![postIndex]['comments_count'] = newCount;
        }
      });
    });
  }

  void _navigateToUserProfile(dynamic authorDetails) {
    if (authorDetails != null && authorDetails['id'] != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
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

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'religious':
        return 'معرفة دينية';
      case 'practice':
        return 'عبادات يومية';
      case 'lifestyle':
        return 'حياة إسلامية';
      case 'contemporary':
        return 'قضايا معاصرة';
      case 'community':
        return 'المجتمع';
      case 'other':
        return 'أخرى';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedTagIds.isNotEmpty
                    ? 'تصفية حسب المواضيع'
                    : _useLatestOrdering
                        ? 'الأحدث أولاً'
                        : 'مقترح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.darkPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: AppStyles.darkPurple,
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _buildChatIconWithBadge(),
            onPressed: () {
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
          child: Column(
            children: [
              // Tag filtering section - shown when expanded
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isFilterExpanded ? null : 0,
                child: _isFilterExpanded
                    ? Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Directionality(
                              textDirection:
                                  TextDirection.rtl, // RTL for Arabic
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        'خيارات التصفية',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppStyles.darkPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Ordering selection - redesigned as segmented control
                                      Text(
                                        'ترتيب المنشورات',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppStyles.darkPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppStyles.lightPurple
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppStyles.lightPurple
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (_useLatestOrdering) {
                                                    setState(() {
                                                      _useLatestOrdering =
                                                          false;
                                                    });
                                                    _fetchPosts();
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                                  decoration: BoxDecoration(
                                                    color: !_useLatestOrdering
                                                        ? AppStyles
                                                            .txtFieldColor
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.auto_awesome,
                                                        color:
                                                            !_useLatestOrdering
                                                                ? AppStyles
                                                                    .white
                                                                : AppStyles
                                                                    .darkPurple,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'مُقترح',
                                                        style: TextStyle(
                                                          color:
                                                              !_useLatestOrdering
                                                                  ? AppStyles
                                                                      .white
                                                                  : AppStyles
                                                                      .darkPurple,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (!_useLatestOrdering) {
                                                    setState(() {
                                                      _useLatestOrdering = true;
                                                    });
                                                    _fetchPosts();
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                                  decoration: BoxDecoration(
                                                    color: _useLatestOrdering
                                                        ? AppStyles
                                                            .txtFieldColor
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        color:
                                                            _useLatestOrdering
                                                                ? AppStyles
                                                                    .white
                                                                : AppStyles
                                                                    .darkPurple,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'الأحدث',
                                                        style: TextStyle(
                                                          color:
                                                              _useLatestOrdering
                                                                  ? AppStyles
                                                                      .white
                                                                  : AppStyles
                                                                      .darkPurple,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Search bar for tags
                                      TextField(
                                        decoration: InputDecoration(
                                          hintText: 'بحث عن مواضيع...',
                                          prefixIcon: Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: AppStyles.lightPurple),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: AppStyles.lightPurple
                                                    .withOpacity(0.5)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _tagSearchQuery = value;
                                            _filterTags();
                                          });
                                        },
                                      ),

                                      const SizedBox(height: 16),

                                      // Category selection
                                      Text(
                                        'تصفية حسب المواضيع',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppStyles.darkPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Category chips
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          // "All" option
                                          FilterChip(
                                            label: Text('الكل'),
                                            selected: _selectedCategory.isEmpty,
                                            onSelected: (selected) {
                                              setState(() {
                                                _selectedCategory = '';
                                                _filterTags();
                                              });
                                            },
                                            backgroundColor: AppStyles
                                                .lightPurple
                                                .withOpacity(0.2),
                                            selectedColor: AppStyles.lightPurple
                                                .withOpacity(0.7),
                                            checkmarkColor: AppStyles.white,
                                            labelStyle: TextStyle(
                                              color: _selectedCategory.isEmpty
                                                  ? AppStyles.white
                                                  : AppStyles.black,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8),
                                          ),

                                          // Category options
                                          ...List.generate(
                                            _categories.length,
                                            (index) {
                                              final category =
                                                  _categories[index];
                                              final String label =
                                                  _getCategoryDisplayName(
                                                      category);

                                              return FilterChip(
                                                label: Text(label),
                                                selected: _selectedCategory ==
                                                    category,
                                                onSelected: (selected) {
                                                  setState(() {
                                                    _selectedCategory = selected
                                                        ? category
                                                        : '';
                                                    _filterTags();
                                                  });
                                                },
                                                backgroundColor: AppStyles
                                                    .lightPurple
                                                    .withOpacity(0.2),
                                                selectedColor: AppStyles
                                                    .lightPurple
                                                    .withOpacity(0.7),
                                                checkmarkColor: AppStyles.white,
                                                labelStyle: TextStyle(
                                                  color: _selectedCategory ==
                                                          category
                                                      ? AppStyles.white
                                                      : AppStyles.black,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8),
                                              );
                                            },
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Selected tags display
                                      if (_selectedTagIds.isNotEmpty) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'المواضيع المُختارة',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppStyles.darkPurple,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _clearTagFilters,
                                              child: Text(
                                                'مسح الكل',
                                                style: TextStyle(
                                                  color: AppStyles.red,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: _tags
                                              .where((tag) => _selectedTagIds
                                                  .contains(tag['id']))
                                              .map<Widget>((tag) {
                                            return Chip(
                                              label: Text(
                                                tag['display_name_ar'] ??
                                                    tag['name'],
                                                style: TextStyle(
                                                  color: AppStyles.darkPurple,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: AppStyles
                                                  .lightPurple
                                                  .withOpacity(0.2),
                                              deleteIconColor:
                                                  AppStyles.darkPurple,
                                              onDeleted: () =>
                                                  _toggleTagSelection(tag),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Tags selection
                                      _isLoadingTags
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : _filteredTags.isEmpty
                                              ? Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      'لا توجد مواضيع متطابقة مع بحثك',
                                                      style: TextStyle(
                                                        color: AppStyles.grey,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Wrap(
                                                  spacing: 8,
                                                  children: _filteredTags
                                                      .map<Widget>((tag) {
                                                    final bool isSelected =
                                                        _selectedTagIds
                                                            .contains(
                                                                tag['id']);
                                                    return ActionChip(
                                                      label: Text(
                                                        tag['display_name_ar'] ??
                                                            tag['name'],
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? AppStyles.white
                                                              : AppStyles
                                                                  .darkPurple,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          isSelected
                                                              ? AppStyles
                                                                  .darkPurple
                                                              : AppStyles
                                                                  .lightPurple
                                                                  .withOpacity(
                                                                      0.2),
                                                      onPressed: () =>
                                                          _toggleTagSelection(
                                                              tag),
                                                    );
                                                  }).toList(),
                                                ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Posts list
              Expanded(
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
                              : ScrollConfiguration(
                                  behavior:
                                      ScrollConfiguration.of(context).copyWith(
                                    scrollbars: kIsWeb ? false : true,
                                  ),
                                  child: kIsWeb
                                      ? _buildWebScrollView()
                                      : _buildMobileScrollView(),
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebScrollView() {
    return Scrollbar(
      controller: _scrollController,
      thickness: 8.0,
      radius: const Radius.circular(10.0),
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.right,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            children: [
              // Posts
              ...List.generate(_posts!.length, (index) {
                final post = _posts![index];
                return PostCard(
                  post: post,
                  onLike: _likePost,
                  onComment: _showComments,
                  onUserTap: _navigateToUserProfile,
                  onDelete: _deletePost,
                  currentUserId: _currentUserId,
                  useRtlText: true,
                );
              }),

              // Loading indicator
              if (_isLoadingMore && _hasMorePages)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // End of content indicator
              if (!_hasMorePages && _posts!.isNotEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'تم تحميل جميع المنشورات',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // Extra space to ensure scrollability
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileScrollView() {
    return Scrollbar(
      controller: _scrollController,
      thickness: 8.0,
      radius: const Radius.circular(10.0),
      thumbVisibility: false,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _posts!.length + (_isLoadingMore && _hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _posts!.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = _posts![index];
          return PostCard(
            post: post,
            onLike: _likePost,
            onComment: _showComments,
            onUserTap: _navigateToUserProfile,
            onDelete: _deletePost,
            currentUserId: _currentUserId,
            useRtlText: true,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
