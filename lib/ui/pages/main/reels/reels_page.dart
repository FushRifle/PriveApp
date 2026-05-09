import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/models/reel_model.dart';
import 'package:Prive/data/services/reel/reel_service.dart';
import 'package:Prive/data/services/user/user_service.dart';
import 'package:Prive/ui/widgets/reels/reel_item.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final ReelService _reelService = ReelService();
  final UserService _userService = UserService();

  late PageController _pageController;
  int _currentIndex = 0;

  List<ReelModel> _reels = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  String _errorMessage = '';
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCurrentUserAndReels();
  }

  Future<void> _loadCurrentUserAndReels() async {
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
      debugPrint('Current user ID: $_currentUserId');
    } catch (e) {
      debugPrint('Error getting current user: $e');
      setState(() {
        _currentUserId = 0;
      });
    }
  }

  Future<void> _loadReels({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final newReelsData = await _reelService.getReels(page: _currentPage);

      final List<ReelModel> newReels =
          newReelsData.map((data) => ReelModel.fromJson(data)).toList();

      setState(() {
        if (refresh || _currentPage == 1) {
          _reels = newReels;
          _currentIndex = 0;
        } else {
          _reels.addAll(newReels);
        }
        _hasMore = newReels.isNotEmpty;
        _isLoading = false;
      });

      if (newReels.isNotEmpty) {
        _currentPage++;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reels: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _likeReel(String reelId, int index) async {
    try {
      final response = await _reelService.likeReel(reelId);
      setState(() {
        final currentLikes = _reels[index].likeCount;
        _reels[index] = _reels[index].copyWith(
          likeCount: currentLikes + 1,
          isLiked: true,
        );
      });
    } catch (e) {
      debugPrint('Error liking reel: $e');
    }
  }

  Future<void> _unlikeReel(String reelId, int index) async {
    try {
      final response = await _reelService.unlikeReel(reelId);
      setState(() {
        final currentLikes = _reels[index].likeCount;
        _reels[index] = _reels[index].copyWith(
          likeCount: currentLikes - 1,
          isLiked: false,
        );
      });
    } catch (e) {
      debugPrint('Error unliking reel: $e');
    }
  }

  Future<void> _shareReel(String reelId) async {
    try {
      await _reelService.shareReel(reelId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reel shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing reel: $e');
    }
  }

  Future<void> _refreshReels() async {
    await _loadReels(refresh: true);
  }

  void _loadMoreReels() {
    if (_hasMore && !_isLoading) {
      _loadReels();
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
          if (_isLoading && _reels.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else if (_errorMessage.isNotEmpty && _reels.isEmpty)
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
                    onPressed: _refreshReels,
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
              itemCount: _reels.length + 1,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });

                if (index >= _reels.length - 2) {
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
                    onLike: () {
                      if (_reels[index].isLiked) {
                        _unlikeReel(_reels[index].id, index);
                      } else {
                        _likeReel(_reels[index].id, index);
                      }
                    },
                    onShare: () => _shareReel(_reels[index].id),
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
