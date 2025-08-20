import 'package:flutter/material.dart';
import 'package:therapist_app/screens/post_details_screen.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class CommunityPost {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String timeAgo;
  final String? authorImage;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isAnonymous;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.timeAgo,
    this.authorImage,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isAnonymous = false,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<CommunityPost> posts = [
    CommunityPost(
      id: '1',
      title: 'dididid',
      content: 'fjkdkdkd',
      authorName: 'hgdhv',
      timeAgo: '19h',
      likes: 0,
      comments: 0,
    ),
    CommunityPost(
      id: '2',
      title: 'ji pe hi hai na matlab ckjabcabsca c ashc ahsc hasc kihas cjas ckhas chkas ckhas ckha ckh ascn ashc a c',
      content: 'c c\nbbdbdbbdbbdbsbvsvsbbsdbsbsbdbdb hbh hi hi h.',
      authorName: 'ghvhvi',
      timeAgo: '1d',
      likes: 0,
      comments: 10,
    ),
    CommunityPost(
      id: '3',
      title: 'igviviviviiukb jk iu hj ',
      content: 'hgvhg iugiu iuug  iugiu i g iu iu iu',
      authorName: 'hiugu  u  u h ',
      timeAgo: '3d',
      likes: 1,
      comments: 9,
    ),
    CommunityPost(
      id: '4',
      title: 'i m under water',
      content: 'help me?',
      authorName: 'Intern',
      timeAgo: '2d',
      likes: 5,
      comments: 3,
    ),
  ];

  final Map<String, bool> _expandedPosts = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConstants.boxShadowOrangeOpacity,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(
            color: ColorConstants.blackColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(post);
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: ColorConstants.primaryBrownColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primaryBrownColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _navigateToNewPost(context),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: ColorConstants.whiteColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Share your thoughts',
                          style: TextStyle(
                            color: ColorConstants.whiteColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final isExpanded = _expandedPosts[post.id] ?? false;
    final shouldShowReadMore = post.content.length > 120;
    final displayContent = shouldShowReadMore && !isExpanded 
        ? '${post.content.substring(0, 120)}...'
        : post.content;

    return GestureDetector(
      onTap: () => _navigateToPostDetails(post),
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConstants.colorE0E0E0.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.colorBlack12.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info header
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
                      radius: 22,
                      backgroundColor: Colors.transparent,
                      child: post.authorImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                post.authorImage!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: ColorConstants.primaryBrownColor,
                              size: 26,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post.timeAgo,
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConstants.hintColor.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Post title - truncated to one line
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.blackColor,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Post content
              Text(
                displayContent,
                style: TextStyle(
                  fontSize: 15,
                  color: ColorConstants.blackColor.withOpacity(0.7),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              // Read more/less button
              if (shouldShowReadMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedPosts[post.id] = !isExpanded;
                      });
                    },
                    child: Text(
                      isExpanded ? 'Read less' : 'Read more',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.primaryBrownColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 18),
              
              // Divider
              Container(
                height: 1,
                color: ColorConstants.colorE0E0E0.withOpacity(0.3),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  _buildActionButton(
                    icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: post.likes.toString(),
                    onTap: () => _toggleLike(post.id),
                    color: post.isLiked ? Colors.red.shade400 : ColorConstants.hintColor,
                    isActive: post.isLiked,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: post.comments.toString(),
                    onTap: () => _openComments(post.id),
                    color: ColorConstants.hintColor,
                    isActive: false,
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => _sharePost(post.id),
                    color: ColorConstants.hintColor,
                    isActive: false,
                    showLabel: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isActive,
    bool showLabel = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? color.withOpacity(0.1) 
              : ColorConstants.colorF5F5F5.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive 
                ? color.withOpacity(0.2) 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: color,
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleLike(String postId) {
    setState(() {
      final index = posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = posts[index];
        posts[index] = CommunityPost(
          id: post.id,
          title: post.title,
          content: post.content,
          authorName: post.authorName,
          timeAgo: post.timeAgo,
          authorImage: post.authorImage,
          likes: post.isLiked ? post.likes - 1 : post.likes + 1,
          comments: post.comments,
          isLiked: !post.isLiked,
          isAnonymous: post.isAnonymous,
        );
      }
    });
  }

  void _openComments(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening comments...'),
        backgroundColor: ColorConstants.primaryBrownColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _sharePost(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing post...'),
        backgroundColor: ColorConstants.primaryBrownColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToNewPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewPostScreen(),
      ),
    );
  }

  void _navigateToPostDetails(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(post: post),
      ),
    );
  }
}

// Post Details Screen
class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _postAnonymously = false;
  bool _enableComments = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.boxShadowOrangeOpacity,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: ColorConstants.blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
            color: ColorConstants.blackColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ElevatedButton(
              onPressed: _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryBrownColor,
                foregroundColor: ColorConstants.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            Container(
              decoration: BoxDecoration(
                color: ColorConstants.colorF5F5F5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: ColorConstants.hintColor,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: ColorConstants.blackColor,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description field
            Container(
              decoration: BoxDecoration(
                color: ColorConstants.colorF5F5F5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  hintStyle: TextStyle(
                    color: ColorConstants.hintColor,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: ColorConstants.blackColor,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Toggle options
            Container(
              decoration: BoxDecoration(
                color: ColorConstants.colorF5F5F5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildToggleOption(
                    title: 'Post Anonymously',
                    value: _postAnonymously,
                    onChanged: (value) {
                      setState(() {
                        _postAnonymously = value;
                      });
                    },
                  ),
                  const Divider(
                    height: 1,
                    color: ColorConstants.colorE0E0E0,
                  ),
                  _buildToggleOption(
                    title: 'Enable Comments',
                    value: _enableComments,
                    onChanged: (value) {
                      setState(() {
                        _enableComments = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: ColorConstants.blackColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ColorConstants.primaryBrownColor,
        activeTrackColor: ColorConstants.primaryBrownColor.withOpacity(0.3),
        inactiveThumbColor: ColorConstants.hintColor,
        inactiveTrackColor: ColorConstants.colorE0E0E0,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _createPost() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    // Here you would typically save the post data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post created successfully!')),
    );
    
    Navigator.pop(context);
  }
}