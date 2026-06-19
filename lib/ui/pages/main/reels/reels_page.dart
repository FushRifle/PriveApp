import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/ui/widgets/reels/reel_item.dart';

class ReelsPage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isVisible;

  const ReelsPage({
    super.key,
    this.onBack,
    this.isVisible = true,
  });

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  late final ReelBloc _reelBloc;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _reelBloc = ReelBloc()..add(const LoadReels());
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    context.read<UserBloc>().add(LoadCurrentUser());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reelBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return BlocProvider.value(
      value: _reelBloc,
      child: BlocConsumer<ReelBloc, ReelState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.red,
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
          final showInitialLoader = reels.isEmpty && isLoading;

          return BlocBuilder<UserBloc, UserState>(
            builder: (context, userState) {
              final currentUserId = userState.currentUser?['id'] ?? 0;

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  _handleBack();
                },
                child: Scaffold(
                  backgroundColor: AppColors.backgroundColorDark,
                  body: Stack(
                    children: [
                      showInitialLoader
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.secondary,
                                strokeWidth: 2,
                              ),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.vertical,
                              itemCount: reels.length + 1,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
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
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  } else if (reels.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No reels available',
                                        style:
                                            TextStyle(color: AppColors.white54),
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                      child: Text(
                                        'No more reels',
                                        style:
                                            TextStyle(color: AppColors.white54),
                                      ),
                                    );
                                  }
                                }

                                return RefreshIndicator(
                                  onRefresh: () async {
                                    context
                                        .read<ReelBloc>()
                                        .add(RefreshReels());
                                    await Future.delayed(
                                        const Duration(milliseconds: 500));
                                  },
                                  color: AppColors.white,
                                  child: ReelItem(
                                    reel: reels[index],
                                    isActive: widget.isVisible &&
                                        index == _currentIndex,
                                    onNextReel: () {
                                      if (index < reels.length - 1) {
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    index: index,
                                    currentUserId: currentUserId,
                                  ),
                                );
                              },
                            ),
                      // Header
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 20,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _handleBack();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
  }
}
