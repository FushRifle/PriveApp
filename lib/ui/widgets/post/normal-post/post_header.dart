import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';
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
      padding: const EdgeInsets.fromLTRB(12, 11, 7, 7),
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
                  const SizedBox(width: 9),
                  Expanded(
                    child: _PostUserInfo(
                      name: name,
                      handle: post.user.handle,
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
              style: IconButton.styleFrom(
                fixedSize: const Size.square(36),
                minimumSize: const Size.square(36),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textSecondary,
                size: 21,
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.55),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipOval(
        child: isOfficial
            ? Image.asset(
                'assets/icons/clique-new.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(text: fallback),
              )
            : avatar.isNotEmpty && avatar.startsWith('http')
                ? AppNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    preset: AppNetworkImagePreset.avatar,
                    placeholder: (_) => _AvatarFallback(text: fallback),
                    errorBuilder: (_) => _AvatarFallback(text: fallback),
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
  final String handle;
  final String time;
  final bool isVerified;
  final bool isOfficial;
  final String badge;

  const _PostUserInfo({
    required this.name,
    required this.handle,
    required this.time,
    required this.isVerified,
    required this.isOfficial,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedHandle = handle.trim().replaceFirst(RegExp(r'^@'), '');
    final showTypeBadge =
        badge.trim().isNotEmpty && badge.trim().toLowerCase() != 'post';

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
                  fontSize: 13.5,
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isVerified || isOfficial) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            if (normalizedHandle.isNotEmpty) ...[
              Flexible(
                child: Text(
                  '@$normalizedHandle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              _MetadataDot(),
              const SizedBox(width: 5),
            ],
            Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showTypeBadge) ...[
              const SizedBox(width: 5),
              _MetadataDot(),
              const SizedBox(width: 5),
              _TypeBadge(label: badge),
            ],
          ],
        ),
      ],
    );
  }
}

class _MetadataDot extends StatelessWidget {
  const _MetadataDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.55),
        shape: BoxShape.circle,
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: AppTheme.blackTextStyle.copyWith(
          color: AppColors.secondary,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
