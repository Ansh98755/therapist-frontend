import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:therapist_app/core/api_service.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/core/shared_pref.dart';
import 'package:therapist_app/firebase/fcm/fcm_service.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class NitiAuthScreen extends StatefulWidget {
  const NitiAuthScreen({Key? key}) : super(key: key);

  @override
  State<NitiAuthScreen> createState() => _NitiAuthScreenState();
}

class _NitiAuthScreenState extends State<NitiAuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      print('=== LOGIN ATTEMPT ===');
      print('Phone: ${_phoneController.text}');
      print('Password: [HIDDEN]');

      final result = await _apiService.login(
        _phoneController.text,
        _passwordController.text,
      );

      print('=== LOGIN RESULT ===');
      print('Success: ${result['success']}');
      print('Result keys: ${result.keys}');

      if (result['success'] == true) {
        // Extract token and user data from the API response
        String? token;
        Map<String, dynamic>? userData;
        if (result['token'] != null) {
          token = result['token'].toString();
        }

        if (result['data'] is Map<String, dynamic>) {
          userData = Map<String, dynamic>.from(result['data']);

          if (token == null) {
            token =
                userData['token']?.toString() ??
                userData['accessToken']?.toString() ??
                userData['authToken']?.toString() ??
                userData['access_token']?.toString();
          }
        }

        print('=== EXTRACTED DATA ===');
        print(
          'Token: ${token?.isNotEmpty == true ? "${token!.substring(0, 20)}..." : "null/empty"}',
        );
        print('UserData keys: ${userData?.keys}');

        if (userData != null) {
          // If no token provided by API, generate a temporary one
          // This depends on your backend authentication strategy
          if (token == null || token.isEmpty) {
            // Option 1: Use therapist ID as token (if backend allows)
            token =
                userData['_id']?.toString() ??
                userData['id']?.toString() ??
                'session_${DateTime.now().millisecondsSinceEpoch}';

            print('Generated fallback token: $token');
          }

          // Save auth data
          final saveSuccess = await _authService.saveAuthData(token, userData);

          String? fcmToken = await FCMService().getFcmToken();
          print("token before calling fcm token endpoint $token");
          print(userData);
          if (fcmToken != null) {
            try {
              final response = await http.post(
                Uri.parse(
                  "https://niti.nexuserp.co.in/api/verifyTherapistToken",
                ),
                headers: {
                  "Content-Type": "application/json",
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({"new_token": fcmToken}),
              );

              if (response.statusCode == 200) {
                print(" Token updated successfully: ${response.body}");
              } else {
                print(
                  " Failed to update token. Status: ${response.statusCode}, Body: ${response.body}",
                );
              }
            } catch (e) {
              print(" Error sending token to backend: $e");
            }
          }

          if (saveSuccess) {
            print('=== LOGIN SUCCESS ===');

            // Verify therapist ID extraction
            final therapistId = await _authService.getTherapistId();
            print('Extracted therapist ID: $therapistId');

            setState(() => _isLoading = false);

            if (mounted) {
              // Navigate to home and clear the navigation stack
              if (context.mounted) {
                context.go('/home');
              }
            }
          } else {
            setState(() => _isLoading = false);
            _showError('Failed to save authentication data');
          }
        } else {
          setState(() => _isLoading = false);
          _showError('Invalid response: missing user data');
          print('Login failed: userData is null');
        }
      } else {
        setState(() => _isLoading = false);
        _showError(
          result['error'] ?? 'Login failed. Please check your credentials.',
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      print('Login exception: $error');
      _showError('An unexpected error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ColorConstants.redColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorConstants.colorF5F5F5,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                SizedBox(height: size.height * 0.08),
                _buildLogo(),
                SizedBox(height: size.height * 0.08),
                _buildWelcomeText(),
                SizedBox(height: size.height * 0.06),
                _buildLoginForm(),
                SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.colorBlack12,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 35,
            color: ColorConstants.primaryOrangeColor,
          ),
          const SizedBox(height: 4),
          const Text(
            'Niti',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorConstants.primaryBrownColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ColorConstants.primaryBrownColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 16,
            color: ColorConstants.color999999,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.colorBlack12,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildPhoneField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildForgotPasswordButton(),
            const SizedBox(height: 24),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorConstants.primaryBrownColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
              return 'Please enter a valid 10-digit phone number';
            }
            return null;
          },
          decoration: _buildInputDecoration('Enter your phone number'),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorConstants.primaryBrownColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: _buildInputDecoration(
            'Enter your password',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: ColorConstants.color999999,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: ColorConstants.color999999.withOpacity(0.7),
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: ColorConstants.colorF9F9F9,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorConstants.colorE0E0E0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: ColorConstants.primaryOrangeColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ColorConstants.redColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/forgot-password');
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: ColorConstants.primaryOrangeColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryBrownColor,
          foregroundColor: ColorConstants.whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.whiteColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Signing in...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
