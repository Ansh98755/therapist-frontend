import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<String?> getFcmToken() async {
    return await _messaging.getToken();
  }

  /// Initialize FCM: request permission, get token, setup listeners
  Future<void> initFCM() async {
    // 1. Request Notification Permission
    await _requestNotificationPermission();

    // 2. Get FCM Token

    // print("FCM Token: $token");

    // TODO: Send this token to your backend Express.js API
    // await sendTokenToServer(token);

    // 3. Setup Local Notifications
    await _initLocalNotifications();

    // 4. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(" Foreground message: ${message.notification?.title}");
      _showNotification(
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Body",
      );
    });

    // 5. Background message listener (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(" Background message clicked: ${message.notification?.title}");
      // Handle navigation when user taps notification
    });

    // 6. Terminated state (cold start)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print(
        " App opened from terminated state: ${initialMessage.notification?.title}",
      );
      // _handleNotificationNavigation(initialMessage);
      // Handle navigation here too
    }

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(" Background notification clicked");
      // _handleNotificationNavigation(message);
    });

    // 7. Token Refresh Listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM Token refreshed: $newToken");
      
      // await SharedPrefsHelper.setFCMToken(newToken);

      // String? token = await SharedPrefsHelper.getToken();

      // if (token != null) {
      //   try {
      //     final response = await http.post(
      //       Uri.parse("https://niti.nexuserp.co.in/api/user/VerifyToken"),
      //       headers: {
      //         "Content-Type": "application/json",
      //       },
      //       body: jsonEncode({
      //         "new_token": newToken,
      //         'Authorization': 'Bearer $token',
      //       }),
      //     );

      //     if (response.statusCode == 200) {
      //       print("Γ£à Token updated successfully: ${response.body}");
      //     } else {
      //       print(
      //           "Γ¥î Failed to update token. Status: ${response.statusCode}, Body: ${response.body}");
      //     }
      //   } catch (e) {
      //     print("ΓÜá∩╕Å Error sending token to backend: $e");
      //   }
      // } else {
      //   print("ΓÜá∩╕Å No token found");
      // }

      // TODO: Send this new token to your backend
      // await sendTokenToServer(newToken);
    });
  }

  /// Request notification permissions (for iOS & Android 13+)
  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print(
      "≡ƒöö Notification permission status: ${settings.authorizationStatus}",
    );
  }

  /// Initialize local notification settings
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initSettings);
  }

  // void _handleNotificationNavigation(RemoteMessage message) {
  //   // use global navigatorKey for GoRouter navigation
  //   rootNavigatorKey.currentContext
  //       ?.pushNamed(AppRouteEnum.notificationScreen.name);
  // }
  // void _handleNotificationNavigation(RemoteMessage message,
  //     {bool fromTerminated = false}) {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final ctx = rootNavigatorKey.currentContext;
  //     if (ctx != null) {
  //       if (fromTerminated) {
  //         // Replace route completely so GoRouter doesnΓÇÖt pop back to home
  //         ctx.goNamed(AppRouteEnum.myPostScreen.name,
  //             queryParameters: {'comingFromTerminated': 'true'});
  //       } else {
  //         // Normal push when app already running
  //         ctx.goNamed(AppRouteEnum.myPostScreen.name,
  //             queryParameters: {'comingFromTerminated': 'false'});
  //       }
  //     } else {
  //       print("ΓÜá∩╕Å Could not navigate, context is null");
  //     }
  //   });
  // }

  /// Show local notification
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(0, title, body, platformDetails);
  }
}
