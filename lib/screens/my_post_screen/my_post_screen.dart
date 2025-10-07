import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:therapist_app/core/shared_pref.dart';
import '../../utils/color_constants/color_constants.dart';
import '../../utils/text_style_constants/text_style_constants.dart';
import 'custom_my_post_widgets/comment_bottom_sheet.dart';
import 'custom_my_post_widgets/highlight_post_widget.dart';

class MyPostScreen extends StatefulWidget {
  const MyPostScreen({super.key});

  @override
  State<MyPostScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostScreen> {
  List<dynamic> posts = [];
  bool isLoading = true;

  /// For editing
  final Map<int, bool> isEditing = {};
  final Map<int, TextEditingController> titleControllers = {};
  final Map<int, TextEditingController> bodyControllers = {};

  /// For show more/less
  final Map<int, bool> isExpanded = {};

  /// For per-post deletion loader
  final Map<int, bool> isDeletingPost = {};
  bool _handledComingFromCommunity = false;
  final Map<String, bool> highlightedPosts = {};

  @override
  void initState() {
    super.initState();
    fetchPosts();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkIfComingFromCommunity();
    // });

    // _loadNotificationCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_handledComingFromCommunity) {
      _handledComingFromCommunity = true; // ensure it runs only once
      _checkIfComingFromCommunity();
    }
  }

  Future<void> _checkIfComingFromCommunity() async {
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>?;

    if (extra != null && extra['comingFromCommunity'] == true) {
      final postId = extra['postId'];
      final userId = extra['userId'];
      final likeFound = extra['likeFound'] ?? false;
      await fetchPosts(); // make sure posts are loaded

      final matchedPost = posts.firstWhere(
        (post) => post['_id'] == postId,
        orElse: () => null,
      );

      if (matchedPost != null) {
        print("found post ...");
        final postTitle = matchedPost['title'];

        // open bottom sheet after UI is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // if (mounted) {
          //   openCommentsSheet(postId, postTitle, userID: userId);
          // }
          if (!mounted) return;

          if (likeFound) {
            // Highlight the post for 2 seconds
            setState(() => highlightedPosts[postId] = true);

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => highlightedPosts[postId] = false);
              }
            });
          } else {
            // Open comments as usual
            openCommentsSheet(
                postId,
                postTitle,
                userID: userId,
                mounted,
                context,
                fetchCommentsForPost);
          }
        });
      } else {
        print("not found post ...");
      }
    }
  }

  // Future<void> _loadNotificationCount() async {
  //   final count = await _fetchNotificationCount();
  //   setState(() {
  //     _notificationCount = count;
  //   });
  // }

  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    final url = Uri.parse('https://niti.nexuserp.co.in/api/getWallById');
    final token = await SharedPrefService().getToken();
    print('Fetched Token: $token');

    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        posts = data['posts'] ?? [];
        isLoading = false;
        _rebuildControllers();
      });
    } else {
      setState(() => isLoading = false);
      print('Error: ${response.reasonPhrase}');
      _showFlushBar(context,
          message: "Failed to fetch posts", color: Colors.red);
    }
  }

  void _rebuildControllers() {
    isEditing.clear();
    isExpanded.clear();
    titleControllers.forEach((_, controller) => controller.dispose());
    bodyControllers.forEach((_, controller) => controller.dispose());
    titleControllers.clear();
    bodyControllers.clear();
    isDeletingPost.clear();

    for (int i = 0; i < posts.length; i++) {
      isEditing[i] = false;
      isExpanded[i] = false;
      isDeletingPost[i] = false;
      titleControllers[i] =
          TextEditingController(text: posts[i]['title'] ?? '');
      bodyControllers[i] = TextEditingController(text: posts[i]['body'] ?? '');
    }
  }

  String formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  Future<void> updatePost(int index) async {
    final postId = posts[index]['_id'];
    final url =
        Uri.parse('https://niti.nexuserp.co.in/api/post/update/$postId');
    final token = await SharedPrefService().getToken();

    final body = {
      "body": bodyControllers[index]?.text ?? '',
      "title": titleControllers[index]?.text ?? '',
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('Update Status Code: ${response.statusCode}');
      print('Update Response: ${response.body}');

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['resSuccess'] == 1) {
          setState(() {
            posts[index]['title'] = titleControllers[index]?.text;
            posts[index]['body'] = bodyControllers[index]?.text;
            isEditing[index] = false;
          });
          _showFlushBar(
            context,
            message: res['message'] ?? "Post updated successfully",
            color: Colors.green,
          );
        } else {
          _showFlushBar(
            context,
            message: res['message'] ?? "Failed to update post",
            color: Colors.red,
          );
        }
      } else {
        _showFlushBar(
          context,
          message: "Error updating post",
          color: Colors.red,
        );
      }
    } catch (e) {
      print("Error updating post: $e");
      _showFlushBar(
        context,
        message: "Something went wrong",
        color: Colors.red,
      );
    }
  }

  void _showFlushBar(BuildContext context,
      {required String message, required Color color}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: color,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(
        color == Colors.green ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    ).show(context);
  }

  Future<List<Map<String, dynamic>>> fetchCommentsForPost(String postId) async {
    try {
      final token = await SharedPrefService().getToken();
      final url =
          Uri.parse('https://niti.nexuserp.co.in/api/post/getComments/$postId');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );
      print('Fetch posts Status Code: ${response.statusCode}');
      print('Fetch posts Response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['response'] ?? []);
      }
    } catch (e) {
      debugPrint('[ERROR Fetching Comments] $e');
    }
    return [];
  }

  // Delete post method
  Future<void> deletePost(String postId, int index) async {
    if (!mounted) return;
    setState(() => isDeletingPost[index] = true);

    try {
      final token = await SharedPrefService().getToken();
      final url =
          Uri.parse('https://niti.nexuserp.co.in/api/post/deletePost/$postId');

      // Using DELETE - if your backend expects POST, change to http.post
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Delete Status Code: ${response.statusCode}');
      print('Delete Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Many APIs use a response code or resSuccess flag
        final success = (data['resSuccess'] == 1) || (data['success'] == true);
        final message = data['message'] ?? 'Post deleted';

        if (success) {
          // Remove the post locally and rebuild controllers
          setState(() {
            posts.removeAt(index);
            _rebuildControllers();
          });

          _showFlushBar(context, message: message, color: Colors.green);
        } else {
          _showFlushBar(context,
              message: message.isNotEmpty ? message : 'Failed to delete post',
              color: Colors.red);
        }
      } else {
        // non-200
        String msg = 'Failed to delete post';
        try {
          final d = jsonDecode(response.body);
          msg = d['message'] ?? msg;
        } catch (_) {}
        _showFlushBar(context, message: msg, color: Colors.red);
      }
    } catch (e) {
      print('Error deleting post: $e');
      _showFlushBar(context,
          message: 'Something went wrong while deleting', color: Colors.red);
    } finally {
      if (mounted) setState(() => isDeletingPost[index] = false);
    }
  }

  Widget buildPostCard(dynamic post, int index) {
    final editing = isEditing[index] ?? false;
    final expanded = isExpanded[index] ?? false;
    final deleting = isDeletingPost[index] ?? false;

    return Stack(
      children: [
        HighlightedPostCard(
          post: post,
          isHighlighted: highlightedPosts[post['_id']] == true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Date + Popup Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👇 Title and Date stacked vertically
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          editing
                              ? TextField(
                                  controller: titleControllers[index],
                                  style:
                                      TextStyleConstants.inter18W600.copyWith(
                                    color: ColorConstants.primaryBrownColor,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                )
                              : Text(
                                  post['title'] ?? '',
                                  style:
                                      TextStyleConstants.inter16W600.copyWith(
                                    color: ColorConstants.primaryBrownColor,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          // 👇 Date just below title
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14,
                                  color: ColorConstants.primaryOrangeColor),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(post['createdAt']),
                                style: TextStyleConstants.inter10W400.copyWith(
                                  color: ColorConstants.primaryOrangeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 👇 Popup menu aligned right
                    Container(
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color:
                            ColorConstants.primaryOrangeColor.withOpacity(0.05),
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        icon: Icon(Icons.more_vert,
                            color: ColorConstants.primaryBrownColor),
                        onSelected: (value) {
                          if (value == 'edit') {
                            setState(() {
                              titleControllers[index]?.text =
                                  posts[index]['title'] ?? '';
                              bodyControllers[index]?.text =
                                  posts[index]['body'] ?? '';
                              isEditing[index] = true;
                            });
                          } else if (value == 'delete') {
                            // Confirm (optional) - you asked to call API on tap; I'll directly call
                            deletePost(posts[index]['_id'], index);
                          }
                        },
                        color: ColorConstants.whiteColor2,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 18,
                                    color: ColorConstants.primaryBrownColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit Post',
                                  style: TextStyleConstants.inter14W500
                                      .copyWith(
                                          color:
                                              ColorConstants.primaryBrownColor),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    size: 18, color: ColorConstants.redColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Post',
                                  style: TextStyleConstants.inter14W500
                                      .copyWith(
                                          color: ColorConstants.redColor2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 👇 Body ABOVE divider
                editing
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorConstants.primaryBrownColor,
                          ),
                        ),
                        child: TextField(
                          controller: bodyControllers[index],
                          maxLines: null,
                          style: TextStyleConstants.inter16W400.copyWith(
                            color: ColorConstants.blackColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              post['body'] ?? '',
                              maxLines: expanded ? null : 3,
                              overflow: expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: TextStyleConstants.inter14W400.copyWith(
                                color: ColorConstants.blackColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if ((post['body'] ?? '').toString().length > 100)
                            GestureDetector(
                              onTap: () {
                                setState(() => isExpanded[index] = !expanded);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  expanded ? "Show less" : "Show more",
                                  style:
                                      TextStyleConstants.inter14W500.copyWith(
                                    color: ColorConstants.primaryOrangeColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                const Divider(height: 20, thickness: 0.5),

                // 👇 Comments + Anonymous (unchanged)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (post['commentsEnabled'] == true) {
                          openCommentsSheet(post['_id'], post['title'] ?? '',
                              mounted, context, fetchCommentsForPost);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 16,
                              color: post['commentsEnabled'] == true
                                  ? ColorConstants.primaryOrangeColor
                                  : ColorConstants.hintColor),
                          const SizedBox(width: 4),
                          Text(
                            post['commentsEnabled'] == true
                                ? 'show comments'
                                : 'Comments Off',
                            style: TextStyleConstants.inter12W400.copyWith(
                              color: post['commentsEnabled'] == true
                                  ? ColorConstants.blueColor
                                  : ColorConstants.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.visibility_off_outlined,
                            size: 16, color: ColorConstants.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          post['anonymous'] == true ? 'Anonymous' : 'Public',
                          style: TextStyleConstants.inter12W400.copyWith(
                            color: ColorConstants.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 👇 Action buttons (unchanged)
                if (editing) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryBrownColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => updatePost(index),
                          child: Text(
                            "Save",
                            style: TextStyleConstants.inter14W500.copyWith(
                              color: ColorConstants.whiteColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryOrangeColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              titleControllers[index]?.text =
                                  post['title'] ?? '';
                              bodyControllers[index]?.text = post['body'] ?? '';
                              isEditing[index] = false;
                            });
                          },
                          child: Text(
                            "Cancel",
                            style: TextStyleConstants.inter14W500.copyWith(
                              color: ColorConstants.whiteColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Overlay loader when deleting
        if (deleting)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    titleControllers.forEach((_, c) => c.dispose());
    bodyControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: ColorConstants.whiteColor,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor2,
        appBar: AppBar(
          shadowColor: Colors.grey.withOpacity(0.3),
          title: Text(
            'My Posts',
            style: TextStyleConstants.inter20W600.copyWith(
              color: ColorConstants.blackColor,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: fetchPosts,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : posts.isEmpty
                  ? const Center(child: Text("No posts found"))
                  : ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return buildPostCard(posts[index], index);
                      },
                    ),
        ),
      ),
    );
  }
}
