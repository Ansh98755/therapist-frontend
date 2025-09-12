import 'package:flutter/material.dart';
import 'package:therapist_app/screens/community_screen/community_screen.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';
class PostDetailsScreen extends StatelessWidget
{
final CommunityPost post;
  const PostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post Details',
          style: TextStyle(
            color: ColorConstants.blackColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ColorConstants.primaryBrownColor.withOpacity(0.1),
                        ColorConstants.colorE6DBCF,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.transparent,
                    child: post.authorImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              post.authorImage!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: ColorConstants.primaryBrownColor,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.timeAgo,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.hintColor.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Post title
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ColorConstants.blackColor,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Post content
            Text(
              post.content,
              style: TextStyle(
                fontSize: 16,
                color: ColorConstants.blackColor.withOpacity(0.7),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: post.isLiked 
                        ? Colors.red.shade50 
                        : ColorConstants.colorF5F5F5,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: post.isLiked 
                          ? Colors.red.shade200 
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: post.isLiked ? Colors.red.shade400 : ColorConstants.hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.likes.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: post.isLiked ? Colors.red.shade400 : ColorConstants.hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: ColorConstants.colorF5F5F5,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: ColorConstants.hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.comments.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstants.hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
