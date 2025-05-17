import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For text direction controls
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/utils/text_utils.dart'; // Import text utilities
import 'package:software_graduation_project/utils/verification_badge.dart'; // Import for sheikh badges

class NewConversationDialog extends StatefulWidget {
  final Function(int) onConversationCreated;

  const NewConversationDialog({Key? key, required this.onConversationCreated})
      : super(key: key);

  @override
  _NewConversationDialogState createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ChatApiService _chatApiService = ChatApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isSearching = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Handle search input with debounce
  void _onSearchChanged() {
    // Cancel any previous timer
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Get the current search text
    final searchText = _searchController.text;

    // Log the search text for debugging
    print('Search text changed: "$searchText" (${searchText.length} chars)');

    // Set a new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Always search with the latest text from the controller
      final currentText = _searchController.text;
      print('Debounce timer triggered. Current text: "$currentText"');
      _performSearch(currentText);
    });
  }

  // Search for users
  Future<void> _performSearch(String query) async {
    // Allow searching with spaces - don't trim the query here
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final results = await _chatApiService.searchUsers(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء البحث';
          _isSearching = false;
        });
      }
      print('Error searching users: $e');
    }
  }

  // Format and display name correctly with Arabic support
  String _formatName(Map<String, dynamic> user) {
    final String firstName = user['first_name'] ?? '';
    final String lastName = user['last_name'] ?? '';
    final String username = user['username'] ?? '';

    String displayName = '';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      displayName = '$firstName $lastName'.trim();
    } else {
      displayName = username;
    }

    // Ensure proper encoding of Arabic text
    return TextUtils.fixArabicEncoding(displayName);
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
    final String username = user['username'];

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Start conversation with this user
      final result = await _chatApiService.startConversation(username, '');

      // Extract the conversation ID
      int? conversationId;
      if (result.containsKey('conversation') && result['conversation'] is Map) {
        final conversation = result['conversation'] as Map;
        conversationId = conversation['id'] is int
            ? conversation['id']
            : int.tryParse(conversation['id'].toString());
      } else if (result.containsKey('id')) {
        conversationId = result['id'] is int
            ? result['id']
            : int.tryParse(result['id'].toString());
      }

      if (conversationId == null) {
        throw Exception('لم يتم العثور على معرف المحادثة في الرد');
      }

      // First close the dialog
      Navigator.of(context).pop();

      // Then notify parent to handle navigation
      widget.onConversationCreated(conversationId);
    } catch (e) {
      print('Error starting conversation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          String errorString = e.toString().toLowerCase();

          if (errorString
                  .contains('cannot start a conversation with yourself') ||
              errorString.contains('conversation with yourself')) {
            _errorMessage = 'لا يمكنك بدء محادثة مع نفسك';
          } else {
            _errorMessage = 'فشل في بدء المحادثة';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on web-sized screen
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isWeb
            ? MediaQuery.of(context).size.width *
                0.4 // Smaller percentage on web
            : MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500, // Maximum width for web
          maxHeight: MediaQuery.of(context).size.height * (isWeb ? 0.6 : 0.7),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'بحث عن مستخدم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Search field with improved RTL support
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'اكتب اسم أو اسم مستخدم',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                // Better RTL handling
                hintTextDirection: TextDirection.rtl,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),

            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),

            // Search results
            Flexible(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty && _searchController.text.length >= 2
                      ? Center(
                          child: Text(
                            'لا توجد نتائج',
                            textDirection: TextDirection.rtl,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            final String username = user['username'] ?? '';
                            final String displayName = _formatName(user);
                            final String? profilePicture =
                                user['profile_picture'];
                            final bool hasFullName =
                                (user['first_name'] != null &&
                                        user['first_name'].isNotEmpty) ||
                                    (user['last_name'] != null &&
                                        user['last_name'].isNotEmpty);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppStyles.lightPurple,
                                backgroundImage: profilePicture != null &&
                                        profilePicture.isNotEmpty
                                    ? NetworkImage(profilePicture)
                                    : null,
                                child: profilePicture == null ||
                                        profilePicture.isEmpty
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0]
                                            : '?',
                                        style:
                                            TextStyle(color: AppStyles.white),
                                      )
                                    : null,
                              ),
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  // Show verification badge for sheikh users
                                  if (user['user_type'] == 'sheikh')
                                    const VerificationBadge(
                                      isVerifiedSheikh: true,
                                      size: 14.0,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '@$username',
                                textDirection:
                                    TextDirection.ltr, // Username is LTR
                              ),
                              onTap: () => _startConversation(user),
                            );
                          },
                        ),
            ),

            // Cancel button
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                ),
                child: const Text('إلغاء'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
