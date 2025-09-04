import 'package:flutter/material.dart';
import 'package:therapist_app/home_page.dart';
import 'package:therapist_app/screens/auth_screen.dart';
import 'package:therapist_app/core/authservices.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
import 'dart:async';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  bool? _isLoggedIn;
  final AuthService _authService = AuthService();
  StreamSubscription<bool>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();

    // Listen to auth state changes with proper subscription management
    print(
      'AuthWrapper: creating auth state subscription - before subscribe, hasListener=${AuthService.hasAuthListeners}',
    );
    _authStateSubscription = AuthService.authStateStream.listen((
      isLoggedIn,
    ) async {
      print(
        'AuthWrapper subscription callback entered (stream event received)',
      );
      if (mounted) {
        print('Auth state changed via stream: $isLoggedIn');
        // Double-check the actual auth status to be sure
        final actualAuthStatus = await _authService.isLoggedIn();
        print('Actual auth status after stream event: $actualAuthStatus');
        setState(() {
          _isLoggedIn = actualAuthStatus;
          _isInitializing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    print('AuthWrapper: disposing auth state subscription');
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    try {
      print('Initializing auth...');

      // Add a small delay to prevent rapid state changes
      await Future.delayed(const Duration(milliseconds: 100));

      // Check initial auth status
      final isLoggedIn = await _authService.isLoggedIn();

      print('Initial auth check result: $isLoggedIn');

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error initializing auth: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'AuthWrapper build - initializing: $_isInitializing, loggedIn: $_isLoggedIn',
    );

    if (_isInitializing) {
      return const SplashScreen();
    }

    final isLoggedIn = _isLoggedIn ?? false;

    // Use AnimatedSwitcher for smooth transitions
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoggedIn
          ? const HomePage(key: ValueKey('home'))
          : const NitiAuthScreen(key: ValueKey('auth')),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.colorF5F5F5,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor,
                borderRadius: BorderRadius.circular(24),
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
                    size: 45,
                    color: ColorConstants.primaryOrangeColor,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Niti',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryBrownColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryBrownColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: ColorConstants.color999999,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
