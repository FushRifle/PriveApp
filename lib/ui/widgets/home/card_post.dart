import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/post_model.dart';
import 'package:social_media_app/ui/widgets/home/custom_bottom_sheet_comments.dart';

import 'clip_status_bar.dart';

class CardPost extends StatefulWidget {
  final PostModel post;

  const CardPost({required this.post, super.key});

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  bool isLiked = false;
  bool isSaved = false;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    likeCount = int.tryParse(widget.post.like) ?? 0;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
        HapticFeedback.lightImpact();
      } else {
        likeCount--;
      }
    });
  }

  void toggleSave() {
    setState(() {
      isSaved = !isSaved;
      HapticFeedback.lightImpact();
    });
  }

  void onCommentTap(BuildContext context) {
    HapticFeedback.lightImpact();
    customBottomSheetComments(context);
  }

  void onShareTap() {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    print('Share tapped');
  }

  void onProfileTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed(NamedRoutes.profileScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 460,
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          _buildImageCover(),
          _buildImageGradient(),
          Positioned(
            height: 375,
            width: 85,
            right: 0,
            top: 25,
            child: Transform.rotate(
              angle: 3.14,
              child: ClipPath(
                clipper: ClipStatusBar(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: ColoredBox(
                    color: AppColors.whiteColor.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 75,
            right: 20,
            child: Column(
              children: [
                _buildStatusButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  text: likeCount.toString(),
                  onTap: toggleLike,
                  isActive: isLiked,
                  activeColor: AppColors.redColor,
                ),
                const SizedBox(height: 10),
                _buildStatusButton(
                  icon: Icons.message,
                  text: widget.post.comment,
                  onTap: () => onCommentTap(context),
                ),
                const SizedBox(height: 10),
                _buildStatusButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  text: "Save",
                  onTap: toggleSave,
                  isActive: isSaved,
                  activeColor: AppColors.greenColor,
                ),
                const SizedBox(height: 10),
                _buildStatusButton(
                  icon: Icons.send,
                  text: widget.post.share,
                  onTap: onShareTap,
                ),
              ],
            ),
          ),
          Positioned(
            width: 5,
            height: 30,
            right: 72,
            top: 200,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          _buildItemPublisher(context),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isActive && activeColor != null
                  ? activeColor
                  : AppColors.whiteColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: (activeColor ?? Colors.white).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : AppColors.whiteColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 13,
              fontWeight: isActive ? AppTheme.bold : AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }

  Align _buildImageGradient() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(children: [
        BlurHash(
          imageFit: BoxFit.cover,
          hash: widget.post.pictureHash,
        ),
        Image.network(
          widget.post.picture,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                height: 55,
                width: 55,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.8),
                  strokeWidth: 1.2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        )
      ]),
    );
  }

  Container _buildItemPublisher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 40, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onProfileTap(context),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    widget.post.imgProfile,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.post.name,
                  style: AppTheme.whiteTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: AppTheme.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.post.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.post.hashtags.join(" "),
            style: AppTheme.whiteTextStyle.copyWith(
              color: AppColors.greenColor,
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}
