import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/ui/bloc/gallery_profile_cubit.dart';
import 'package:social_media_app/ui/pages/main/profile/edit_profile_page.dart';
import 'package:social_media_app/ui/pages/settings/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isOwnProfile;
  final String? userId;

  const ProfilePage({
    super.key,
    this.isOwnProfile = true,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isFollowing = false;
  int _selectedAccount = 0;

  final List<Map<String, String>> _accounts = [
    {
      'name': 'Fush',
      'username': '@fush.co',
      'avatar': 'assets/images/img_profile.jpeg',
    },
    {
      'name': 'Creative Studio',
      'username': '@creative',
      'avatar': 'profiles/profile_1.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeroProfile(),
                    const SizedBox(height: 16),
                    _buildAccountSwitcher(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              _buildStickyTabBar(),
            ];
          },
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildGalleryGrid(context),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam,
                        size: 48, color: AppColors.greyColor),
                    const SizedBox(height: 12),
                    Text("Video Content", style: AppTheme.greyTextStyle),
                  ],
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bookmark,
                        size: 48, color: AppColors.greyColor),
                    const SizedBox(height: 12),
                    Text("Tagged Posts", style: AppTheme.greyTextStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSwitcher() {
    return GestureDetector(
      onTap: () => _showAccountSwitcher(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.purpleColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _accounts[_selectedAccount]['name']!,
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.purpleColor,
                fontWeight: AppTheme.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.purpleColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAccountSwitcher() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Switch Account',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ..._accounts.asMap().entries.map((entry) {
                final index = entry.key;
                final account = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(account['avatar']!),
                  ),
                  title: Text(
                    account['name']!,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                  subtitle: Text(
                    account['username']!,
                    style: AppTheme.greyTextStyle,
                  ),
                  trailing: _selectedAccount == index
                      ? const Icon(Icons.check_circle,
                          color: AppColors.purpleColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedAccount = index);
                    Navigator.pop(context);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.purpleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.add, color: AppColors.purpleColor),
                ),
                title: Text(
                  'Add Account',
                  style: AppTheme.blackTextStyle
                      .copyWith(fontWeight: AppTheme.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
        },
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
      ),
      title: Text(
        _accounts[_selectedAccount]['username']!,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.bold,
          fontSize: 14,
        ),
      ),
      actions: [
        if (widget.isOwnProfile)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz, color: Colors.black),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroProfile() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.purpleColor, Colors.blueAccent.shade100],
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: AssetImage(
                    _accounts[_selectedAccount]['avatar']!,
                  ),
                ),
              ),
            ),
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: AppColors.purpleColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _accounts[_selectedAccount]['name']!,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 24,
          ),
        ),
        Text(
          _accounts[_selectedAccount]['username']!,
          style: AppTheme.greyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem("29", "Following"),
        _statItem("121.9k", "Followers"),
        _statItem("7.5M", "Likes"),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (widget.isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.purpleColor,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.greyColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      'EDIT PROFILE',
                      style: AppTheme.whiteTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              ),
              child:
                  const Icon(Icons.person_add_outlined, color: Colors.black87),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isFollowing = !_isFollowing);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _isFollowing
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.purpleColor, Colors.blue],
                          ),
                    border: _isFollowing
                        ? Border.all(
                            color: AppColors.greyColor.withOpacity(0.3))
                        : null,
                    boxShadow: _isFollowing
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.purpleColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      _isFollowing ? 'FOLLOWING' : 'FOLLOW',
                      style: TextStyle(
                        color: _isFollowing ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              ),
              child: const Icon(Icons.mail_outline, color: Colors.black87),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          indicatorColor: AppColors.purpleColor,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.greyColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: "PHOTOS"),
            Tab(text: "VIDEOS"),
            Tab(text: "TAGGED"),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context) {
    return BlocProvider(
      create: (context) => GalleryProfileCubit()..getGalleryProfile(),
      child: BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
        builder: (context, state) {
          if (state is GalleryProfileLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: state.galleryProfiles.length,
              itemBuilder: (context, index) {
                final gallery = state.galleryProfiles[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(gallery.image),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                gallery.like,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
