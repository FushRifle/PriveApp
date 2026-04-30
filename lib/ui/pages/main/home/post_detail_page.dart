import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/data/models/post_model.dart';
import 'package:social_media_app/ui/widgets/home/card_post.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Data state
  final List<Map<String, dynamic>> _comments = [
    {
      'name': 'Sarah Johnson',
      'avatar': 'assets/profiles/profile_1.jpeg',
      'comment': 'This is absolutely stunning! 😍',
      'time': '2m',
      'likes': 24,
      'isLiked': false
    },
    {
      'name': 'Michael Chen',
      'avatar': 'assets/profiles/profile_2.jpeg',
      'comment': 'Great work! Keep it up 🔥',
      'time': '15m',
      'likes': 12,
      'isLiked': true
    },
    {
      'name': 'Emma Wilson',
      'avatar': 'assets/profiles/profile_3.jpeg',
      'comment': 'Love the colors in this!',
      'time': '1h',
      'likes': 8,
      'isLiked': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeroAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CardPost(post: widget.post),
                      ),
                    ),
                    _buildEngagementStats(),
                    _buildCommentHeader(),
                  ],
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildModernComment(_comments[index]),
                    childCount: _comments.length,
                  ),
                ),
              ),

              // Bottom Spacer for the Floating Input
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),

          // Floating Glass/Shadow Input Bar
          _buildFloatingBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: Colors.white.withOpacity(0.8),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        ),
      ),
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, color: Colors.black),
          onPressed: _showPostOptions,
        )
      ],
    );
  }

  Widget _buildEngagementStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.favorite_rounded, widget.post.like, "Likes",
              Colors.redAccent),
          _statItem(Icons.chat_bubble_rounded, _comments.length.toString(),
              "Comments", AppColors.purpleColor),
          _statItem(Icons.share_rounded, "42", "Shares", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(count,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCommentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("COMMUNITY",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 12,
                  color: Colors.black54)),
          Text("Recent First",
              style: TextStyle(
                  color: AppColors.purpleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModernComment(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              backgroundImage: AssetImage(comment['avatar']), radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const Spacer(),
                    Text(comment['time'],
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['comment'],
                    style: const TextStyle(
                        height: 1.4, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _commentAction(
                        Icons.favorite_border_rounded, "${comment['likes']}"),
                    const SizedBox(width: 20),
                    _commentAction(Icons.reply_rounded, "Reply"),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFloatingBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(0.9),
              Colors.white
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      AssetImage('assets/images/img_profile.jpeg')),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Add to the story...",
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send_rounded, color: AppColors.purpleColor),
                onPressed: () => _addComment(_commentController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addComment(String text) {
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _comments.insert(0, {
        'name': 'Fush',
        'avatar': 'assets/images/img_profile.jpeg',
        'comment': text,
        'time': 'Just now',
        'likes': 0,
        'isLiked': false,
      });
      _commentController.clear();
    });
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              _optionTile(Icons.link_rounded, "Copy Post Link", Colors.black87),
              _optionTile(
                  Icons.share_outlined, "External Share", Colors.black87),
              _optionTile(Icons.report_gmailerrorred_rounded, "Report Content",
                  Colors.redAccent),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: () => Navigator.pop(context),
    );
  }
}
