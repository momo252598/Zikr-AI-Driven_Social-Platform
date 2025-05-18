import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/res/media.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/services/chat_api_service.dart';
import 'package:software_graduation_project/services/firebase_service.dart';
import 'package:software_graduation_project/services/auth_service.dart';
import 'package:software_graduation_project/services/global_notification_manager.dart';
import 'package:software_graduation_project/services/message_notification_service.dart'; // Import message notification service
import 'package:software_graduation_project/utils/text_utils.dart'; // Import utility
import 'package:software_graduation_project/screens/profile/profile.dart'; // Import ProfilePage
import 'package:software_graduation_project/services/chat_notification_helper.dart'; // Import chat notification helper

class ChatPage extends StatefulWidget {
  final int chatId;
  final void Function(String)?
      onMessageUpdate; // Add callback that takes the message text

  const ChatPage({
    Key? key,
    required this.chatId,
    this.onMessageUpdate,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ChatApiService _chatApiService = ChatApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final MessageNotificationService _messageNotificationService =
      MessageNotificationService(); // Add notification service
  final ScrollController _scrollController =
      ScrollController(); // Add scroll controller

  bool _showScrollToBottom =
      false; // Track if scroll-to-bottom button should be shown

  String contactName = '';
  Map<String, dynamic>? chatData;
  bool isLoading = true;
  bool hasCompletedMessagesCheck = false; // Add this flag
  List<Map<String, dynamic>> messages = [];
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  Map<int, int> typingUsers = {};
  int? currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _isPageActive = true; // Track if page is active/focused

  // Add animation controllers for typing indicator
  List<AnimationController> _dotControllers = [];
  List<Animation<double>> _dotAnimations = [];

  int? contactUserId; // Add variable to store contact's user ID
  @override
  void initState() {
    super.initState();
    _initialize();

    // Add listener to detect when user scrolls away from bottom
    _scrollController.addListener(_scrollListener);

    // Initialize the dot animations
    _initializeAnimations();

    // Initialize notification permission
    _initNotifications();

    // Set this page as active
    _isPageActive =
        true; // Register as active conversation with notification manager
    GlobalNotificationManager().setActiveConversationId(widget.chatId);

    // Mark as active conversation for chat notifications right away with Django ID
    ChatNotificationHelper()
        .setActiveConversation(null, djangoId: widget.chatId);

    // Once chat data is loaded, update with Firebase ID
    if (chatData != null && chatData!['firebase_id'] != null) {
      ChatNotificationHelper().setActiveConversation(
          chatData!['firebase_id'].toString(),
          djangoId: widget.chatId);
    }
  }

  // Initialize notification service
  Future<void> _initNotifications() async {
    await _messageNotificationService.initialize();
    // Request permissions when the chat is first opened
    await _messageNotificationService.ensurePermissions(context: context);
  }

  void _initializeAnimations() {
    // Create 3 animation controllers for the dots
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600),
      )..repeat(reverse: true);
    });

    // Add delay to each dot's animation start for wave effect
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (_dotControllers.isNotEmpty && _dotControllers[i].isAnimating) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }

    // Create animations for the dots
    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  void _scrollListener() {
    // Show button when not at bottom
    final newShowButton = _scrollController.hasClients &&
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 50;

    if (newShowButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = newShowButton;
      });
    }
  }

  Future<void> _initialize() async {
    // Get current user ID with retry mechanism
    await _ensureUserAuthenticated();

    // Load conversation data
    await _loadConversationData();

    // Mark messages as read
    _chatApiService.markMessagesAsRead(widget.chatId);

    // Subscribe to messages
    final conversationFirebaseId = chatData?['firebase_id'];
    if (conversationFirebaseId != null) {
      _subscribeToMessages(conversationFirebaseId);
      _subscribeToTypingIndicators(conversationFirebaseId);

      // Manage notifications based on page focus
      _manageNotifications(conversationFirebaseId);
    }

    // Set user as online
    if (currentUserId != null) {
      _firebaseService.updateUserPresence(currentUserId!, true);
    }

    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // Handle notification subscription based on page focus
  void _manageNotifications(String firebaseId) {
    if (_isPageActive) {
      // If page is active/focused, unsubscribe from notifications to avoid duplicates
      _messageNotificationService.unsubscribeFromConversation(firebaseId);
    } else {
      // If page is not active, subscribe to notifications
      _messageNotificationService.subscribeToConversation(
        firebaseId,
        contactName,
      );
    }
  }

  // Utility function to scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _ensureUserAuthenticated() async {
    // Check storage contents for debugging
    await _authService.debugInspectStorage();

    // Try to get current user ID
    currentUserId = await _authService.getCurrentUserId();

    // Log authentication state
    print("Authentication check: currentUserId = $currentUserId");

    if (currentUserId == null) {
      // Try to get the full user object
      final user = await _authService.getCurrentUser();
      print("User object retrieved: ${user?.toJson()}");

      // Try Firebase authentication to ensure we're connected
      try {
        await _firebaseService.signInWithCustomToken();
        print("Firebase authentication completed");
      } catch (e) {
        print("Firebase authentication error: $e");
      }

      // Wait briefly and try again (could be a network delay issue)
      await Future.delayed(const Duration(seconds: 1));
      currentUserId = await _authService.getCurrentUserId();
      print("Authentication retry: currentUserId = $currentUserId");

      if (currentUserId == null) {
        // For development/testing only: Set a temporary manual ID
        // This is helpful during development but should be removed in production
        print(
            "Authentication failed. For DEVELOPMENT only: setting temporary ID");
        await _authService.setCurrentUserId(1); // Use an appropriate test ID
        currentUserId = 1;
      }
    }
  }

  @override
  void didUpdateWidget(ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      // Clean up old subscriptions
      _messagesSubscription?.cancel();
      _typingSubscription?.cancel();

      setState(() {
        isLoading = true;
        messages = [];
      });

      _initialize();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    // Dispose animation controllers
    for (var controller in _dotControllers) {
      controller.dispose();
    }

    // If we have chat data, ensure we unsubscribe from notifications for this chat
    if (chatData != null && chatData!['firebase_id'] != null) {
      _messageNotificationService
          .unsubscribeFromConversation(chatData!['firebase_id']);
    } // Clear active conversation when leaving chat screen
    GlobalNotificationManager().clearActiveConversation();

    // Clear chat notification helper state
    ChatNotificationHelper().clearActiveConversation();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handlePageFocus(true);
  }

  @override
  void deactivate() {
    _handlePageFocus(false);
    super.deactivate();
  }

  // Update page focus state and manage notifications accordingly
  void _handlePageFocus(bool isFocused) {
    _isPageActive = isFocused;
    if (chatData != null && chatData!['firebase_id'] != null) {
      _manageNotifications(chatData!['firebase_id']);
    }
  }

  Future<void> _loadConversationData() async {
    try {
      // First try loading from the API
      final conversation =
          await _chatApiService.getConversationDetails(widget.chatId);

      // Debug the conversation data structure
      print("Conversation data received: ${json.encode(conversation)}");

      // Find the other participant's name
      String name = conversation['name'] ?? 'محادثة';
      name = TextUtils.fixArabicEncoding(name);

      // Get current user ID for comparison
      final currentUserId = await _authService.getCurrentUserId();
      print("Current user ID for comparison: $currentUserId");

      // Try to find other participant's name and ID
      if (conversation['participants'] != null &&
          conversation['participants'] is List) {
        final participants = conversation['participants'] as List;

        for (var participant in participants) {
          if (participant is Map &&
              participant.containsKey('id') &&
              participant['id'].toString() != currentUserId.toString()) {
            // Extract user ID for profile navigation
            contactUserId = participant['id'];

            // Extract name from the participant data
            if (participant.containsKey('first_name') &&
                participant.containsKey('last_name')) {
              String firstName =
                  TextUtils.fixArabicEncoding(participant['first_name'] ?? '');
              String lastName =
                  TextUtils.fixArabicEncoding(participant['last_name'] ?? '');

              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                name = '$firstName $lastName'.trim();
              } else {
                name = TextUtils.fixArabicEncoding(
                    participant['username'] ?? 'محادثة');
              }
            } else {
              name = TextUtils.fixArabicEncoding(
                  participant['username'] ?? 'محادثة');
            }
            break;
          }
        }
      }

      setState(() {
        chatData = conversation;
        contactName = name; // Use the extracted name
        isLoading = false;
      });

      // Register with ChatNotificationHelper once we have the firebase_id
      if (conversation['firebase_id'] != null) {
        ChatNotificationHelper().setActiveConversation(
            conversation['firebase_id'].toString(),
            djangoId: widget.chatId);
        debugPrint(
            'Registered active conversation ID: ${conversation['firebase_id']}');
      }

      // After loading data and updating state, scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error loading chat from API: $e');

      // Fallback to local data during development
      _loadLocalConversationData();
    }
  }

  Future<void> _loadLocalConversationData() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/utils/chat_ex.json');
      List<dynamic> chats = json.decode(jsonString);

      // Find our chat by ID
      Map<String, dynamic>? foundChat;
      for (var chat in chats) {
        if (chat['id'] == widget.chatId) {
          foundChat = Map<String, dynamic>.from(chat);
          break;
        }
      }

      if (foundChat != null) {
        if (!foundChat.containsKey('messages')) {
          foundChat['messages'] = [];
        }

        // Ensure we extract the other user's name properly
        String name = foundChat['name'] ?? 'محادثة';
        name = TextUtils.fixArabicEncoding(name);
        final currentUserId = await _authService.getCurrentUserId();

        // If there are participants, try to extract the other user's name and ID
        if (foundChat.containsKey('participants') &&
            foundChat['participants'] is List) {
          for (var participant in foundChat['participants']) {
            if (participant is Map &&
                participant.containsKey('username') &&
                participant.containsKey('id') &&
                participant['id'].toString() != currentUserId.toString()) {
              name = TextUtils.fixArabicEncoding(participant['username']);
              contactUserId = participant['id'];
              break;
            }
          }
        }

        setState(() {
          chatData = foundChat;
          contactName = name;
          isLoading = false;
        });

        // Register with ChatNotificationHelper once we have the firebase_id
        if (foundChat['firebase_id'] != null) {
          ChatNotificationHelper().setActiveConversation(
              foundChat['firebase_id'].toString(),
              djangoId: widget.chatId);
          debugPrint(
              'Registered active conversation ID (local): ${foundChat['firebase_id']}');
        }

        // After loading data and updating state, scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        setState(() {
          contactName = 'محادثة غير موجودة';
          chatData = {'messages': []};
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading local chat data: $e');
      setState(() {
        contactName = 'خطأ';
        chatData = {'messages': []};
        isLoading = false;
      });
    }
  }

  void _subscribeToMessages(String firebaseId) {
    _messagesSubscription =
        _firebaseService.getMessagesStream(firebaseId).listen((newMessages) {
      if (mounted) {
        setState(() {
          messages = newMessages;
          hasCompletedMessagesCheck =
              true; // Set the flag when we've received messages data

          // Mark messages as read
          if (currentUserId != null) {
            for (var message in newMessages) {
              // Ensure consistent type comparison
              String msgSenderId = message['sender_id'].toString();
              String curUserId = currentUserId.toString();

              if (msgSenderId != curUserId) {
                _firebaseService.markMessageAsRead(
                    firebaseId, message['id'], currentUserId!);
              }
            }
          }
        });

        // Scroll to bottom to show new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Notify parent about the latest message if available
        if (newMessages.isNotEmpty) {
          final latestMessage = newMessages.last;
          widget.onMessageUpdate?.call(latestMessage['content'] ?? '');
        }
      }
    });
  }

  void _subscribeToTypingIndicators(String firebaseId) {
    _typingSubscription = _firebaseService
        .getTypingIndicatorsStream(firebaseId)
        .listen((typingData) {
      if (mounted) {
        setState(() {
          typingUsers = typingData;
        });

        // Check if typing status changed to active and scroll to bottom
        final hasTypingUsersNow = typingData.isNotEmpty &&
            typingData.keys.any((userId) => userId != currentUserId);

        // Scroll down if typing started or continued
        if (hasTypingUsersNow) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    });
  }

  void _handleTyping(bool isTyping) {
    _typingTimer?.cancel();

    if (isTyping && !_isTyping) {
      _setTypingStatus(true);
    }

    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _setTypingStatus(false);
      });
    }
  }

  void _setTypingStatus(bool isTyping) {
    if (currentUserId != null && chatData != null) {
      _isTyping = isTyping;
      _firebaseService.setTypingStatus(
          chatData!['firebase_id'], currentUserId!, isTyping);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    print("Attempting to send message: '$content'");

    // Ensure the text is properly encoded before sending
    final contentToSend = TextUtils.prepareForSending(content);

    if (contentToSend.isEmpty) {
      print("Message content is empty. Aborting send.");
      return;
    }

    // If user ID is still null, try to get it one more time
    if (currentUserId == null) {
      print("Attempting to retrieve user ID before sending message...");
      currentUserId = await _authService.getCurrentUserId();
    }

    if (currentUserId == null) {
      print("Current user ID is still null. Showing login prompt.");
      return;
    }

    if (chatData == null) {
      print("Chat data is null. Aborting send.");
      return;
    }

    final String? firebaseId = chatData!['firebase_id']?.toString();
    if (firebaseId == null || firebaseId.isEmpty) {
      print("Firebase ID is missing or empty: $firebaseId");
      return;
    }

    print(
        "Chat data validated. Firebase ID: $firebaseId, User ID: $currentUserId");

    _messageController.clear();
    _setTypingStatus(false);

    try {
      final username = await _authService.getCurrentUsername() ?? 'User';
      print("Sending message to Firebase with username: $username");

      // Send message to Firebase directly from client
      await _firebaseService.sendMessage(
          firebaseId, contentToSend, currentUserId!, username);

      print("Message sent to Firebase successfully!");

      // Create message reference in Django WITHOUT sending to Firebase again
      print(
          "Updating message reference in Django backend. Chat ID: ${widget.chatId}");
      await _chatApiService.addMessageReference(widget.chatId, contentToSend);
      print("Django message reference updated successfully!");

      // Notify parent about the latest message
      widget.onMessageUpdate?.call(contentToSend);

      // Scroll to bottom after sending a message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _navigateToLogin() {
    // Navigate to your login screen
    // Example: Navigator.of(context).pushNamed('/login');
    print("Should navigate to login screen");
  }

  Future<bool> _handleBackNavigation() async {
    // Return true to indicate that the chat list should be refreshed
    Navigator.pop(context, true);
    return false; // Prevent default back behavior since we handled it
  }

  // Update method to display contact's profile in a modal sheet
  void _navigateToContactProfile() {
    if (contactUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن عرض الملف الشخصي للمستخدم')),
      );
      return;
    }

    // Show profile in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92, // Almost full screen but keeps app bar visible
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
              userId: contactUserId.toString(),
              scrollController: scrollController,
              isOverlay: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
    final formattedTime =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // Fix comparison by ensuring both values are strings
    bool isSentByMe = false;
    if (currentUserId != null) {
      // Get the sender ID from the message
      final senderId = msg['sender_id'];
      // Convert both to strings for reliable comparison
      final senderIdString = senderId.toString();
      final currentUserIdString = currentUserId.toString();

      // Log the values for debugging
      print('Message: sender_id=$senderId (${senderId.runtimeType}), '
          'currentUserId=$currentUserId (${currentUserId.runtimeType})');
      print(
          'After toString: sender_id=$senderIdString, currentUserId=$currentUserIdString, '
          'equal=${senderIdString == currentUserIdString}');

      isSentByMe = senderIdString == currentUserIdString;
    }

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe ? AppStyles.buttonColor : AppStyles.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSentByMe
                        ? AppStyles.lightPurple
                        : AppStyles.darkPurple,
                    width: 1),
              ),
              child: Text(
                TextUtils.fixArabicEncoding(msg['content']),
                style: TextStyle(
                  color: isSentByMe ? AppStyles.white : AppStyles.black,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    // Filter out current user and expired typing indicators
    final typingUserIds =
        typingUsers.keys.where((userId) => userId != currentUserId).toList();

    if (typingUserIds.isEmpty) return const SizedBox();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppStyles.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) => _buildDot(index)),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotAnimations[index],
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, -_dotAnimations[index].value),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppStyles.buttonColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = currentUserId != null;

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        backgroundColor: AppStyles.bgColor,
        appBar: CustomAppBar(
          title: contactName,
          showAddButton: false,
          showBackButton: !kIsWeb,
          onBackPressed: () {
            // Return true to indicate refresh when back button is pressed
            Navigator.pop(context, true);
          },
          // Add actions parameter with profile button
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: _navigateToContactProfile,
              tooltip: 'الملف الشخصي',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Expanded list of messages
                Expanded(
                  child: isLoading || !hasCompletedMessagesCheck
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMessagesList(),
                ),
                // Input field for sending messages
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: AppStyles.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            hintText: '...اكتب رسالتك',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (text) {
                            // Notify typing status
                            _handleTyping(text.isNotEmpty);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed:
                            isAuthenticated ? _sendMessage : _navigateToLogin,
                      )
                    ],
                  ),
                ),
              ],
            ),

            // Scroll to bottom button
            if (_showScrollToBottom)
              Positioned(
                right: 16,
                bottom: 70,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AppStyles.buttonColor,
                  onPressed: _scrollToBottom,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (messages.isEmpty) {
      return const Center(child: Text('لا توجد رسائل بعد'));
    }

    return ListView.builder(
      controller: _scrollController, // Add scroll controller to ListView
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messages.length + 1, // +1 for typing indicator
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessage(messages[index]);
      },
    );
  }
}
