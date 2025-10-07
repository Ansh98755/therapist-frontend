import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../custom_widgets/Animated Banner.dart';
import '../../../utils/assets_constants/assets_constants.dart';
import '../../../utils/color_constants/color_constants.dart';
import '../../../utils/text_style_constants/text_style_constants.dart';

class CommentCard extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final String userId;

  /// Called when user taps Send. Params: replyText, commentMap
  final void Function(String replyText, Map<String, dynamic> comment)? onSend;

  const CommentCard({
    Key? key,
    required this.comment,
    required this.postId,
    this.onSend,
    this.userId = '',
  }) : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  final _cardKey = GlobalKey();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // bool _showReply = false;
  // bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Future<void> _onReplyTap() async {
  //   final commentId = widget.comment['_id']?.toString() ?? '';

  //   setState(() => _showReply = true);

  //   final provider = Provider.of<RepliesProvider>(context, listen: false);

  //   await provider.fetchReplies(commentId);

  //   await Future.delayed(const Duration(milliseconds: 160));
  //   try {
  //     if (_cardKey.currentContext != null) {
  //       await Scrollable.ensureVisible(
  //         _cardKey.currentContext!,
  //         duration: const Duration(milliseconds: 250),
  //         curve: Curves.easeInOut,
  //         alignment: 0.15,
  //       );
  //     }
  //   } catch (_) {}
  //   await Future.delayed(const Duration(milliseconds: 80));
  //   if (mounted) _focusNode.requestFocus();
  // }

  // void _toggleReplyCancel() {
  //   _focusNode.unfocus();
  //   _replyController.clear();
  //   setState(() => _showReply = false);
  // }

  // Future<void> _sendReply() async {
  //   final text = _replyController.text.trim();
  //   if (text.isEmpty) return;

  //   setState(() => _isSending = true);
  //   try {
  //     widget.onSend?.call(text, widget.comment);
  //     // final provider = Provider.of<RepliesProvider>(context, listen: false);
  //     _replyController.clear();
  //     _focusNode.unfocus();
  //     setState(() => _showReply = false);
  //   } catch (e) {
  //     debugPrint('Error sending reply: $e');
  //   } finally {
  //     if (mounted) setState(() => _isSending = false);
  //   }
  // }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  // Future<void> _handleDone(String value) async {
  //   final text = value.trim();
  //   if (text.isEmpty) {
  //     FocusScope.of(context).unfocus();
  //     _replyController.clear();
  //   } else {
  //     await _sendReply();
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
    final comment = widget.comment;

    final String role = comment['postedByType'] ?? '';

    final String userName = role == "User"
        ? (comment['postedBy']?['fullName'] ?? 'Anonymous')
        : (comment['postedBy']?['fullname'] ?? 'Anonymous');

    final String? userPicture = comment['postedBy']?['pictureUrl'];

    final String commentText = comment['comment_text'] ?? '';
    final String commentedAt = _formatTimestamp(comment['created_at']);
    // final String commentId = comment['_id']?.toString() ?? '';

    // final provider = Provider.of<RepliesProvider>(context);
    // final isPosting = provider.isPosting(commentId);

    return Container(
      key: _cardKey,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: avatar + content
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: userPicture != null && userPicture.isNotEmpty
                    ? Image.network(
                        "https://niti.nexuserp.co.in/uploads/$userPicture",
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          AssetsConstants.communityAnony,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        AssetsConstants.communityAnony,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyleConstants.inter14W500.copyWith(
                            color: ColorConstants.primaryBrownColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '·${commentedAt}',
                          style: TextStyleConstants.inter12W500.copyWith(
                            color: ColorConstants.hintColor,
                          ),
                        ),
                        Spacer(),
                        if (role == "Therapist") ...[
                          AnimatedGradientBanner(text: "Therapist"),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      commentText,
                      style: TextStyleConstants.inter12W400.copyWith(
                        color: ColorConstants.blackColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// ********* Replies Section start from here and currently in replies_screen.dart in order *********
        ],
      ),
    );
  }
}
