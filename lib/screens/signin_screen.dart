import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'package:eatease/components/bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


final String apiUrl = "${dotenv.env['API_BASE_URL']}/users/login";

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
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');
    bool? rememberMe = prefs.getBool('remember_me');

    if (rememberMe == true && savedEmail != null && savedPassword != null) {
      // Automatically log in the user
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      await _loginUser();
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('email', email);
    prefs.setString('password', password);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
  }

  Future<void> _saveRememberMeState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('remember_me', value);
  }

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
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1.3),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
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
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
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
            borderSide: const BorderSide(color: Colors.grey, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 207, 207, 207), width: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          labelText: labelText,
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.grey,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
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
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Text(
            "Remember Me",
            style: TextStyle(fontSize: 12.3, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignupScreen()),
              );
            },
            style: TextButton.styleFrom(
              overlayColor: Colors.transparent,
              padding: EdgeInsets.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
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
        onPressed: _loginUser,
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

  Future<void> _loginUser() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    // Clear previous error message
    setState(() {
      _errorMessage = null;
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
        final data = json.decode(response.body);
        String userId = data['userId']; // Get user ID from response

        // Save userId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userId', userId);

        // Save credentials if "Remember Me" is checked
        if (_rememberMe) {
          _saveCredentials(email, password);
        } else {
          _clearCredentials();
        }

        // Navigate to BottomNav on successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  BottomNav(userId: userId)), // Pass userId to BottomNav
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
              MaterialPageRoute(builder: (context) => SignupScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
