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

  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _pages = <({
    String image,
    String eyebrow,
    String title,
    String body,
    Color accent,
  })>[
    (
      image: 'assets/images/img_post_1.jpeg',
      eyebrow: 'CREATE',
      title: 'Share what feels real',
      body: 'Post stories, reels, and everyday moments worth remembering.',
      accent: AppColors.primary,
    ),
    (
      image: 'assets/images/img_post_2.jpeg',
      eyebrow: 'DISCOVER',
      title: 'Find your kind of people',
      body: 'Explore communities, events, and conversations without the noise.',
      accent: AppColors.secondary,
    ),
    (
      image: 'assets/images/img_post_3.jpeg',
      eyebrow: 'CONNECT',
      title: 'Keep the good energy going',
      body: 'React, reply, save, and come back to the moments that matter.',
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
          PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => _OnboardingSlide(
              image: _pages[index].image,
              accent: _pages[index].accent,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8A071019),
                  Color(0x18071019),
                  Color(0x66071019),
                  Color(0xF2071019),
                ],
                stops: [0, 0.34, 0.62, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _OnboardingHeader(
                  page: _page,
                  pageCount: _pages.length,
                  onSkip: _finishing ? null : _finish,
                  accent: item.accent,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Material(
                    color: _background.withOpacity(0.78),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: Column(
                              key: ValueKey(_page),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.eyebrow,
                                  style: TextStyle(
                                    color: item.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.9,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    height: 1.08,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.66),
                                    fontSize: 13.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _finishing
                                ? null
                                : _page == _pages.length - 1
                                    ? _finish
                                    : _next,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: item.accent,
                              disabledBackgroundColor:
                                  item.accent.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _finishing
                                  ? const SizedBox.square(
                                      key: ValueKey('loading'),
                                      dimension: 21,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      key: ValueKey(_page),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _page == _pages.length - 1
                                              ? 'Join Clique'
                                              : 'Continue',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
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
  final String image;
  final Color accent;

  const _OnboardingSlide({
    required this.image,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      image,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: const Color(0xFF111923),
        child: Center(
          child: Image.asset(
            'assets/icons/clique-new.png',
            width: 84,
            height: 84,
            color: accent.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final int page;
  final int pageCount;
  final Color accent;
  final VoidCallback? onSkip;

  const _OnboardingHeader({
    required this.page,
    required this.pageCount,
    required this.accent,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Clique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
                Text(
                  'Your people. Your moments.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                pageCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: index == page ? 17 : 5,
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == pageCount - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: index == page
                        ? accent
                        : Colors.white.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
