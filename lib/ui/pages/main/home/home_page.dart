import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/hooks/home/feed_hook.dart';
import 'package:social_media_app/data/models/status_model.dart';
import 'package:social_media_app/data/hooks/home/story_hook.dart';
import 'package:social_media_app/ui/pages/main/status/status_view_page.dart';
import 'package:social_media_app/ui/widgets/home/card_post.dart';
import 'package:social_media_app/ui/widgets/status/status_widget.dart';
import '../../../widgets/home/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FeedHook _feedHook = FeedHook();
  final StoryHook _storyHook = StoryHook();

  @override
  void initState() {
    super.initState();
    _feedHook.initialize();
    _storyHook.fetchStories();
  }

  @override
  void dispose() {
    _feedHook.dispose();
    _storyHook.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildCustomAppBar(context),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _feedHook.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    _buildStatusBar(context),
                    const SizedBox(height: 18),
                    _buildPostsList(),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_feedHook.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.purpleColor),
        ),
      );
    }

    if (_feedHook.error != null) {
      return Center(
        child: Column(
          children: [
            Text(_feedHook.error!, style: AppTheme.greyTextStyle),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _feedHook.fetchPosts(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._feedHook.posts.map((post) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                NamedRoutes.postDetailScreen,
                arguments: post,
              );
            },
            child: CardPost(post: post),
          );
        }),
        if (_feedHook.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _feedHook.loadingMore
                ? const CircularProgressIndicator(color: AppColors.purpleColor)
                : TextButton(
                    onPressed: () => _feedHook.loadMorePosts(),
                    child: Text('Load More',
                        style: AppTheme.blackTextStyle
                            .copyWith(color: AppColors.purpleColor)),
                  ),
          ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    final stories = _storyHook.stories;

    if (_storyHook.loading && stories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.purpleColor)),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StatusWidget(
            status: const StatusModel(
              name: 'Your Story',
              imgProfile: 'assets/profiles/profile_1.jpeg',
              statusImage: '',
              time: '',
            ),
            isAddStatus: true,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, NamedRoutes.createStatusScreen);
            },
          ),
          ...stories.map((story) {
            final status = StatusModel(
              name: story['user']?['name'] ?? 'User',
              imgProfile:
                  story['user']?['avatar'] ?? 'assets/profiles/profile_1.jpeg',
              statusImage: story['attachments']?.isNotEmpty == true
                  ? story['attachments'][0]['url'] ?? ''
                  : '',
              time: story['time'] ?? '',
              isViewed: story['isSeen'] ?? false,
            );
            return StatusWidget(
              status: status,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatusViewPage(
                      statuses: stories
                          .map((s) => StatusModel(
                                name: s['user']?['name'] ?? 'User',
                                imgProfile: s['user']?['avatar'] ?? '',
                                statusImage:
                                    s['attachments']?.isNotEmpty == true
                                        ? s['attachments'][0]['url'] ?? ''
                                        : '',
                                time: s['time'] ?? '',
                                isViewed: s['isSeen'] ?? false,
                              ))
                          .toList(),
                      initialIndex: stories.indexOf(story),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  CustomAppBar _buildCustomAppBar(BuildContext context) {
    return CustomAppBar(
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withOpacity(0.2),
                  blurRadius: 35,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child:
                Image.asset('assets/images/prive.png', width: 60, height: 60),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, NamedRoutes.notificationScreen),
            child: Image.asset("assets/images/ic_notification.png",
                width: 30, height: 30),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {},
            child: Image.asset("assets/images/ic_search.png",
                width: 30, height: 30),
          ),
          const Spacer(),
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, NamedRoutes.profileScreen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                color: AppColors.backgroundColor,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.whiteColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blackColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: const DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage("assets/images/img_profile.jpeg"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text("Fush",
                      style: AppTheme.blackTextStyle
                          .copyWith(fontWeight: AppTheme.bold, fontSize: 12)),
                  const SizedBox(width: 2),
                  Image.asset("assets/images/ic_checklist.png", width: 16),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
