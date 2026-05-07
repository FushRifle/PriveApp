import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          _buildShimmerCard(),
          const SizedBox(height: 16),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and age
                Container(
                  width: 150,
                  height: 24,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                // Location
                Container(
                  width: 100,
                  height: 16,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                // Bio lines
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 6),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.grey[300],
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
