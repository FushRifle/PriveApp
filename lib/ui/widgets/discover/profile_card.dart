import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/profile_model.dart';

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(isTop ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildProfileImage(),
            _buildGradientOverlay(),
            if (profile.distance.isNotEmpty) _buildDistanceBadge(),
            if (profile.isOnline) _buildOnlineIndicator(),
            _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (profile.image.isNotEmpty) {
      return Image.asset(
        profile.image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleColor.withOpacity(0.3),
            AppColors.purpleColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 100,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.5, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildDistanceBadge() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: Colors.white.withOpacity(0.9),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              profile.distance,
              style: AppTheme.whiteTextStyle.copyWith(
                fontSize: 12,
                fontWeight: AppTheme.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
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
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameAndLocation(),
            const SizedBox(height: 12),
            Text(
              profile.bio,
              style: AppTheme.whiteTextStyle.copyWith(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (profile.interests.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInterestTags(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameAndLocation() {
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
                Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.location_on,
          color: Colors.white.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            profile.location,
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

  Widget _buildInterestTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: profile.interests
          .map((interest) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: AppTheme.whiteTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: AppTheme.medium,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
