import 'package:flutter/material.dart';
import 'package:therapist_app/core/home/home_page.dart';
import 'package:therapist_app/core/screens/auth_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String mainScreen = '/home';
  static const String auth = '/auth';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case mainScreen:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case auth:
        return MaterialPageRoute(builder: (_) => const NitiAuthScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
