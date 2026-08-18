import 'dart:async';

import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  final FutureOr<void> Function()? onComplete;

  const OnboardingPage({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _background = Color(0xFF0B0D14);
  static const _cardRadius = 32.0;

  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _pages = <({
    String image,
    String eyebrow,
    String title,
    String body,
    IconData icon,
    Color accent,
  })>[
    (
      image: 'assets/images/img_post_1.jpeg',
      eyebrow: 'CREATE',
      title: 'Share what feels real',
      body: 'Post stories, reels, and everyday moments worth remembering.',
      icon: Icons.auto_awesome_rounded,
      accent: AppColors.primary,
    ),
    (
      image: 'assets/images/img_post_2.jpeg',
      eyebrow: 'DISCOVER',
      title: 'Find your kind of people',
      body: 'Explore communities, events, and conversations without the noise.',
      icon: Icons.people_alt_rounded,
      accent: AppColors.secondary,
    ),
    (
      image: 'assets/images/img_post_3.jpeg',
      eyebrow: 'CONNECT',
      title: 'Keep the good energy going',
      body: 'React, reply, save, and come back to the moments that matter.',
      icon: Icons.forum_rounded,
      accent: Color(0xFFFFB86B),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _pages[_page];

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _OnboardingBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 14, 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Text(
                        'Clique',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finishing ? null : _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 650;
                      return PageView.builder(
                        controller: _controller,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _pages.length,
                        onPageChanged: (page) => setState(() => _page = page),
                        itemBuilder: (context, index) {
                          return _OnboardingSlide(
                            item: _pages[index],
                            compact: compact,
                            radius: _cardRadius,
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: List.generate(
                                _pages.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  width: index == _page ? 30 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 7),
                                  decoration: BoxDecoration(
                                    color: index == _page
                                        ? item.accent
                                        : Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _finishing
                            ? null
                            : _page == _pages.length - 1
                                ? _finish
                                : _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: item.accent,
                          foregroundColor: const Color(0xFF11131A),
                          disabledBackgroundColor: item.accent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _finishing
                              ? const SizedBox.square(
                                  key: ValueKey('loading'),
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFF11131A),
                                  ),
                                )
                              : Row(
                                  key: ValueKey(_page),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _page == _pages.length - 1
                                          ? 'Get started'
                                          : 'Continue',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      if (widget.onComplete != null) {
        await widget.onComplete!();
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }
}

class _OnboardingSlide extends StatelessWidget {
  final ({
    String image,
    String eyebrow,
    String title,
    String body,
    IconData icon,
    Color accent,
  }) item;
  final bool compact;
  final double radius;

  const _OnboardingSlide({
    required this.item,
    required this.compact,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 8 : 16, 20, 8),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: item.accent.withOpacity(0.16),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: item.accent.withOpacity(0.15),
                        child: Icon(
                          item.icon,
                          color: item.accent,
                          size: 72,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.06),
                            Colors.black.withOpacity(0.68),
                          ],
                          stops: const [0, 0.52, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: item.accent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.24),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          item.icon,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              22,
              compact ? 16 : 20,
              22,
              compact ? 17 : 22,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.065),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.11)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eyebrow,
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 23 : 27,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  item.body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: compact ? 13 : 14,
                    height: 1.45,
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

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF15101B),
            Color(0xFF0B0D14),
            Color(0xFF091516),
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _Glow(color: AppColors.primary, size: 270),
          ),
          Positioned(
            bottom: -130,
            left: -110,
            child: _Glow(color: AppColors.secondary, size: 290),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0)],
        ),
      ),
    );
  }
}
