// Forgot Password Screen (keeping existing implementation)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/color_constants/color_constants.dart';

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
    context.pop();
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