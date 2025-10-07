import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/replies_provider.dart';
import '../../../utils/color_constants/color_constants.dart';
import '../../../utils/text_style_constants/text_style_constants.dart';
import 'comment_cart_widget.dart';

void openCommentsSheet(String postId, String postTitle, bool mounted,
    BuildContext context, Function(String postId) fetchCommentsForPost,
    {String userID = ''}) async {
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
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.35,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          borderRadius: BorderRadius.circular(10)),
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
                          child: Center(child: Text("No comments yet")))
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
                                    'Reply for ${commentMap['_id']}: $replyText');
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
