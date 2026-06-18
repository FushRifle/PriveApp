import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:clique/app/configs/colors.dart';

class EventsLoadingShimmer extends StatelessWidget {
  const EventsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.secondary.withOpacity(0.24),
      child: Column(
        children: [
          const _EventCardSkeleton(compact: false),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) ...[
            const _EventCardSkeleton(compact: true),
            if (i != 2) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _EventCardSkeleton extends StatelessWidget {
  final bool compact;

  const _EventCardSkeleton({
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = compact ? 138.0 : 190.0;
    final padding = compact ? 14.0 : 16.0;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: imageHeight,
                width: double.infinity,
                color: AppColors.background,
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: compact ? 78 : 96,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: compact ? 58 : 74,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: compact ? 170 : 220,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: compact ? 148 : 200,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: compact ? 120 : 170,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    compact ? 3 : 4,
                    (index) => Container(
                      width: index == 0
                          ? (compact ? 108 : 112)
                          : index == 1
                              ? (compact ? 82 : 96)
                              : 92,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ButtonSkeleton(width: compact ? 112 : 124),
                    _ButtonSkeleton(width: compact ? 98 : 110),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonSkeleton extends StatelessWidget {
  final double width;

  const _ButtonSkeleton({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
