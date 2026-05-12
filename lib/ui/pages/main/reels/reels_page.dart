import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/services/reel/reel_service.dart';
import 'package:Prive/data/services/user/user_service.dart';
import 'package:Prive/ui/widgets/reels/reel_item.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  final ReelService _reelService = ReelService();
  final UserService _userService = UserService();

  List<dynamic> _reels = [];
  int _currentIndex = 0;
  int _currentUserId = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _getCurrentUserId();
    await _loadReels();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final userData = await _userService.getCurrentUser();
      final userId = userData['id'];
      setState(() {
        _currentUserId = userId != null ? int.parse(userId.toString()) : 0;
      });
    } catch (e) {
      debugPrint('Error getting current user: $e');
      setState(() {
        _currentUserId = 0;
      });
    }
  }

  Future<void> _loadReels() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reels = await _reelService.getReels(page: 1);
      setState(() {
        _reels = reels;
        _currentPage = 1;
        _hasMore = reels.length >= 10;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReels() async {
    if (_isLoadingMore || !_hasMore || _isRefreshing) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newReels = await _reelService.getReels(page: nextPage);

      setState(() {
        if (newReels.isNotEmpty) {
          _reels.addAll(newReels);
          _currentPage = nextPage;
          _hasMore = newReels.length >= 10;
        } else {
          _hasMore = false;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more reels: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshReels() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final reels = await _reelService.getReels(page: 1);
      setState(() {
        _reels = reels;
        _currentPage = 1;
        _hasMore = reels.length >= 10;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error refreshing reels: $e');
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleLike(String reelId, int index) async {
    final oldReel = _reels[index];
    final wasLiked = oldReel['isLiked'] ?? false;

    // Optimistic update
    setState(() {
      _reels[index] = {
        ...oldReel,
        'isLiked': !wasLiked,
        'likes': (oldReel['likes'] ?? 0) + (wasLiked ? -1 : 1),
      };
    });

    try {
      if (wasLiked) {
        await _reelService.unlikeReel(reelId);
      } else {
        await _reelService.likeReel(reelId);
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        _reels[index] = oldReel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${wasLiked ? "unlike" : "like"} reel'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareReel(String reelId, int index) async {
    try {
      await _reelService.shareReel(reelId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reel shared successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // Show loading only on initial load with no data
          _reels.isEmpty && _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _reels.length + 1,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });

                    // Load more when nearing the end
                    if (index >= _reels.length - 2 &&
                        _hasMore &&
                        !_isLoadingMore) {
                      _loadMoreReels();
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index == _reels.length) {
                      if (_hasMore) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      } else if (_reels.isEmpty) {
                        return const Center(
                          child: Text(
                            'No reels available',
                            style: TextStyle(color: Colors.white54),
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
                      onRefresh: _refreshReels,
                      color: Colors.white,
                      child: ReelItem(
                        reel: _reels[index],
                        isActive: _currentIndex == index,
                        onNextReel: () {
                          if (index < _reels.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        onLike: () =>
                            _toggleLike(_reels[index]['id'].toString(), index),
                        onShare: () =>
                            _shareReel(_reels[index]['id'].toString(), index),
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
                    // TODO: Create reel
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Create reel feature coming soon'),
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
                      Icons.add,
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
