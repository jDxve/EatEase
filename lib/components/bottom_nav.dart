import 'package:flutter/material.dart';
import 'package:eatease/screens/home_screen.dart';
import 'package:eatease/screens/chat_screen.dart';
import 'package:eatease/screens/orders_screen.dart';
import 'package:eatease/screens/profile_screen.dart';

class BottomNav extends StatefulWidget {
  final String userId; // Add a userId parameter

  const BottomNav({super.key, required this.userId}); // Update the constructor

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions(String userId) => <Widget>[
        HomeScreen(userId: userId), // Pass the userId to HomeScreen
        const ChatScreen(),
        const OrdersScreen(),
        const ProfileScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions(widget.userId), // Pass the userId here
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                width: 21,
                height: 22,
                child: ImageIcon(
                  const AssetImage('assets/images/home.png'),
                  color: _selectedIndex == 0 ? Colors.red : Colors.grey,
                ),
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                width: 21,
                height: 22,
                child: ImageIcon(
                  const AssetImage('assets/images/chat.png'),
                  color: _selectedIndex == 1 ? Colors.red : Colors.grey,
                ),
              ),
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                width: 22,
                height: 22,
                child: ImageIcon(
                  const AssetImage('assets/images/PurchaseOrder.png'),
                  color: _selectedIndex == 2 ? Colors.red : Colors.grey,
                ),
              ),
            ),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: SizedBox(
                width: 22,
                height: 22,
                child: ImageIcon(
                  const AssetImage('assets/images/user.png'),
                  color: _selectedIndex == 3 ? Colors.red : Colors.grey,
                ),
              ),
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}