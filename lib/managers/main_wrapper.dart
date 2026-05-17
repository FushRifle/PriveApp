import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/ui/pages/main/explore/explore_page.dart';
import 'package:Prive/ui/pages/main/chat/inbox_page.dart';
import 'package:Prive/ui/pages/main/home/home_page.dart';
import 'package:Prive/ui/pages/main/reels/reels_page.dart';
import 'package:Prive/ui/widgets/home/clip_status_bar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DiscoverPage(),
    const ReelsPage(),
    const InboxPage(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(icon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.explore, label: 'Discover'),
    BottomNavItem(icon: Icons.play_circle_fill, label: 'Reels'),
    BottomNavItem(icon: Icons.message, label: 'Inbox'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          if (_currentIndex != 2) _buildBackgroundGradient(),
          if (_currentIndex != 2)
            Positioned(
              bottom: 72,
              child: Transform.rotate(
                angle: 11,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      NamedRoutes.createPostScreen,
                    );
                  },
                  child: ClipPath(
                    clipper: ClipStatusBar(),
                    child: Container(
                      height: 110,
                      width: 40,
                      color: AppColors.primary,
                      child: const Icon(
                        Icons.add,
                        size: 24,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentIndex != 2) _buildBottomNavBar(backgroundColor),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColor = isDarkMode ? AppColors.darkBackground : Colors.white;

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColor.withOpacity(0),
            gradientColor.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(Color backgroundColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < _navItems.length; i++)
                _buildNavItem(_navItems[i], i, unselectedColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BottomNavItem item, int index, Color unselectedColor) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    Icon(
                      item.icon,
                      size: 24,
                      color: isSelected ? AppColors.primary : unselectedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}
