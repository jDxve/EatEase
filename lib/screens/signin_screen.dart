import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'package:eatease/components/bottom_nav.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

final String apiUrl = (Platform.isAndroid)
    ? "http://192.168.1.244:5001/api/users/login"
    : "http://localhost:5001/api/users/login";

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _passwordVisible = false;
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.redAccent,
              Color(0xFFA60000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              _buildLogo(),
              const SizedBox(height: 30),
              _buildInputContainer(),
              if (_isLoading) // Show loading indicator if loading
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo2.png',
      width: 250,
      height: 250,
    );
  }

  Widget _buildInputContainer() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(40.0),
        topRight: Radius.circular(40.0),
      ),
      child: Container(
        width: double.infinity,
        height: 510,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40.0),
            topRight: Radius.circular(40.0),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 35),
            _buildEmailTextField(),
            const SizedBox(height: 27),
            _buildPasswordTextField(),
            // Display error message aligned to the right with left padding
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1.3),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12), // Set font size to 12
                      ),
                    ),
                ],
              ),
            ),
            _buildRememberMeAndForgotPasswordRow(),
            const SizedBox(height: 40),
            _buildSignInButton(),
            const SizedBox(height: 10),
            _buildSignupTextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTextField() {
    return _buildTextField(
      controller: _emailController,
      labelText: 'E-mail',
      prefixIcon: Icons.email,
      obscureText: false,
    );
  }

  Widget _buildPasswordTextField() {
    return _buildTextField(
      controller: _passwordController,
      labelText: 'Password',
      prefixIcon: Icons.lock,
      obscureText: !_passwordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _passwordVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _passwordVisible = !_passwordVisible;
          });
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      width: 370,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Lighter shadow
            spreadRadius: 1, // Smaller spread
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Colors.grey, width: 0.8), // Thinner border
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 207, 207, 207),
                width: 0.6), // Even thinner when not focused
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 0.9), // Slightly thicker when focused
            borderRadius: BorderRadius.circular(10),
          ),
          labelText: labelText,
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.grey,
            size: 20, // Slightly smaller icon
          ),
          suffixIcon: suffixIcon,
          labelStyle: const TextStyle(
            fontSize: 15, // Smaller font size
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Future<void> _saveRememberMeState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('remember_me', value);
  }

  Widget _buildRememberMeAndForgotPasswordRow() {
    return Transform.translate(
      offset: const Offset(0, -7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: .75, 
            child: Checkbox(
              value: _rememberMe,
              onChanged: (bool? newValue) {
                setState(() {
                  _rememberMe = newValue ?? false;
                });
                _saveRememberMeState(_rememberMe);
              },
              activeColor: Colors.redAccent,
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap, 
              visualDensity: VisualDensity.compact, 
            ),
          ),
          const Text(
            "Remember Me",
            style: TextStyle(fontSize: 12.3, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              overlayColor: Colors.transparent,
              padding: EdgeInsets.zero,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.only(right: 8), // Adjust the value as needed
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        onPressed: _loginUser, // Call the login function
        style: ElevatedButton.styleFrom(
          overlayColor: Colors.white,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Sign In",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  bool _isLoading = false;

  Future<void> _loginUser() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    // Clear previous error message
    setState(() {
      _errorMessage = null; 
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Navigate to HomeScreen on successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNav()),
        );
      } else {
        // Handle error response
        setState(() {
          _errorMessage =
              'Login failed. Please try again.'; // Set error message
        });
      }
    } catch (e) {
      // Handle exceptions
      setState(() {
      _errorMessage = 'An error occurred: $e'; 
      });
    } finally {
      // Set loading to false after the operation
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSignupTextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        ),
        const SizedBox(width: 4), 
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SignupScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Sign Up",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}
