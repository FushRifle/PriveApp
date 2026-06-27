import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostHeader extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onMoreTap;
  final bool isOwnProfile;

  const PostHeader({
    super.key,
    required this.post,
    this.onMoreTap,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = post.isAnonymousPost ? '' : post.user.avatar;
    final name = post.isAnonymousPost
        ? 'Anonymous'
        : post.user.name.trim().isNotEmpty
            ? post.user.name
            : 'User';
    final canOpenProfile = post.user.id > 0 && !post.isAnonymousPost;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canOpenProfile
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(
                        context,
                        isOwnProfile
                            ? NamedRoutes.profileScreen
                            : NamedRoutes.otherProfileScreen,
                        arguments: isOwnProfile ? null : post.user.id,
                      );
                    }
                  : null,
              child: Row(
                children: [
                  _PostAvatar(
                    avatar: avatar,
                    name: name,
                    isOfficial: post.isAIPost,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PostUserInfo(
                      name: name,
                      time: post.time,
                      isVerified: post.user.verified,
                      isOfficial: post.isAIPost,
                      badge: post.contentTypeLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onMoreTap != null)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onMoreTap?.call();
              },
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _PostAvatar extends StatelessWidget {
  final String avatar;
  final String name;
  final bool isOfficial;

  const _PostAvatar({
    required this.avatar,
    required this.name,
    required this.isOfficial,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: isOfficial
            ? Image.asset(
                'assets/icons/clique-new.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(text: fallback),
              )
            : avatar.isNotEmpty && avatar.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _AvatarFallback(text: fallback),
                    errorWidget: (_, __, ___) =>
                        _AvatarFallback(text: fallback),
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
      color: AppColors.primary.withOpacity(0.12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _PostUserInfo extends StatelessWidget {
  final String name;
  final String time;
  final bool isVerified;
  final bool isOfficial;
  final String badge;

  const _PostUserInfo({
    required this.name,
    required this.time,
    required this.isVerified,
    required this.isOfficial,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.githubOrange,
              ),
            ],
            if (isOfficial) ...[
              const SizedBox(width: 4),
              const _OfficialBadge(),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            _TypeBadge(label: badge),
          ],
        ),
      ],
    );
  }
}

class _OfficialBadge extends StatelessWidget {
  const _OfficialBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.verified_rounded,
            size: 15,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;

  const _TypeBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final value = label.trim().isEmpty ? 'Post' : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: AppTheme.blackTextStyle.copyWith(
          color: AppColors.text,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
