import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'), 
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Text(
            'Chat Screen',
            style: TextStyle(fontSize: 24, color: Colors.white), 
          ),
        ),
      ),
    );
  }
}