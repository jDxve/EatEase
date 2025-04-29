import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class MessageScreen extends StatefulWidget {
  final String userId;
  final String restaurantId;

  const MessageScreen({
    Key? key,
    required this.userId,
    required this.restaurantId,
  }) : super(key: key);

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? restaurantName;
  String? restaurantImage;
  String? _chatId;
  bool _isChatIdLoading = true;
  Timer? _refreshTimer;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchRestaurantDetails();
    _getOrCreateChatId().then((_) {
      if (_chatId != null) {
        _fetchLatestMessages();
        _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _chatId != null) {
            _fetchLatestMessages();
          }
        });
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      setState(() {
        _showScrollToBottom = _scrollController.position.pixels !=
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _fetchLatestMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL']}/chats/users/${widget.userId}/restaurants/${widget.restaurantId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> fetchedMessages = data['messages'] ?? [];

        if (fetchedMessages.length != _messages.length) {
          setState(() {
            _messages.clear();
            _messages.addAll(fetchedMessages.map<Map<String, dynamic>>((msg) {
              return {
                'sender_id': msg['sender_id'],
                'message': msg['message'],
                'timestamp': msg['timestamp'] != null
                    ? DateTime.parse(msg['timestamp']).millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch,
              };
            }).toList());
            _messages.sort((a, b) =>
                (a['timestamp'] as num).compareTo(b['timestamp'] as num));
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Error fetching latest messages: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchExistingChat() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL']}/chats/users/${widget.userId}/restaurants/${widget.restaurantId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('Failed to fetch existing chat: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching existing chat: $e');
      return null;
    }
  }

  Future<void> _getOrCreateChatId() async {
    final existingChat = await _fetchExistingChat();
    if (existingChat != null) {
      setState(() {
        _chatId = existingChat['_id'];
        _isChatIdLoading = false;
      });
      await _fetchLatestMessages();
    } else {
      await _createChatId();
    }
  }

  Future<void> _createChatId() async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/chats'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_id': widget.userId,
          'restaurant_id': widget.restaurantId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _chatId = data['_id'];
          _isChatIdLoading = false;
        });
        await _fetchLatestMessages();
      }
    } catch (e) {
      print('Error creating chat ID: $e');
      setState(() {
        _isChatIdLoading = false;
      });
    }
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/restaurants/${widget.restaurantId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          restaurantName = data['name'];
          restaurantImage = data['restaurant_photo'];
        });
      }
    } catch (e) {
      print('Error fetching restaurant details: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty && _chatId != null) {
      final message = _controller.text;
      _addMessageToLocal(message);
      _controller.clear();

      try {
        await _saveMessageToDatabase(message);
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  void _addMessageToLocal(String message) {
    setState(() {
      _messages.add({
        'sender_id': widget.userId,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  Future<void> _saveMessageToDatabase(String message) async {
    if (_chatId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/chats/$_chatId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': widget.userId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to save message to database: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving message to database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: restaurantImage != null
                  ? NetworkImage(restaurantImage!)
                  : const AssetImage('assets/images/restaurant1.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                restaurantName ?? 'Restaurant',
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(color: Colors.grey, height: 1, thickness: 1),
          Expanded(
            child: Stack(
              children: [
                _isChatIdLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchLatestMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _messages.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _buildMessage(_messages[index]);
                          },
                        ),
                      ),
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 8,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: _scrollToBottom,
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> messageData) {
    final bool isUserMessage = messageData['sender_id'] == widget.userId;
    final String message = messageData['message'];
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      messageData['timestamp'] is int
          ? messageData['timestamp']
          : DateTime.now().millisecondsSinceEpoch,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUserMessage) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUserMessage ? Colors.red : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: isUserMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUserMessage) const SizedBox(width: 8), // Fixed here
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed:
                    _isChatIdLoading || _chatId == null ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
