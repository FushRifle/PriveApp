import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:clique/app/configs/colors.dart';

class HomeFeedLoadingShimmer extends StatelessWidget {
  const HomeFeedLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF121B25) : const Color(0xFFE7EDF2),
      highlightColor:
          isDark ? const Color(0xFF213040) : const Color(0xFFF9FBFC),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 100),
        child: Column(
          children: [
            ...List.generate(
              4,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
                child: _FeedCardSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF121B25) : const Color(0xFFFCFDFE);
    final border = isDark ? const Color(0xFF2A3746) : const Color(0xFFD9E1E8);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface,
                    border: Border.all(
                      color: border.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 96,
                        height: 10,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 12,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                top: BorderSide(
                  color: border.withOpacity(0.32),
                ),
                bottom: BorderSide(
                  color: border.withOpacity(0.32),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 210,
                  height: 12,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Dot(),
                    const SizedBox(width: 12),
                    _Dot(),
                    const SizedBox(width: 12),
                    _Dot(),
                    const Spacer(),
                    Container(
                      width: 76,
                      height: 18,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF121B25) : const Color(0xFFFCFDFE);
    final border = isDark ? const Color(0xFF2A3746) : const Color(0xFFD9E1E8);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: surface,
        border: Border.all(color: border.withOpacity(0.4)),
      ),
    );
  }
}
