import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:therapist_app/core/shared_pref.dart';
import '../../utils/color_constants/color_constants.dart';
import '../../utils/text_style_constants/text_style_constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await SharedPrefService().getToken();
      if (token == null) {
        print("No token found in SharedPreferences");
        setState(() => _isLoading = false);
        return;
      }

      print("Using token: $token");

      final response = await http.post(
        Uri.parse("https://niti.nexuserp.co.in/api/post/getNotifications"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📡 API Status: ${response.statusCode}");
      print("📩 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> apiNotifications = data['notifications'] ?? [];

        if (apiNotifications.isEmpty) {
          _notifications = [];
        } else {
          print("✅ Notifications loaded from API (${apiNotifications.length})");
          _notifications = apiNotifications.cast<Map<String, dynamic>>();
        }
      } else {
        print("❌ Error: ${response.statusCode} ${response.body}");
        _hasError = true;
      }
    } catch (e) {
      _hasError = true;
      print("❌ Exception while fetching notifications: $e");
    }

    setState(() => _isLoading = false);
  }

  // String _formatDateTime(String dateTimeStr) {
  //   try {
  //     final dateTime =
  //         DateTime.parse(dateTimeStr); // assumes ISO 8601 string from API
  //     return DateFormat("dd MMM yyyy • hh:mm a").format(dateTime);
  //   } catch (e) {
  //     return dateTimeStr; // fallback in case parsing fails
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: ColorConstants.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyleConstants.inter20W600
              .copyWith(color: ColorConstants.blackColor),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Failed to load notifications"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchNotifications,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No notifications yet",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade300),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];

                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      ColorConstants.primaryBrownColor,
                                  child: Icon(Icons.notifications,
                                      color: ColorConstants.whiteColor2),
                                ),
                                if (notification["seen"] == false)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color:
                                            ColorConstants.primaryOrangeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                                notification["user_name"] ?? "Unknown User",
                                style: TextStyleConstants.inter14W600.copyWith(
                                    color: ColorConstants.blackColor)),
                            subtitle: Text(
                                notification["notification_body"] ?? "",
                                style: TextStyleConstants.inter14W400.copyWith(
                                    color: ColorConstants.blackColor)),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    DateFormat("dd MMM yyyy").format(
                                        DateTime.parse(
                                            notification["created_at"])),
                                    style: TextStyleConstants.inter12W500
                                        .copyWith(
                                            color: ColorConstants.hintColor)),
                                Text(
                                    DateFormat("hh:mm a").format(DateTime.parse(
                                        notification["created_at"])),
                                    style: TextStyleConstants.inter10W400
                                        .copyWith(
                                            color: ColorConstants.hintColor)),
                              ],
                            ),
                            onTap: () async {
                              print("notification data $notification");
                              print(
                                  "Tapped notification: ${notification['post_id']}");
                              // Check if the notification body contains "liked"
                              final notificationBody =
                                  notification["notification_body"] ?? "";
                              final likeFound = notificationBody
                                  .toLowerCase()
                                  .contains("liked");

                              print("likeFound: $likeFound");

                              try {
                                // 1. Get token from SharedPrefsHelper
                                final token = await SharedPrefService()
                                    .getToken(); // adjust method name if different

                                // 2. Prepare request body
                                final body = {
                                  "notificationId":
                                      notification['notification_id'],
                                  "created_at": notification['created_at'],
                                };

                                // 3. Make API call
                                final response = await http.post(
                                  Uri.parse(
                                      "https://niti.nexuserp.co.in/api/post/updateToSeenNotification"),
                                  headers: {
                                    "Content-Type": "application/json",
                                    "Authorization": "Bearer $token",
                                  },
                                  body: jsonEncode(body),
                                );
                                print(
                                    "Response status: ${response.statusCode}");
                                if (response.statusCode == 200 ||
                                    response.statusCode == 204) {
                                  print("✅ Notification marked as seen");
                                } else {
                                  print(
                                      "❌ Failed to update notification: ${response.body}");
                                }
                              } catch (e) {
                                print(
                                    "⚠️ Error while updating notification: $e");
                              }

                              context.pop({
                                "postId": notification["post_id"],
                                "userId": notification["user_id"],
                                "likeFound": likeFound,
                              });
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
