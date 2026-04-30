import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/status_model.dart';
import 'package:social_media_app/ui/bloc/post_cubit.dart';
import 'package:social_media_app/ui/pages/main/status/status_view_page.dart';
import 'package:social_media_app/ui/widgets/home/card_post.dart';
import 'package:social_media_app/ui/widgets/status/status_widget.dart';

import '../../../widgets/home/custom_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<StatusModel> _statuses = const [
    StatusModel(
      name: 'Sarah',
      imgProfile: 'profiles/profile_1.jpeg',
      statusImage: 'profiles/profile_1.jpeg',
      time: '2m ago',
      isViewed: false,
    ),
    StatusModel(
      name: 'Mike',
      imgProfile: 'profiles/profile_2.jpeg',
      statusImage: 'profiles/profile_2.jpeg',
      time: '15m ago',
      isViewed: false,
    ),
    StatusModel(
      name: 'Emma',
      imgProfile: 'profiles/profile_3.jpeg',
      statusImage: 'profiles/profile_3.jpeg',
      time: '1h ago',
      isViewed: true,
    ),
    StatusModel(
      name: 'James',
      imgProfile: 'profiles/profile_4.jpeg',
      statusImage: 'profiles/profile_4.jpeg',
      time: '2h ago',
      isViewed: true,
    ),
  ];

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
        // Fixed header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildCustomAppBar(context),
            ],
          ),
        ),
        // Scrollable content (status + feed)
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  _buildStatusBar(context),
                  const SizedBox(height: 18),
                  BlocProvider(
                    create: (context) => PostCubit()..getPosts(),
                    child: BlocBuilder<PostCubit, PostState>(
                      builder: (context, state) {
                        if (state is PostError) {
                          return Center(child: Text(state.message));
                        } else if (state is PostLoaded) {
                          return Column(
                            children: state.posts
                                .map((post) => GestureDetector(
                                      onTap: () {
                                        // Navigate to post detail
                                        Navigator.pushNamed(
                                          context,
                                          NamedRoutes.postDetailScreen,
                                          arguments: post,
                                        );
                                      },
                                      child: CardPost(post: post),
                                    ))
                                .toList(),
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                  // Add bottom padding to account for the bottom nav bar
                  const SizedBox(height: 130),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add status button
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
              Navigator.pushNamed(
                context,
                NamedRoutes.createStatusScreen,
              );
            },
          ),
          // Status items
          ..._statuses.map((status) => StatusWidget(
                status: status,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatusViewPage(
                        statuses: _statuses,
                        initialIndex: _statuses.indexOf(status),
                      ),
                    ),
                  );
                },
              )),
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
            height: 40,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withOpacity(0.2),
                  blurRadius: 35,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/prive.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, NamedRoutes.notificationScreen);
            },
            child: Image.asset(
              "assets/images/ic_notification.png",
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              print('Search tapped');
              // TODO: Navigate to search
            },
            child: Image.asset(
              "assets/images/ic_search.png",
              width: 24,
              height: 24,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, NamedRoutes.profileScreen);
            },
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
                      border: Border.all(
                        color: AppColors.whiteColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blackColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: const DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(
                          "assets/images/img_profile.jpeg",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Fush ",
                    style: AppTheme.blackTextStyle
                        .copyWith(fontWeight: AppTheme.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 2),
                  Image.asset(
                    "assets/images/ic_checklist.png",
                    width: 16,
                  ),
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
