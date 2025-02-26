import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'), // Path to your background image
            fit: BoxFit.cover, // Cover the entire screen
          ),
        ),
        child: const Center(
          child: Text(
            'Chat Screen',
            style: TextStyle(fontSize: 24, color: Colors.white), // Change text color for visibility
          ),
        ),
      ),
    );
  }
}