import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

class CommunityAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double size;
  final Color accentColor;

  const CommunityAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.size = 52,
    this.accentColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.16)),
        image: imageUrl.isNotEmpty
            ? DecorationImage(
                image: appNetworkImageProvider(
                  context,
                  imageUrl,
                  logicalWidth: size,
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl.isNotEmpty
          ? null
          : Center(
              child: Text(
                name.isEmpty ? 'C' : name.characters.first.toUpperCase(),
                style: AppTheme.blackTextStyle.copyWith(
                  color: accentColor,
                  fontWeight: AppTheme.extraBold,
                  fontSize: size * 0.42,
                ),
              ),
            ),
    );
  }
}
