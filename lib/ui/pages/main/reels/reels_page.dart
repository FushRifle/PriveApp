import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/providers/reels_provider.dart';
import 'package:Prive/data/services/user/user_service.dart';
import 'package:Prive/ui/widgets/reels/reel_item.dart';

class ReelsPage extends ConsumerStatefulWidget {
  const ReelsPage({super.key});

  @override
  ConsumerState<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends ConsumerState<ReelsPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCurrentUserAndReels();
  }

  Future<void> _loadCurrentUserAndReels() async {
    await _getCurrentUserId();
    // Load reels after getting user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelsProvider.notifier).loadReels();
    });
  }

  Future<void> _getCurrentUserId() async {
    try {
      final userService = UserService();
      final userData = await userService.getCurrentUser();
      final userId = userData['id'];
      setState(() {
        _currentUserId = userId != null ? int.parse(userId.toString()) : 0;
      });
      debugPrint('Current user ID: $_currentUserId');
    } catch (e) {
      debugPrint('Error getting current user: $e');
      setState(() {
        _currentUserId = 0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reelsState = ref.watch(reelsProvider);
    final reels = reelsState.reels;
    final isLoading = reelsState.isLoading;
    final hasMore = reelsState.hasMore;
    final error = reelsState.error;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isLoading && reels.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else if (error != null && reels.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong, refresh page.',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(reelsProvider.notifier).refreshReels();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(120, 48),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Refresh',
                      style: AppTheme.whiteTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length + 1,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });

                // Load more when approaching the end
                if (index >= reels.length - 2 && hasMore && !isLoading) {
                  ref.read(reelsProvider.notifier).loadMoreReels();
                }
              },
              itemBuilder: (context, index) {
                if (index == reels.length) {
                  if (hasMore) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No more reels',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(reelsProvider.notifier).refreshReels();
                  },
                  color: Colors.white,
                  child: ReelItem(
                    reel: reels[index],
                    isActive: _currentIndex == index,
                    onNextReel: () {
                      if (index < reels.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    onLike: () {
                      ref
                          .read(reelsProvider.notifier)
                          .toggleLike(reels[index].id, index);
                    },
                    onShare: () {
                      ref
                          .read(reelsProvider.notifier)
                          .shareReel(reels[index].id, index);
                    },
                    currentUserId: _currentUserId,
                  ),
                );
              },
            ),
          // Header - Back button and Camera
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushReplacementNamed(
                      context,
                      NamedRoutes.homeScreen,
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Open camera for reel
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camera feature coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 20,
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
