import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:clique/app/configs/colors.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(420.0, 520.0)
        .toDouble();

    return Shimmer.fromColors(
      baseColor: AppColors.grey[300]!,
      highlightColor: AppColors.grey[100]!,
      child: Column(
        children: [
          _buildShimmerCard(cardHeight),
          const SizedBox(height: 16),
          _buildShimmerCard(cardHeight),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey[300],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and age
                  Container(
                    width: 150,
                    height: 24,
                    color: AppColors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Container(
                    width: 100,
                    height: 16,
                    color: AppColors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  // Bio lines
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: AppColors.grey[300],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 200,
                    height: 14,
                    color: AppColors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  // Interests
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 60,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
