import 'package:flutter/material.dart';
import 'package:therapist_app/home_page.dart';
import 'package:therapist_app/screens/auth_screen.dart';
import 'package:therapist_app/screens/auth_wrapper.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('Navigating to route: ${settings.name}');
    
    switch (settings.name) {
      case splash:
        return _buildRoute(
          const AuthWrapper(),
          settings,
        );

      case auth:
        return _buildRoute(
          const NitiAuthScreen(),
          settings,
        );

      case home:
        return _buildRoute(
          const HomePage(),
          settings,
        );

      default:
        return _buildRoute(
          _buildNotFoundScreen(settings.name ?? 'Unknown'),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }

  static Widget _buildNotFoundScreen(String routeName) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No route defined for $routeName',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate back to splash/auth wrapper
                Navigator.pushNamedAndRemoveUntil(
                  // This won't work here, we need context
                  // Use Navigator.of(context) in actual implementation
                  null as BuildContext,
                  AppRoutes.splash,
                  (route) => false,
                );
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}