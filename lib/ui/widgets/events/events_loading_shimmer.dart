import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:clique/app/configs/colors.dart';

class EventsLoadingShimmer extends StatelessWidget {
  const EventsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.secondary.withOpacity(0.25),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSkeleton(),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _ChipSkeleton(width: 92),
                      _ChipSkeleton(width: 82),
                      _ChipSkeleton(width: 78),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _SearchSkeleton(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: _SectionSkeleton(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _FeaturedCardSkeleton(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: _SectionSkeleton(short: true),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList.separated(
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return const _CompactCardSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 112,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 260,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _ChipSkeleton extends StatelessWidget {
  final double width;

  const _ChipSkeleton({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                  child: Container(
                    width: 70 + (index.isEven ? 10 : 0),
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final bool short;

  const _SectionSkeleton({this.short = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: short ? 140 : 110,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: short ? 180 : 240,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCardSkeleton extends StatelessWidget {
  const _FeaturedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _EventCardSkeleton(compact: false);
  }
}

class _CompactCardSkeleton extends StatelessWidget {
  const _CompactCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _EventCardSkeleton(compact: true);
  }
}

class _EventCardSkeleton extends StatelessWidget {
  final bool compact;

  const _EventCardSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final imageHeight = compact ? 136.0 : 178.0;
    final contentPadding = compact ? 14.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
                right: 14,
                child: Row(
                  children: [
                    Container(
                      width: compact ? 78 : 96,
                      height: 27,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: compact ? 58 : 72,
                      height: 27,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(contentPadding),
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
                            width: compact ? 165 : 220,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: compact ? 150 : 200,
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
