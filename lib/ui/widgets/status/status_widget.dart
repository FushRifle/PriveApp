import 'package:flutter/material.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/data/models/status_model.dart';

class StatusWidget extends StatelessWidget {
  final StatusModel status;
  final VoidCallback onTap;
  final bool isAddStatus;

  const StatusWidget({
    super.key,
    required this.status,
    required this.onTap,
    this.isAddStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAddStatus
                        ? null
                        : status.isViewed
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.5),
                                  Colors.grey.withOpacity(0.5),
                                ],
                              )
                            : const LinearGradient(
                                colors: [
                                  AppColors.purpleColor,
                                  AppColors.redColor,
                                  Colors.orange,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                    border: isAddStatus
                        ? Border.all(
                            color: AppColors.purpleColor.withOpacity(0.5),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.whiteColor,
                        width: 3,
                      ),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(status.imgProfile),
                      ),
                    ),
                    child: isAddStatus
                        ? Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.purpleColor,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isAddStatus ? 'Your Story' : status.name,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 12,
                fontWeight: AppTheme.medium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
