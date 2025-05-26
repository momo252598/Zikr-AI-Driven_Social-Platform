import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:software_graduation_project/base/res/styles/app_styles.dart';
import 'package:software_graduation_project/base/widgets/app_bar.dart';
import 'package:software_graduation_project/services/rag_service.dart';
import 'package:software_graduation_project/utils/text_utils.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final RagService _ragService = RagService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;
  bool _showScrollToBottom = false;

  // Animation controllers for typing indicator
  List<AnimationController> _dotControllers = [];
  List<Animation<double>> _dotAnimations = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeAnimations();
    _loadSessionMessages();
  }

  void _initializeAnimations() {
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600),
      );
    });

    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (_dotControllers.isNotEmpty && mounted) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }

    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  void _loadSessionMessages() {
    // Initialize session with welcome message if empty
    _ragService.initializeSessionIfEmpty();

    // Load messages from session storage
    setState(() {
      messages = _ragService.getSessionMessages();
    });

    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollListener() {
    final newShowButton = _scrollController.hasClients &&
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 50;

    if (newShowButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = newShowButton;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final contentToSend = TextUtils.prepareForSending(content);
    _messageController.clear();

    // Add user message to session storage
    final userMessage = {
      'content': contentToSend,
      'isBot': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _ragService.addMessageToSession(userMessage);

    // Update UI state
    setState(() {
      messages = _ragService.getSessionMessages();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Send query to RAG service
      final response = await _ragService.sendQuery(contentToSend);

      // Create bot response message
      Map<String, dynamic> botMessage;
      if (response['success'] == true) {
        botMessage = {
          'content': TextUtils.fixArabicEncoding(response['text']),
          'isBot': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'citation': response['citation'],
          'request_id': response['request_id'],
        };
      } else {
        botMessage = {
          'content': 'عذراً، حدث خطأ: ${response['error']}',
          'isBot': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isError': true,
        };
      }

      // Add bot message to session storage
      _ragService.addMessageToSession(botMessage);

      // Update UI state
      setState(() {
        _isLoading = false;
        messages = _ragService.getSessionMessages();
      });
    } catch (e) {
      // Add error message to session storage
      final errorMessage = {
        'content': 'عذراً، حدث خطأ في الاتصال بالخدمة',
        'isBot': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isError': true,
      };

      _ragService.addMessageToSession(errorMessage);

      setState(() {
        _isLoading = false;
        messages = _ragService.getSessionMessages();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
    final formattedTime =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final isBot = msg['isBot'] == true;
    final isError = msg['isError'] == true;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment:
              isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                  maxWidth: kIsWeb
                      ? MediaQuery.of(context).size.width * 0.5
                      : MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isBot
                    ? (isError ? Colors.red.withOpacity(0.1) : AppStyles.white)
                    : AppStyles.buttonColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBot
                      ? (isError ? Colors.red : AppStyles.darkPurple)
                      : AppStyles.lightPurple,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBot && !isError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.smart_toy,
                              size: 16, color: AppStyles.darkPurple),
                          SizedBox(width: 4),
                          Text(
                            'المساعد الذكي',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppStyles.darkPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    msg['content'],
                    style: TextStyle(
                      color: isBot ? AppStyles.black : AppStyles.white,
                    ),
                  ),
                ],
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
    if (!_isLoading) return const SizedBox();

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
            children: [
              Icon(Icons.smart_toy, size: 16, color: AppStyles.darkPurple),
              SizedBox(width: 8),
              ...List.generate(3, (index) => _buildDot(index)),
            ],
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
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    for (var controller in _dotControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgColor,
      appBar: CustomAppBar(
        title: 'المساعد الذكي',
        showAddButton: false,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
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
                          hintText: '...اسأل سؤالك الديني',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _sendMessage,
                    )
                  ],
                ),
              ),
            ],
          ),
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
    );
  }

  Widget _buildMessagesList() {
    if (messages.isEmpty) {
      return const Center(child: Text('ابدأ محادثة جديدة'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessage(messages[index]);
      },
    );
  }
}
