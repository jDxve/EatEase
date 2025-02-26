import 'package:flutter/material.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            'Profile Screen',
            style: TextStyle(fontSize: 24, color: Colors.white), // Change text color for visibility
          ),
        ),
      ),
    );
  }
}