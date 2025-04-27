import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eatease/screens/signin_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isValidEmail = false;
  bool _isCodeSent = false;
  bool _isCodeVerified = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmailInput);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmailInput);
    _emailController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmailInput() {
    setState(() {
      _isValidEmail = _validateEmail(_emailController.text.trim());
    });
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  Future<void> _requestVerificationCode() async {
    if (!_validateEmail(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http
          .post(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/auth/request-verification-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text.trim()}),
      )
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isCodeSent = true;
          _successMessage = 'Verification code sent to your email';
        });
      } else {
        setState(() {
          _errorMessage =
              responseData['error'] ?? 'Failed to send verification code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'code': _verificationCodeController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isCodeVerified = true;
          _successMessage = 'Code verified successfully';
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
  if (_newPasswordController.text != _confirmPasswordController.text) {
    setState(() {
      _errorMessage = 'Passwords do not match';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
  });

  try {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_BASE_URL']}/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text.trim(),
        'code': _verificationCodeController.text.trim(),
        'new_password': _newPasswordController.text,
      }),
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        _successMessage = 'Password reset successfully';
      });
      

      

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SignInScreen()),
        (Route<dynamic> route) => false,
      );

    } else {
      setState(() {
        _errorMessage = responseData['error'] ?? 'Failed to reset password';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'An error occurred. Please try again.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: Color(0xFFFF7F6F), // Coral color from screenshot
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              !_isCodeSent
                  ? 'Enter your email address to receive verification code'
                  : !_isCodeVerified
                      ? 'Enter the verification code sent to your email'
                      : 'Enter your new password',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            if (!_isCodeSent) _buildEmailField(),
            if (_isCodeSent && !_isCodeVerified) _buildVerificationCodeField(),
            if (_isCodeVerified) _buildNewPasswordFields(),
            SizedBox(height: 20),
            _buildMessages(),
            SizedBox(height: 20),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(2, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _emailController.text.isNotEmpty && !_isValidEmail
                  ? Colors.red
                  : Color.fromARGB(255, 207, 207, 207),
              width: 0.6,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _isValidEmail ? Colors.redAccent : Colors.red,
              width: 0.9,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          labelText: 'Email',
          prefixIcon: Icon(
            Icons.email,
            color: Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCodeField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _verificationCodeController,
        decoration: InputDecoration(
          labelText: 'Verification Code',
          hintText: 'Enter verification code',
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildNewPasswordFields() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'New Password',
              hintText: 'Enter new password',
              prefixIcon: Icon(Icons.lock, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_isNewPasswordVisible,
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Confirm Password',
              hintText: 'Confirm your new password',
              prefixIcon: Icon(Icons.lock, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_isConfirmPasswordVisible,
          ),
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (_successMessage != null)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _successMessage!,
              style: TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        // Changed 'on :' to 'onPressed:'
        onPressed: _isLoading
            ? null
            : () {
                if (!_isCodeSent) {
                  _requestVerificationCode();
                } else if (!_isCodeVerified) {
                  _verifyCode();
                } else {
                  _resetPassword();
                }
              },
        style: ElevatedButton.styleFrom(
          // Changed 'primary' to 'backgroundColor' as 'primary' is deprecated
          backgroundColor: Colors.redAccent,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                !_isCodeSent
                    ? 'Send Verification Code'
                    : !_isCodeVerified
                        ? 'Verify Code'
                        : 'Reset Password',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
