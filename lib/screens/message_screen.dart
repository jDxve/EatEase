import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;
  bool _isSending = false;
  String? _chatId;
  bool _isChatIdLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantDetails();
    _initializeSocket(); // Move this before _getOrCreateChatId
    _getOrCreateChatId().then((_) {
      if (_chatId != null) {
        _loadInitialMessages();
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _initializeSocket() {
    socket = IO.io('${dotenv.env['SOCKET_BASE_URL']}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Socket Connected');
      setState(() => _isConnected = true);
      if (_chatId != null) {
        socket.emit('joinChat', _chatId);
        print('Joined chat room: $_chatId');
      }
    });

    socket.onDisconnect((_) {
      print('Socket Disconnected');
      setState(() => _isConnected = false);
    });

    // Update the message received handler
    socket.on('messageReceived', (data) {
      print('Received message: $data');
      if (data != null && data['sender_id'] != widget.userId) {
        setState(() {
          _messages.add({
            'sender_id': data['sender_id'],
            'message': data['message'],
            'timestamp':
                data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          });
          _messages.sort((a, b) =>
              (a['timestamp'] as num).compareTo(b['timestamp'] as num));
        });
        _scrollToBottom();
      }
    });

    socket.onError((error) => print('Socket Error: $error'));
    socket.onConnectError((error) => print('Connect Error: $error'));
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

  void _loadInitialMessagesFromChat(Map<String, dynamic> chatData) {
    if (chatData['messages'] != null && mounted) {
      List<dynamic> fetchedMessages = chatData['messages'];
      setState(() {
        _messages.clear();
        _messages.addAll(fetchedMessages.map<Map<String, dynamic>>((msg) {
          return {
            'sender_id': msg['sender_id'],
            'message': msg['message'],
            'timestamp':
                msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          };
        }).toList());
        _messages.sort(
            (a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num));
      });
      _scrollToBottom();
    }
  }

  void _addMessage(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        _messages.add({
          'sender_id': data['sender_id'],
          'message': data['message'],
          'timestamp':
              data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        });
        _messages.sort(
            (a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num));
      });
      _scrollToBottom();
    }
  }

  Future<void> _getOrCreateChatId() async {
    final existingChat = await _fetchExistingChat();
    if (existingChat != null) {
      _chatId = existingChat['_id'];
      _isChatIdLoading = false;
      socket.emit('joinChat', _chatId);
      _loadInitialMessagesFromChat(existingChat);
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
        _chatId = data['_id'];
        socket.emit('joinChat', _chatId);
      }
    } catch (e) {
      print('Error creating chat ID: $e');
    } finally {
      setState(() {
        _isChatIdLoading = false;
      });
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_chatId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/chats/$_chatId/messages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _loadMessagesFromResponse(data);
      }
    } catch (e) {
      print('Error loading initial messages: $e');
    }
  }

  void _loadMessagesFromResponse(Map<String, dynamic> data) {
    if (data != null) {
      List<dynamic> fetchedMessages =
          data is List ? data : data['messages'] ?? [];
      setState(() {
        _messages.clear();
        _messages.addAll(fetchedMessages.map<Map<String, dynamic>>((msg) {
          return {
            'sender_id': msg['sender_id'],
            'message': msg['message'],
            'timestamp':
                msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          };
        }).toList());
        _messages.sort(
            (a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num));
      });
      _scrollToBottom();
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
    if (_controller.text.isNotEmpty && !_isSending && _chatId != null) {
      final message = _controller.text;
      _addMessageToLocal(message);
      _controller.clear();

      try {
        await _saveMessageToDatabase(message);
        socket.emit('sendMessage', {
          'chatId': _chatId,
          'sender_id': widget.userId,
          'message': message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
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
    _scrollToBottom();
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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              _isConnected ? Icons.circle : Icons.circle_outlined,
              color: _isConnected ? Colors.green : Colors.red,
              size: 12,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(color: Colors.grey, height: 1, thickness: 1),
          Expanded(
            child: _isChatIdLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
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
          if (isUserMessage) const SizedBox(width: 8),
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
                onPressed: _isChatIdLoading || _chatId == null || _isSending
                    ? null
                    : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
