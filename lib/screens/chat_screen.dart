// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatease/screens/message_screen.dart';
import 'dart:async';

class Contact {
  final String chatId;
  final String contactId;
  final String contactName;
  final String lastMessage;
  final DateTime lastMessageTime;

  Contact({
    required this.chatId,
    required this.contactId,
    required this.contactName,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      chatId: json['chatId'],
      contactId: json['contactId'],
      contactName: json['contactName'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every 1 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _fetchContacts();
      }
    });
  }

  Future<void> _fetchContacts() async {
    try {
      if (_contacts.isEmpty) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final apiUrl =
          "${dotenv.env['API_BASE_URL']}/users/${widget.userId}/contacts";

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> contactsJson = data['contacts'];

        if (mounted) {
          setState(() {
            _contacts =
                contactsJson.map((json) => Contact.fromJson(json)).toList();
            if (_searchController.text.isEmpty) {
              _filteredContacts = _contacts;
            } else {
              _filterContacts(_searchController.text);
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load contacts: ${response.statusCode}';
            _isLoading = false;
          });
        }
        print('Error response: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
      print('Error fetching contacts: $e');
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact.contactName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 5),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 45,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterContacts,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            hintText: 'Search Contacts',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchContacts,
                          child: _buildContactsList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _fetchContacts,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return ListView(
        children: const [
          Center(
            child: Text('No contacts available'),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            radius: 25,
            child: Text(
              contact.contactName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            contact.contactName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            contact.lastMessage,
            style: const TextStyle(color: Color.fromARGB(255, 115, 115, 115)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(contact.lastMessageTime),
                style:
                    const TextStyle(color: Color.fromARGB(255, 115, 115, 115)),
              ),
              const SizedBox(height: 20),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageScreen(
                  userId: widget.userId,
                  restaurantId: contact.contactId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
