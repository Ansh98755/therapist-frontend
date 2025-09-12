import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:therapist_app/home_page.dart';
import 'package:therapist_app/screens/auth_screen.dart';
import 'package:therapist_app/screens/auth_wrapper.dart';
import 'package:therapist_app/screens/community_screen.dart';
import 'package:therapist_app/screens/forgot_password.dart';
import 'package:therapist_app/screens/post_details_screen.dart';

class AppRouteNames {
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const community = '/community';
  static const newPost = '/community/new';
  static const postDetails = '/community/post'; 
  static const forgotPassword = '/forgot-password';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRouteNames.splash,
  routes: [
    GoRoute(
      path: AppRouteNames.splash,
      name: 'splash',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: AppRouteNames.auth,
      name: 'auth',
      builder: (context, state) => const NitiAuthScreen(),
    ),
    GoRoute(
      path: AppRouteNames.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRouteNames.community,
      name: 'community',
      builder: (context, state) => const CommunityScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'new-post',
          builder: (context, state) => const NewPostScreen(),
        ),
        GoRoute(
          path: 'post',
          name: 'post-details',
          builder: (context, state) {
            final post = state.extra;
            if (post is CommunityPost) {
              return PostDetailsScreen(post: post);
            }
            return const Scaffold(
              body: Center(child: Text('Invalid post data')),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRouteNames.forgotPassword,
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No route defined for: \n${state.uri.toString()}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRouteNames.splash),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
