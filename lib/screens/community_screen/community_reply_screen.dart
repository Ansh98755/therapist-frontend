import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../api_services/community_api_service.dart';
import '../../core/shared_pref.dart';
import '../../custom_widgets/Animated Banner.dart';
import '../../models/single_post_model.dart';
import '../../utils/assets_constants/assets_constants.dart';
import '../../utils/color_constants/color_constants.dart';
import '../../utils/string_constants/string_constants.dart';
import '../../utils/text_style_constants/text_style_constants.dart';

class RepliesScreen extends StatefulWidget {
  final String postId;
  final String postedById;

  const RepliesScreen({
    super.key,
    required this.postId,
    required this.postedById,
  });

  @override
  State<RepliesScreen> createState() => _RepliesScreenState();
}

class _RepliesScreenState extends State<RepliesScreen>
    with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _token;
  String? _userName;
  bool _isLoading = true;
  List<Map<String, dynamic>> _comments = [];
  PostData? _post; // now holds the wrapper

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _loadPost();
  }

  Future<void> _loadData() async {
    final token = await SharedPrefService().getToken();
    final userName = await SharedPrefService().getFullName();

    setState(() {
      _token = token;
      _userName = userName;
    });

    await Future.wait([
      _fetchComments(),
    ]);
  }

  Future<void> _loadPost() async {
    try {
      print("Fetching post with ID: ${widget.postId}");

      final postData = await CommunityApiService.fetchPostById(widget.postId);

      setState(() {
        _post = postData;
      });
    } catch (e, stack) {
      debugPrint("Error loading post: $e");
      debugPrintStack(stackTrace: stack);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load post")),
      );

      setState(() {
        _post = null;
      });
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
          'https://niti.nexuserp.co.in/api/post/getComments/${widget.postId}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({}),
      );
      print('${response.statusCode}');
      print('${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data['response'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('[ERROR Fetching Comments] $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

/// *****to comment on the posts from the community section******
  Future<void> _submitReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty || _token == null) return;

    try {
      final url = Uri.parse(
          'https://niti.nexuserp.co.in/api/v1/post/${widget.postId}/comment');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'comment': reply,
          'user_name': _userName,
          'postedBy': widget.postedById
        }),
      );
      print('${response.statusCode}');
      print('${response.body}');
      print("postedBy: ${widget.postedById}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _comments.insert(0, {
            'user_name': _userName ?? "You",
            'comment_text': reply,
          });
          _replyController.clear();
        });
        _showFlushBar(
          context,
          message: responseData['message'] ?? 'Comment added successfully',
          color: Colors.green,
        );
      } else {
        debugPrint('[REPLY FAILED] ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[REPLY ERROR] $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      setState(() => _isKeyboardVisible = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: ColorConstants.whiteColor,
        appBar: isLandscape && _isKeyboardVisible
            ? null
            : AppBar(
          backgroundColor: ColorConstants.whiteColor,
          shadowColor: Colors.grey.withOpacity(0.3),
          elevation: 0,
          surfaceTintColor: ColorConstants.transparentColor,
          leading: IconButton(
            icon: Image.asset(
              AssetsConstants.settingsBack,
              width: 24,
              height: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Comments',
            style: TextStyleConstants.inter20W600.copyWith(color: ColorConstants.blackColor),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPostContent(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'Comments',
                              style: TextStyleConstants.inter16W600
                                  .copyWith(color: ColorConstants.blackColor),
                            ),
                          ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            ..._comments.map((comment) {
                              final postedBy = comment['postedBy'] ?? {};
                              final String name = postedBy['fullname'] ??
                                  postedBy['fullName'] ??
                                  'Anonymous';

                              final String imgPath = postedBy['pictureUrl'] != null
                                  ? 'https://niti.nexuserp.co.in/uploads/${postedBy['pictureUrl']}'
                                  : AssetsConstants.communityAnony; // fallback

                              final String text = comment['comment_text'] ?? '';

                              final String time = comment['created_at'] != null
                                  ? _formatTimeAgo(DateTime.parse(comment['created_at']))
                                  : '';

                              final String postedByType = comment['postedByType'] ?? 'User';

                              return _replyItem(
                                imgPath: imgPath,
                                name: name,
                                text: text,
                                time: time,
                                isTherapist: postedByType == 'Therapist',
                              );
                            }),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildReplyBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    if (_post == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Loading post...'),
      );
    }
    final postData = _post!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textStyle = TextStyleConstants.inter18W700.copyWith(
                color: ColorConstants.primaryBrownColor,
              );

              final timeStyle = TextStyleConstants.inter14W600.copyWith(
                color: ColorConstants.colorFFB444,
              );

              // Check overflow
              final tp = TextPainter(
                text: TextSpan(
                  text: postData.title,
                  style: textStyle,
                  children: [
                    TextSpan(
                      text: " ·${_formatTimeAgo(postData.createdAt)}",
                      style: timeStyle,
                    ),
                  ],
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final isOverflowing = tp.didExceedMaxLines;
              bool isExpanded = false;

              return StatefulBuilder(
                builder: (context, setSB) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: postData.title,
                          style: textStyle,
                          children: [
                            TextSpan(
                              text: " ·${_formatTimeAgo(postData.createdAt)}",
                              style: timeStyle,
                            ),
                          ],
                        ),
                        maxLines: isExpanded ? null : 1,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (isOverflowing)
                        GestureDetector(
                          onTap: () => setSB(() => isExpanded = !isExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              isExpanded ? "Show less" : "Show more",
                              style: TextStyleConstants.inter12W500.copyWith(
                                color: Colors.blue.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            postData.body,
            style: TextStyleConstants.inter14W500.copyWith(
              color: ColorConstants.blackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyItem({
    required String imgPath,
    required String name,
    required String time,
    required String text,
    bool isTherapist = false,

  })
  {
    final bool isNetwork = imgPath.startsWith('http');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: isNetwork
                ? Image.network(
              imgPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  AssetsConstants.communityAnony,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                );
              },
            )
                : Image.asset(imgPath, width: 40, height: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyleConstants.inter14W600
                          .copyWith(color: ColorConstants.blackColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· $time',
                      style: TextStyleConstants.inter12W600
                          .copyWith(color: ColorConstants.hintColor),
                    ),
                    Spacer(),
                    if (isTherapist) ...[
                      AnimatedGradientBanner(text: "Therapist"),

                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyleConstants.inter12W400
                      .copyWith(color: ColorConstants.blackColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: ColorConstants.whiteColor,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Image.asset(AssetsConstants.communityAnony, width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: ColorConstants.colorF5F5F5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _replyController,
                          focusNode: _focusNode,
                          maxLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitReply(),
                          decoration: const InputDecoration(
                            hintText: StringConstants.writeAReply,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              color: ColorConstants.color6B8278,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: _submitReply,
                        icon: const Icon(Icons.send,
                            size: 24, color: ColorConstants.color6B8278),
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

  String _formatTimeAgo(DateTime date) {
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
}