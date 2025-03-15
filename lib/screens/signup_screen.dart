import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'signin_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:email_validator/email_validator.dart'; // Add this import for email validation
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String apiUrl = "${dotenv.env['API_BASE_URL']}/users/register";

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _passwordVisible = false;
  bool _isChecked = false;
  bool _confirmPasswordVisible = false;
  final ScrollController _scrollController = ScrollController();

  // Add controllers for text fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State variables for error messages
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _termsError;

  // State variable for notification banner
  bool _showNotification = false;
  String _notificationMessage = '';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 10.5; // Base font size
    double responsiveFontSize = baseFontSize * (screenWidth / 375);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        leadingWidth: 30,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Sign Up',
              style: TextStyle(
                  fontSize: responsiveFontSize * 1.5,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildYourDetails(responsiveFontSize),
                _buildNameTextField(),
                const SizedBox(height: 8),
                _buildEmailTextField(),
                if (_emailError != null) // Show email error if exists
                  Padding(
                    padding: const EdgeInsets.only(left: 23.0),
                    child: Text(
                      _emailError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                _buildPhoneNumberTextField(),
                if (_phoneError != null) // Show phone error if exists
                  Padding(
                    padding: const EdgeInsets.only(left: 23.0),
                    child: Text(
                      _phoneError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                _buildPasswordTextField(),
                const SizedBox(height: 8),
                _buildConfirmPasswordTextField(),
                if (_passwordError != null) // Show password error if exists
                  Padding(
                    padding: const EdgeInsets.only(left: 23.0),
                    child: Text(
                      _passwordError!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                _buildTermsAndCondition(context, responsiveFontSize),
                if (_termsError != null) // Show terms error if exists
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 23.0),
                      child: Text(
                        _termsError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center, // Center the text
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
                _buildSignUpButton(),
                const SizedBox(height: 8),
                _buildAlreadyHaveAccountText()
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 7,
              color: const Color(0xFFA60000),
              width: double.infinity,
            ),
          ),
          // Notification Banner
          if (_showNotification)
            Positioned(
              top: 10, // Adjust the position as needed
              left: 0,
              right: 0,
              child: Container(
                color: Colors.deepOrange, // Background color for success
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _notificationMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYourDetails(double responsiveFontSize) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 21.0),
      child: Text(
        'Enter Your Details Here',
        style: TextStyle(
          fontSize: responsiveFontSize * 1.5,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildNameTextField() {
    return _buildTextField(
      controller: _fullNameController,
      labelText: 'Full Name',
      obscureText: false,
    );
  }

  Widget _buildEmailTextField() {
    return _buildTextField(
        controller: _emailController, labelText: 'E-mail', obscureText: false);
  }

  Widget _buildPhoneNumberTextField() {
    return _buildTextField(
      controller: _phoneController,
      labelText: 'Phone Number',
      obscureText: false,
    );
  }

  Widget _buildPasswordTextField() {
    return _buildTextField(
      controller: _passwordController,
      labelText: 'Password',
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

  Widget _buildConfirmPasswordTextField() {
    return _buildTextField(
      controller: _confirmPasswordController,
      labelText: 'Confirm Password',
      obscureText: !_confirmPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _confirmPasswordVisible = !_confirmPasswordVisible;
          });
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(
              color: Colors.grey, fontSize: 17, fontWeight: FontWeight.w500),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 17.0, horizontal: 20.0),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Color.fromARGB(255, 188, 187, 187), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildTermsAndCondition(
      BuildContext context, double responsiveFontSize) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 17),
            child: Transform.translate(
              offset: const Offset(0, -9),
              child: Transform.scale(
                scale: 0.70,
                child: Checkbox(
                  value: _isChecked,
                  activeColor: Colors.redAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.black,
                  fontSize: responsiveFontSize,
                ),
                children: [
                  const TextSpan(text: 'By signing up, you accept our '),
                  TextSpan(
                    text: 'terms of use',
                    style: const TextStyle(color: Colors.red),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showLegalDialog(context, 'terms'),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: ' privacy policy',
                    style: const TextStyle(color: Colors.red),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showLegalDialog(context, 'privacy'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String section) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section == 'terms' ? 'Terms of Service' : 'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 5),
              Text(
                'Last Updated on 2/19/2025',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          content: Container(
            height: double.infinity,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (section == 'terms'
                        ? [
                            {
                              'id': 'acceptance',
                              'title': '1. Acceptance of Terms',
                              'content':
                                  'By accessing or using our mobile application "EatEase," you agree to comply with these Terms.'
                            },
                            {
                              'id': 'use',
                              'title': '2. Use of the Service',
                              'content':
                                  'You must be at least 18 years old or have parental consent to use the app.'
                            },
                            {
                              'id': 'payments',
                              'title': '3. Ordering and Payments',
                              'content':
                                  'Orders placed through the app are binding once confirmed by the eatery.'
                            },
                            {
                              'id': 'refunds',
                              'title': '4. Cancellations and Refunds',
                              'content':
                                  'Cancellation policies are set by individual eateries.'
                            },
                            {
                              'id': 'conduct',
                              'title': '5. User Conduct',
                              'content':
                                  'You agree not to misuse the platform, including fraudulent activities, abusive behavior, or spamming.'
                            },
                            {
                              'id': 'liability',
                              'title': '6. Limitation of Liability',
                              'content':
                                  'EatEase acts as a facilitator between users and eateries.'
                            },
                            {
                              'id': 'changes',
                              'title': '7. Changes to Terms',
                              'content':
                                  'We reserve the right to update these Terms at any time.'
                            },
                            {
                              'id': 'contact',
                              'title': '8. Contact Us',
                              'content':
                                  'For any questions or concerns, contact us at [Your Email].'
                            },
                          ]
                        : [
                            {
                              'id': 'collection',
                              'title': '1. Information Collection',
                              'content':
                                  'We collect personal data such as name, email, and location for better service.'
                            },
                            {
                              'id': 'usage',
                              'title': '2. How We Use Your Information',
                              'content':
                                  'Your data is used for order processing, customer support, and app improvements.'
                            },
                            {
                              'id': 'sharing',
                              'title': '3. Data Sharing and Disclosure',
                              'content':
                                  'We do not sell or share your data with third parties except as required by law.'
                            },
                            {
                              'id': 'security',
                              'title': '4. Data Security',
                              'content':
                                  'We implement strong security measures to protect your personal data.'
                            },
                            {
                              'id': 'cookies',
                              'title': '5. Cookies and Tracking Technologies',
                              'content':
                                  'Our app may use cookies and analytics tools to enhance your experience.'
                            },
                            {
                              'id': 'rights',
                              'title': '6. Your Privacy Rights',
                              'content':
                                  'You have the right to request access, correction, or deletion of your personal data.'
                            },
                            {
                              'id': 'changes',
                              'title': '7. Changes to This Policy',
                              'content':
                                  'We may update this Privacy Policy from time to time. Please review it periodically.'
                            },
                            {
                              'id': 'contact',
                              'title': '8. Contact Us',
                              'content':
                                  'For any privacy concerns, contact us at [Your Email].'
                            },
                          ])
                    .map<Widget>((section) {
                  return _buildSection(section['title']!, section['content']!);
                }).toList(),
              ),
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Center(
                child: SizedBox(
                  width: 150, // Adjust the width of the button
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Set background to black
                      foregroundColor: Colors.white, // Set text color to white
                      minimumSize: Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Adjust border radius
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isChecked = true; // Check the checkbox when accepted
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text('I Accept'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Corrected here
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(content),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Center(
      child: SizedBox(
        width: 250,
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            String fullName = _fullNameController.text;
            String email = _emailController.text;
            String phone = _phoneController.text;
            String password = _passwordController.text;
            String confirmPassword = _confirmPasswordController.text;

            // Reset error messages
            setState(() {
              _emailError = null;
              _phoneError = null;
              _passwordError = null;
              _termsError = null; // Reset terms error
              _showNotification = false; // Hide notification initially
            });

            // Check if the terms and conditions are accepted
            if (!_isChecked) {
              setState(() {
                _termsError =
                    'You must accept the terms of use and privacy policy.';
              });
              return; // Exit the function if not checked
            }

            if (!EmailValidator.validate(email)) {
              setState(() {
                _emailError = 'Invalid email format.';
              });
              return;
            }
            if (phone.isEmpty || phone.length < 10) {
              setState(() {
                _phoneError = 'Please enter a valid phone number.';
              });
              return;
            }
            if (!isPasswordStrong(password)) {
              setState(() {
                _passwordError = 'Password must be at least 8 characters long, '
                    'include an uppercase letter, a lowercase letter, a number, '
                    'and a special character.';
              });
              return;
            }
            if (password != confirmPassword) {
              setState(() {
                _passwordError =
                    'The passwords do not match. Please try again.';
              });
              return;
            }

            var response = await http.post(
              Uri.parse(apiUrl), // Use the global constant here
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "fullName": fullName,
                "email": email,
                "phone": phone,
                "password": password
              }),
            );
            print("Response status: ${response.statusCode}");
            print("Response body: ${response.body}");
            // Handle the response
            if (response.statusCode == 201) {
              print("✅ User registered successfully!");
              setState(() {
                _notificationMessage = "User  registered successfully!";
                _showNotification = true; // Show notification
              });

              // Delay for 3 seconds and then navigate to SignInScreen
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  _showNotification =
                      false; // Hide notification after 3 seconds
                });

                // Navigate to SignInScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              });
            } else {
              print("❌ Registration failed: ${response.body}");
              setState(() {
                _notificationMessage =
                    "Registration failed: E-mail already used.";
                _showNotification = true; // Show notification
              });

              // Delay for 3 seconds and then hide the notification
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  _showNotification =
                      false; // Hide notification after 3 seconds
                });
              });
            }
          },
          style: ElevatedButton.styleFrom(
            overlayColor: Colors.white,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Sign Up",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  bool isPasswordStrong(String password) {
    // Check for minimum length
    if (password.length < 8) return false;

    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Check for digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;

    return true; // Password is strong
  }

  Widget _buildAlreadyHaveAccountText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account?",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignInScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Sign In",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}
