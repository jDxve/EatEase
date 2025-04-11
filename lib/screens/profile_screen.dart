import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // If you're using .env files

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

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch data when the screen loads
  }

  Future<void> _fetchUserData() async {
    final String apiUrl =
        "${dotenv.env['API_BASE_URL']}/users/${widget.userId}"; // Using dotenv

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body); // Parse JSON
        print("User  data fetched: $data"); // Log the fetched data
        setState(() {
          _email = data['email'] ?? "Email not found"; // Provide default value
          _phone = data['phone'] ?? "Phone not found"; // Provide default value
          _fullName = data['fullName'] ??
              "Full Name not found"; // Provide default value
        });
      } else {
        print("Failed to fetch user data. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
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
        print("User updated successfully");
        _fetchUserData();
      } else {
        print("Failed to update user. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (error) {
      print("Error updating user data: $error");
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
                      onPressed: () {
                        // Logout logic here
                      },
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
                        const SizedBox(
                            height:
                                20), // Added spacing before the first info row
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _fullName,
                        ),
                        const SizedBox(
                            height: 15), // Added spacing after Full Name
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'E-mail',
                          value: _email,
                        ),
                        const SizedBox(
                            height: 15), // Added spacing after E-mail
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
}
