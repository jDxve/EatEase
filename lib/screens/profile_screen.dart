import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // If you're using .env files
import 'package:eatease/components/orderhistory_card.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:eatease/screens/signin_screen.dart'; // Import your SignInScreen

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _email = "";
  String _phone = "";
  String _fullName = "";
  List<Map<String, dynamic>> _orderHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchOrderHistory(); // Fetch order history
  }

  Future<void> _fetchUserData() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/users/${widget.userId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _email = data['email'] ?? "Email not found";
          _phone = data['phone'] ?? "Phone not found";
          _fullName = data['fullName'] ?? "Full Name not found";
        });
      } else {
        print("Failed to fetch user data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  Future<void> _fetchOrderHistory() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/orders/${widget.userId}/completed";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("Fetching order history for user ID: ${widget.userId}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Order history fetched: $data");
        setState(() {
          _orderHistory = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print(
            "Failed to fetch order history. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (error) {
      print("Error fetching order history: $error");
    }
  }

  Future<void> _handleRating(String orderId, int rating) async {
    final String apiUrl = "${dotenv.env['API_BASE_URL']}/orders/$orderId/rate";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "rating": rating,
          "userId": widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
        _fetchOrderHistory(); // Refresh the order history
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit rating')),
        );
      }
    } catch (error) {
      print("Error submitting rating: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting rating')),
      );
    }
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('userId');
    await prefs.remove('remember_me');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (Route<dynamic> route) => false,
    );
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      onPressed: _logout, // Call the logout function
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'Information',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 174, 20, 9),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _showEditDialog(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _fullName,
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'E-mail',
                          value: _email,
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: _phone,
                        ),
                        const Divider(),
                        const SizedBox(height: 20),
                        const Text(
                          'Order History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 174, 20, 9),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _orderHistory.length,
                            itemBuilder: (context, index) {
                              // Sort orders: unrated first, then rated
                              final sortedOrders =
                                  List<Map<String, dynamic>>.from(_orderHistory)
                                    ..sort((a, b) {
                                      final aRated = a['isRated'] ?? false;
                                      final bRated = b['isRated'] ?? false;
                                      if (aRated == bRated) return 0;
                                      return aRated
                                          ? 1
                                          : -1; // Rated orders go to the bottom
                                    });

                              final order = sortedOrders[index];
                              final items = List<Map<String, dynamic>>.from(
                                  order['items']);

                              return Column(
                                children: items.map((item) {
                                  return OrderHistoryCard(
                                    name: item['name'] ?? '',
                                    imageUrl: item['image'] ?? '',
                                    price: (item['price'] ?? 0).toDouble(),
                                    quantity: item['quantity'] ?? 0,
                                    orderDate: order['orderDate'] ?? '',
                                    rating: order['rating'] ?? 0,
                                    isRated: order['isRated'] ?? false,
                                    ratingCount:
                                        order['ratingCount'] ?? 0, // Add this
                                    onRatingChanged: (rating) =>
                                        _handleRating(order['_id'], rating),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 111, 110, 110),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _newFullName = _fullName;
    String? _newEmail = _email;
    String? _newPhone = _phone;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _fullName,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  onChanged: (value) => _newFullName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) => _newEmail = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  onChanged: (value) => _newPhone = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _updateUserData(_newFullName, _newEmail, _newPhone);
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserData(
      String? fullName, String? email, String? phone) async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/users/${widget.userId}";

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          'fullName': fullName?.trim(),
          'email': email?.trim(),
          'phone': phone?.trim(),
        }),
      );

      if (response.statusCode == 200) {
        print("User  updated successfully");
        _fetchUserData();
      } else {
        print("Failed to update user. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error updating user data: $error");
    }
  }
}
