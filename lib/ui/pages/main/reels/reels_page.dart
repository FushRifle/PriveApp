import 'package:clique/ui/pages/main/reels/create_reel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/resources/constant/named_routes.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/data/services/user/user_service.dart';
import 'package:clique/ui/widgets/reels/reel_item.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  final UserService _userService = UserService();
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _getCurrentUserId();
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

    return BlocProvider(
      create: (context) => ReelBloc()..add(const LoadReels()),
      child: BlocConsumer<ReelBloc, ReelState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<ReelBloc>().add(ClearReelError());
          }
        },
        builder: (context, state) {
          final reels = state.reels;
          final isLoading = state.isLoading;
          final isLoadingMore = state.isLoadingMore;
          final hasMore = state.hasMore;
          final isRefreshing = state.isRefreshing;

          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                reels.isEmpty && isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: reels.length + 1,
                        onPageChanged: (index) {
                          if (index >= reels.length - 2 &&
                              hasMore &&
                              !isLoadingMore &&
                              !isRefreshing) {
                            context.read<ReelBloc>().add(LoadMoreReels());
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
                            } else if (reels.isEmpty) {
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
                            onRefresh: () async {
                              context.read<ReelBloc>().add(RefreshReels());
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                            },
                            color: Colors.white,
                            child: ReelItem(
                              reel: reels[index],
                              isActive: true,
                              onNextReel: () {
                                if (index < reels.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              onLike: () {
                                final reelId = reels[index]['id'].toString();
                                final isLiked =
                                    reels[index]['isLiked'] ?? false;

                                if (isLiked) {
                                  context.read<ReelBloc>().add(
                                        UnlikeReel(
                                            reelId: reelId, index: index),
                                      );
                                } else {
                                  context.read<ReelBloc>().add(
                                        LikeReel(reelId: reelId, index: index),
                                      );
                                }
                              },
                              onShare: () {
                                final reelId = reels[index]['id'].toString();
                                context.read<ReelBloc>().add(
                                      ShareReel(reelId: reelId, index: index),
                                    );
                              },
                              currentUserId: _currentUserId,
                            ),
                          );
                        },
                      ),
                // Header
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CreateReelPage()),
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
        },
      ),
    );
  }
}
