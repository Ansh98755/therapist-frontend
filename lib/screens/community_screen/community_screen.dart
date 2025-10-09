import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/shared_pref.dart';
import '../../providers/community_provider.dart';
import '../../providers/replies_provider.dart';
import '../../routes/app_routing.dart';
import '../../utils/assets_constants/assets_constants.dart';
import '../../utils/color_constants/color_constants.dart';
import '../../utils/string_constants/string_constants.dart';
import '../../utils/text_style_constants/text_style_constants.dart';
import '../my_post_screen/custom_my_post_widgets/comment_cart_widget.dart';
import '../skeleton_screens/skeleton_community_screen.dart';
import 'community_reply_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late ScrollController _scrollController;
  late CommunityProvider provider;
  String? _token;
  int _notificationCount = 0;
  List<dynamic> posts = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);

    Future.microtask(() async {
      final token = await SharedPrefService().getToken();
      setState(() => _token = token);

      if (token != null) {
        final provider = Provider.of<CommunityProvider>(context, listen: false);

        if (provider.posts.isEmpty) {
          print("🟢 First time: No posts in memory → fetching from API...");
          await provider.fetchPosts(reset: true, token: token);
        } else {
          print(
            "🟡 Returning user: Showing ${provider.posts.length} posts from Provider (no API call).",
          );
        }
      } else {
        print("🔒 No token found → skipping fetch.");
      }
      _loadNotificationCount();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final provider = Provider.of<CommunityProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoading &&
        !provider.hasReachedEnd) {
      provider.fetchPosts(token: _token);
    }
  }

  // Add pull-to-refresh functionality
  Future<void> _onRefresh() async {
    if (_token != null) {
      await Provider.of<CommunityProvider>(
        context,
        listen: false,
      ).fetchPosts(reset: true, token: _token!);
    }
  }

  String timeAgoSinceDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  Future<int> _fetchNotificationCount() async {
    try {
      final token = await SharedPrefService().getToken(); // adjust if different

      final response = await http.post(
        Uri.parse("https://niti.nexuserp.co.in/api/post/getNotificationCount"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({}), // empty body
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["count"] ?? 0;
      } else {
        print("❌ Failed to fetch count: ${response.body}");
        return 0;
      }
    } catch (e) {
      print("⚠️ Error: $e");
      return 0;
    }
  }

  Future<void> _loadNotificationCount() async {
    final count = await _fetchNotificationCount();
    setState(() {
      _notificationCount = count;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCommentsForPost(String postId) async {
    try {
      final token = await SharedPrefService().getToken();
      final url = Uri.parse(
        'https://niti.nexuserp.co.in/api/post/getComments/$postId',
      );
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

  void openCommentsSheet(
    String postId,
    String postTitle, {
    String userID = '',
  }) async {
    final comments = await fetchCommentsForPost(postId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider(
          create: (_) => RepliesProvider(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.35,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Text(
                        "Comments on '$postTitle'",
                        style: TextStyleConstants.inter16W500.copyWith(
                          color: ColorConstants.primaryBrownColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(),
                      if (comments.isEmpty)
                        const Expanded(
                          child: Center(child: Text("No comments yet")),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 16),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.manual,
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return CommentCard(
                                postId: postId,
                                comment: comment,
                                onSend: (replyText, commentMap) async {
                                  debugPrint(
                                    'Reply for ${commentMap['_id']}: $replyText',
                                  );
                                },
                                userId: userID,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: ColorConstants.whiteColor2,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: ColorConstants.whiteColor2,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return SafeArea(
      child: Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12.0, right: 12.0),
          child: ElevatedButton.icon(
            onPressed: () {
              context.pushNamed(AppRouteEnum.newPostScreen.name);
            },
            icon: const Icon(
              Icons.edit,
              size: 20,
              color: ColorConstants.primaryOrangeColor,
            ),
            label: Text(
              "Share your thoughts",
              style: TextStyleConstants.inter14W600.copyWith(
                color: ColorConstants.whiteColor2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryBrownColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 4,
            ),
          ),
        ),
        backgroundColor: ColorConstants.whiteColor2,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.grey.withOpacity(0.3),

          // backgroundColor: ColorConstants.whiteColor,
          elevation: 0,
          // centerTitle: true,
          backgroundColor: ColorConstants.whiteColor2,
<<<<<<< HEAD
=======

>>>>>>> d0dfb253bff71cb90c6ef9ab7f09e2dc9c320720
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () async {
                  final result = await context.pushNamed<Map<String, dynamic>>(
                    AppRouteEnum.notificationScreen.name,
                  );
                  print("Notification screen result: $result");

                  // reload count after visiting notifications
                  await _loadNotificationCount();

                  if (result != null) {
                    context.pushNamed(
                      AppRouteEnum.myPostScreen.name,
                      extra: {
                        'postId': result['postId'],
                        'userId': result['userId'],
                        'likeFound': result['likeFound'],
                        'comingFromCommunity': true,
                      },
                    );
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 28,
                      color: ColorConstants.primaryBrownColor.withOpacity(0.7),
                    ),
                    if (_notificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              _notificationCount > 99
                                  ? "99+"
                                  : '$_notificationCount',
                              style: TextStyleConstants.inter12W500.copyWith(
                                color: ColorConstants.whiteColor2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          title: Padding(
            padding: const EdgeInsets.only(right: 48.0),
            child: Text(
              StringConstants.community,
              style: TextStyleConstants.inter20W600.copyWith(
                color: ColorConstants.blackColor,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: 50,
              left: 50,
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/background_sticker2.png',
                  width: 180,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: 50,
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/background_sticker1.png',
                  width: 100,
                ),
              ),
            ),
            // Posts list
            Consumer<CommunityProvider>(
              builder: (context, provider, _) {
                // Show skeleton if loading first time and no posts
                if (provider.posts.isEmpty && provider.isLoading) {
                  return const SkeletonCommunityScreen();
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // Safe space for FAB
                    itemCount:
                        provider.posts.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loader at the end of the list
                      if (index == provider.posts.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        );
                      }

                      final post = provider.posts[index];

                      return _CommunityPost(
                        postId: post.id,
                        title: post.title,
                        content: post.body,
                        name: post.postedBy?.fullName ?? "Anonymous",
                        createdById: post.postedBy?.id,
                        timeAgo: timeAgoSinceDate(post.createdAt),
                        commentsEnabled: post.commentsEnabled,
                        commentCount: post.commentCount,
                        anonymous: post.anonymous,
                        postedById: post.postedBy?.id,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPost extends StatefulWidget {
  final String postId;
  final String title; // <-- add title
  final String content; // body
  final String name; // fullName of poster
  final String? createdById; // poster’s id
  final String timeAgo;
  final bool commentsEnabled;
  final int commentCount;
  final bool anonymous;
  final String? postedById;

  const _CommunityPost({
    required this.postId,
    required this.title, // <-- add in constructor
    required this.content,
    required this.name,
    required this.createdById,
    required this.timeAgo,
    required this.commentsEnabled,
    required this.commentCount,
    required this.anonymous,
    this.postedById,
  });

  @override
  State<_CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<_CommunityPost> {
  bool _isExpanded = false;
  bool _showReadMore = false;
  bool _isLoadingComments = false;
  bool _showInlineComments = false;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _replyController = TextEditingController();
  String? _token;
  String? _userName;
  final FocusNode _focusNode = FocusNode();
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final token = await SharedPrefService().getToken();
    final userName = await SharedPrefService().getFullName();
    if (mounted) {
      setState(() {
        _token = token;
        _userName = userName;
      });
    }
  }

  void _checkTextOverflow() {
    final span = TextSpan(
      text: widget.content,
      style: TextStyleConstants.manrope16W400Dark.copyWith(height: 24 / 16),
    );
    final tp = TextPainter(
      maxLines: 4,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      text: span,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 32);

    if (tp.didExceedMaxLines) {
      setState(() => _showReadMore = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkTextOverflow();
  }

  Future<void> _handleLikeTap() async {
    if (_token == null) await _loadToken();
    if (_token == null) return;

    final provider = Provider.of<CommunityProvider>(context, listen: false);

    await provider.toggleLikePost(
      postId: widget.postId,
      postedBy: widget.postedById,
      token: _token!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      AssetsConstants.communityAnony,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textStyle = TextStyleConstants.inter14W600
                                .copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: ColorConstants.primaryBrownColor,
                                );

                            final tp = TextPainter(
                              text: TextSpan(
                                text: widget.title,
                                style: textStyle,
                              ),
                              maxLines: 1, // important
                              textDirection: TextDirection.ltr,
                            )..layout(maxWidth: constraints.maxWidth);

                            final isOverflowing = tp.didExceedMaxLines;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: textStyle,
                                  maxLines: isExpanded ? null : 1,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                if (isOverflowing)
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => isExpanded = !isExpanded,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        isExpanded ? "Show less" : "Show more",
                                        style: TextStyleConstants.inter12W600
                                            .copyWith(
                                              color: Colors.blue.shade600,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'By ${widget.anonymous ? "Anonymous" : widget.name} • ${widget.timeAgo}',
                          style: TextStyleConstants.inter10W600.copyWith(
                            color: ColorConstants.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon(Icons.more_vert, color: ColorConstants.hintColor, size: 20),
                ],
              ),
            ),
            // CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.content,
                maxLines: _isExpanded ? null : 5,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyleConstants.inter12W500.copyWith(
                  fontSize: 15.5,
                  height: 1.55,
                  color: ColorConstants.blackColor,
                ),
              ),
            ),

            // READ MORE
            if (_showReadMore)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 16, right: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded ? "Show less" : "Read more",
                    style: TextStyleConstants.inter12W600.copyWith(
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            // Divider(thickness: 0.8, color: Colors.grey.shade200),

            // ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Consumer<CommunityProvider>(
                      builder: (context, provider, _) {
                        final isLiked = provider.isPostLiked(widget.postId);
                        final isLiking = provider.isLiking(widget.postId);
                        final likeCount = provider.getLikeCount(widget.postId);

                        return GestureDetector(
                          onTap: isLiking ? null : _handleLikeTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isLiked
                                  ? Colors.red.shade50
                                  : Colors.red.shade50.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isLiked
                                    ? Colors.white
                                    : ColorConstants.themeColor.withOpacity(
                                        0.3,
                                      ),
                              ),
                            ),
                            child: Row(
                              children: [
                                isLiked
                                    ? Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 20,
                                      )
                                    : Image.asset(
                                        'assets/images/like_icon.png',
                                        height: 20,
                                        width: 20,
                                      ),
                                const SizedBox(width: 6),
                                Text(
                                  likeCount.toString(),
                                  style: TextStyleConstants.inter14W600
                                      .copyWith(
                                        color: ColorConstants.hintColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    VerticalDivider(
                      thickness: 0.5,
                      color: ColorConstants.hintColor,
                      indent: 5,
                      endIndent: 5,
                    ),
                    // const SizedBox(width: 14),
                    if (widget.commentsEnabled)
                      GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            AppRouteEnum.communityReplyScreen.name,
                            extra: {
                              "postId": widget.postId.toString(),
                              "postedById": widget.createdById.toString(),
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ColorConstants.themeColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                AssetsConstants.communityChat,
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.commentCount}', // <-- Show API count
                                style: TextStyleConstants.inter14W600.copyWith(
                                  color: ColorConstants.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
