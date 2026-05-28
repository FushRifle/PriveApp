import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/models/profile_model.dart';

class ProfileCard extends StatelessWidget {
  final ProfileModel profile;
  final bool isTop;

  const ProfileCard({
    super.key,
    required this.profile,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(
              isTop ? 0.2 : 0.08,
            ),
            blurRadius: isTop ? 20 : 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ProfileImage(profile: profile),
            const _GradientOverlay(),
            Positioned(
              top: 16,
              left: 16,
              child: _DistanceBadge(
                distanceText: profile.distanceText,
              ),
            ),
            if (profile.isOnline)
              const Positioned(
                top: 16,
                right: 16,
                child: _OnlineBadge(),
              ),
            if (profile.matchScore > 0)
              Positioned(
                bottom: 106,
                left: 16,
                child: _MatchScoreBadge(
                  score: profile.matchScore,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProfileInfo(profile: profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileImage({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final image = profile.image.trim();

    if (image.isEmpty) {
      return _PlaceholderImage(profile: profile);
    }

    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        memCacheWidth: 900,
        placeholder: (_, __) => _PlaceholderImage(profile: profile),
        errorWidget: (_, __, ___) => _PlaceholderImage(profile: profile),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _PlaceholderImage(profile: profile);
      },
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final ProfileModel profile;

  const _PlaceholderImage({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = profile.name.trim().isNotEmpty
        ? profile.name.trim()[0].toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.35),
            AppColors.primary.withOpacity(0.85),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: 96,
              color: AppColors.white.withOpacity(0.48),
            ),
            const SizedBox(height: 8),
            Text(
              firstLetter,
              style: TextStyle(
                fontSize: 40,
                color: AppColors.white.withOpacity(0.55),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.48, 0.7, 1.0],
          colors: [
            AppColors.transparent,
            Color.fromRGBO(0, 0, 0, 0.15),
            Color.fromRGBO(0, 0, 0, 0.78),
          ],
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final String distanceText;

  const _DistanceBadge({
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassBadge(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.white.withOpacity(0.9),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            distanceText,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.greenColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online',
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  final int score;

  const _MatchScoreBadge({
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite,
            color: AppColors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$score% Match',
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileInfo({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final interests = profile.interests
            ?.where((interest) => interest.trim().isNotEmpty)
            .take(4)
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NameRow(profile: profile),
          if (profile.occupation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _OccupationRow(occupation: profile.occupation),
          ],
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio,
              style: AppTheme.whiteTextStyle.copyWith(
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InterestTags(interests: interests),
          ],
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  final ProfileModel profile;

  const _NameRow({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  '${profile.name}, ${profile.age}',
                  style: AppTheme.whiteTextStyle.copyWith(
                    fontSize: 24,
                    fontWeight: AppTheme.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  color: AppColors.blue,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.location_on,
          color: AppColors.white.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            profile.distanceText,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OccupationRow extends StatelessWidget {
  final String occupation;

  const _OccupationRow({
    required this.occupation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.work_outline,
          color: AppColors.white.withOpacity(0.8),
          size: 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            occupation,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
              color: AppColors.white.withOpacity(0.82),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InterestTags extends StatelessWidget {
  final List<String> interests;

  const _InterestTags({
    required this.interests,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.white.withOpacity(0.3),
            ),
          ),
          child: Text(
            interest,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Widget child;

  const _GlassBadge({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
        ),
      ),
      child: child,
    );
  }
}
