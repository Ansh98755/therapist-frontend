import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import '../../api_services/auth_services.dart';
import '../splash_screen/splash_screen.dart';
import '../../routes/app_routing.dart';

/// THIS CLASS IS USED TO CHECK WETHER THE USER LOGGED IN OR NOT
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

    // Listen to auth state changes
    _authStateSubscription = AuthService.authStateStream.listen((isLoggedIn) async {
      if (mounted) {
        final actualAuthStatus = await _authService.isLoggedIn();
        setState(() {
          _isLoggedIn = actualAuthStatus;
          _isInitializing = false;
        });

        if (actualAuthStatus) {
          context.go(AppRouteEnum.homeScreen.path);
        } else {
          context.go(AppRouteEnum.loginScreen.path);
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final isLoggedIn = await _authService.isLoggedIn();

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isInitializing = false;
        });

        if (isLoggedIn) {
          context.go(AppRouteEnum.homeScreen.path);
        } else {
          context.go(AppRouteEnum.loginScreen.path);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isInitializing = false;
        });
        context.go(AppRouteEnum.loginScreen.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SplashScreen();
    }

    return const SizedBox.shrink();
  }
}
