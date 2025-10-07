import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:therapist_app/screens/community_screen/community_screen.dart';
import 'package:therapist_app/screens/home_screen/home_screen.dart';
import 'package:therapist_app/screens/new_post_screen/new_post_screen.dart';
import 'package:therapist_app/screens/profile_screen/profile_screen.dart';

import '../custom_widgets/custom_bottom_navigation.dart';
import '../screens/analytics_screen/analytics_Screen.dart';
import '../screens/community_screen/community_reply_screen.dart';
import '../screens/forgot_password/forgot_password.dart';
import '../screens/login_screen/auth_wrapper.dart';
import '../screens/login_screen/login_screen.dart';
import '../screens/my_post_screen/my_post_screen.dart';
import '../screens/notification_screen/notification_screen.dart';

part 'app_route_enum.dart';
part 'app_route_names.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final String initRouteLocation = AppRouteEnum.splashScreen.path;

abstract final class AppRouting {
  static final appRouter = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initRouteLocation,
    routes: [
      /// Splash / Auth Wrapper
      GoRoute(
        path: AppRouteEnum.splashScreen.path,
        name: AppRouteEnum.splashScreen.name,
        builder: (context, state) => const AuthWrapper(),
      ),

      /// Auth Screen
      GoRoute(
        path: AppRouteEnum.loginScreen.path,
        name: AppRouteEnum.loginScreen.name,
        builder: (context, state) => const LoginScreen(),
      ),

      /// ---- Main App Shell with BottomNavigation ----
      ShellRoute(
        builder: (context, state, child) {
          return CustomBottomNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: AppRouteEnum.homeScreen.path,
            name: AppRouteEnum.homeScreen.name,
            builder: (context, state) => HomeScreen(),
          ),
          GoRoute(
            path: AppRouteEnum.analyticsScreen.path,
            name: AppRouteEnum.analyticsScreen.name,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRouteEnum.profileScreen.path,
            name: AppRouteEnum.profileScreen.name,
            builder: (context, state) => ProfileScreen(),
          ),
          GoRoute(
            path: AppRouteEnum.notificationScreen.path,
            name: AppRouteEnum.notificationScreen.name,
            builder: (context, state) => NotificationScreen(),
          ),
          GoRoute(
            name: AppRouteEnum.myPostScreen.name,
            path: AppRouteEnum.myPostScreen.path,
            builder: (context, state) => MyPostScreen(),
          ),
          GoRoute(
            path: AppRouteEnum.communityScreen.path,
            name: AppRouteEnum.communityScreen.name,
            builder: (context, state) => CommunityScreen(),
          ),
          GoRoute(
            path: AppRouteEnum.communityReplyScreen.path,
            name: AppRouteEnum.communityReplyScreen.name,
            pageBuilder: (context, state) {
              // extract Map
              final args = state.extra as Map<String, dynamic>? ?? {};
              final postId = args['postId'] as String? ?? '';
              final postedById = args['postedById'] as String? ?? '';

              return CustomTransitionPage(
                transitionDuration: const Duration(milliseconds: 400),
                child: RepliesScreen(postId: postId, postedById: postedById),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      final offsetAnimation =
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          );

                      final fadeAnimation = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(animation);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: child,
                        ),
                      );
                    },
              );
            },
          ),

          /// Post Details
          // GoRoute(
          //   path: AppRouteEnum.postDetailsScreen.path,
          //   name: AppRouteEnum.postDetailsScreen.name,
          //   pageBuilder: (context, state) {
          //     final post = state.extra;
          //     if (post is CommunityPost) {
          //       return CustomTransitionPage(
          //         child: PostDetailsScreen(post: post),
          //         transitionDuration: const Duration(milliseconds: 400),
          //         transitionsBuilder:
          //             (context, animation, secondaryAnimation, child) {
          //           final offsetAnimation = Tween<Offset>(
          //             begin: const Offset(1.0, 0.0),
          //             end: Offset.zero,
          //           ).animate(CurvedAnimation(
          //             parent: animation,
          //             curve: Curves.easeInOut,
          //           ));
          //
          //           final fadeAnimation = Tween<double>(
          //             begin: 0.0,
          //             end: 1.0,
          //           ).animate(animation);
          //
          //           return SlideTransition(
          //             position: offsetAnimation,
          //             child: FadeTransition(
          //               opacity: fadeAnimation,
          //               child: child,
          //             ),
          //           );
          //         },
          //       );
          //     }
          //     return const MaterialPage(
          //       child: Scaffold(
          //         body: Center(child: Text('Invalid post data')),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),

      /// Forgot Password
      GoRoute(
        path: AppRouteEnum.forgotPasswordScreen.path,
        name: AppRouteEnum.forgotPasswordScreen.name,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRouteEnum.newPostScreen.path,
        name: AppRouteEnum.newPostScreen.name,
        builder: (context, state) => const NewPostScreen(),
      ),
    ],

    /// Error Page
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
              onPressed: () => context.go(AppRouteEnum.splashScreen.path),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static BuildContext get rootNavigatorKeyContext =>
      rootNavigatorKey.currentContext!;
}
