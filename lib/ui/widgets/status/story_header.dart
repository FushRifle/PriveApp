import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StoryHeader extends StatelessWidget {
  final Story story;
  final VoidCallback onClose;

  const StoryHeader({
    super.key,
    required this.story,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StoryAvatar(
          avatar: story.user.avatar,
          name: story.user.name,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StoryUserInfo(story: story),
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onClose();
          },
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String avatar;
  final String name;

  const _StoryAvatar({
    required this.avatar,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final fallback =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatar.isNotEmpty && avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: avatar,
                fit: BoxFit.cover,
                placeholder: (_, __) => _AvatarFallback(text: fallback),
                errorWidget: (_, __, ___) => _AvatarFallback(text: fallback),
              )
            : avatar.isNotEmpty
                ? Image.asset(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _AvatarFallback(text: fallback);
                    },
                  )
                : _AvatarFallback(text: fallback),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String text;

  const _AvatarFallback({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white.withOpacity(0.18),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _StoryUserInfo extends StatelessWidget {
  final Story story;

  const _StoryUserInfo({
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          story.user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          story.time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.72),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
