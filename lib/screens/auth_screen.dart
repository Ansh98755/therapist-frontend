import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:therapist_app/core/api_service.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/home_page.dart';
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
      print('Attempting login with phone: ${_phoneController.text}');

      final result = await _apiService.login(
        _phoneController.text,
        _passwordController.text,
      );

      print('Login API result: $result');

      if (result['success'] == true) {
        final data = result['data'];

        // Handle different possible response structures
        String? token;
        Map<String, dynamic>? userData;

        if (data is Map<String, dynamic>) {
          // Try top-level token fields
          token =
              data['token'] ??
              data['accessToken'] ??
              data['authToken'] ??
              data['access_token'];

          // If token not found at top level, check nested 'data' or other nested objects
          if (token == null) {
            final nested =
                data['data'] ??
                data['user'] ??
                data['therapist'] ??
                data['profile'];
            if (nested is Map<String, dynamic>) {
              token =
                  nested['token'] ??
                  nested['accessToken'] ??
                  nested['authToken'] ??
                  nested['access_token'];
            }
          }

          // Try to extract user data from different possible locations (top-level or nested)
          userData = data['user'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['user'])
              : data['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['data'])
              : data['therapist'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['therapist'])
              : data['psychologist'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['psychologist'])
              : null;

          // As a last resort, use the entire response object (minus obvious token fields)
          if (userData == null) {
            userData = Map<String, dynamic>.from(data);
            userData.remove('token');
            userData.remove('accessToken');
            userData.remove('authToken');
            userData.remove('access_token');
          }
        }

        String tokenPreview = token == null
            ? 'null'
            : (token.length > 20 ? '${token.substring(0, 20)}...' : token);
        print('Extracted token: $tokenPreview');
        print('Extracted user data: $userData');

        if (token != null && token.isNotEmpty && userData != null) {
          final saveSuccess = await _authService.saveAuthData(token, userData);

          if (saveSuccess) {
            setState(() => _isLoading = false);
            print('Login successful, auth data saved');
            print('Auth state should now trigger AuthWrapper rebuild...');
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          } else {
            setState(() => _isLoading = false);
            _showError('Failed to save authentication data');
          }
        } else {
          setState(() => _isLoading = false);
          _showError('Invalid response: missing token or user data');
          print('Login failed: token=$token, userData=$userData');
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            ),
          );
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_phoneController.text.length != 10) {
      _showMessage('Please enter a valid 10-digit phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    _showMessage('OTP sent to your phone number');
  }

  void _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showMessage('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    _showMessage('Password reset link sent to your registered email');
    Navigator.pop(context);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? ColorConstants.redColor
            : ColorConstants.color2E7D7D,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.colorF5F5F5,
      appBar: AppBar(
        backgroundColor: ColorConstants.transparentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: ColorConstants.primaryBrownColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildResetPasswordHeader(),
            const SizedBox(height: 32),
            _buildResetPasswordForm(),
            const SizedBox(height: 24),
            _buildBackToLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResetPasswordHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.colorBlack12,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorConstants.primaryOrangeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: ColorConstants.primaryOrangeColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Reset Your Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _otpSent
                ? 'Enter the OTP sent to your phone number'
                : 'Enter your phone number to receive an OTP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: ColorConstants.color999999,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.colorBlack12,
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_otpSent) ..._buildPhoneInput() else ..._buildOtpInput(),
          const SizedBox(height: 32),
          _buildActionButton(),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneInput() {
    return [
      const Text(
        'Phone Number',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ColorConstants.primaryBrownColor,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        decoration: InputDecoration(
          hintText: 'Enter your 10-digit phone number',
          prefixIcon: Icon(
            Icons.phone_android,
            color: ColorConstants.primaryOrangeColor,
          ),
          border: _buildOutlineInputBorder(),
          enabledBorder: _buildOutlineInputBorder(),
          focusedBorder: _buildOutlineInputBorder(
            ColorConstants.primaryOrangeColor,
          ),
          counterText: '',
        ),
      ),
    ];
  }

  List<Widget> _buildOtpInput() {
    return [
      const Text(
        'Enter OTP',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ColorConstants.primaryBrownColor,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          hintText: 'Enter 6-digit OTP',
          prefixIcon: Icon(
            Icons.verified_user,
            color: ColorConstants.primaryOrangeColor,
          ),
          border: _buildOutlineInputBorder(),
          enabledBorder: _buildOutlineInputBorder(),
          focusedBorder: _buildOutlineInputBorder(
            ColorConstants.primaryOrangeColor,
          ),
          counterText: '',
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              _otpSent = false;
              _otpController.clear();
            });
            _sendOtp();
          },
          child: const Text(
            'Resend OTP',
            style: TextStyle(
              color: ColorConstants.primaryOrangeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  OutlineInputBorder _buildOutlineInputBorder([Color? borderColor]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: borderColor ?? ColorConstants.colorE0E0E0,
        width: borderColor != null ? 2 : 1,
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryOrangeColor,
          foregroundColor: ColorConstants.whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                _otpSent ? 'Verify OTP & Reset Password' : 'Send OTP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back,
          color: ColorConstants.primaryBrownColor,
          size: 18,
        ),
        label: const Text(
          'Back to Login',
          style: TextStyle(
            color: ColorConstants.primaryBrownColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
