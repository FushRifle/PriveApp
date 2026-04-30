import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/data/reel_model.dart';
import 'package:social_media_app/ui/widgets/reels/reel_item.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<ReelModel> _reels = [
    ReelModel(
      username: 'sophie.anderson',
      userProfile: 'assets/images/profile_1.jpeg',
      videoUrl: '',
      caption: 'Beautiful sunset at the beach 🌅',
      hashtags: ['sunset', 'beach', 'nature'],
      audio: 'Original Sound',
      audioArtist: 'sophie.anderson',
      like: '12.4K',
      comment: '234',
      share: '567',
      isVerified: true,
    ),
    ReelModel(
      username: 'marcus.fitness',
      userProfile: 'assets/images/profile_2.jpeg',
      videoUrl: '',
      caption: 'Morning workout routine 💪',
      hashtags: ['fitness', 'workout', 'motivation'],
      audio: 'Eye of the Tiger',
      audioArtist: 'Survivor',
      like: '45.2K',
      comment: '1.2K',
      share: '3.4K',
      isVerified: false,
    ),
    ReelModel(
      username: 'elena.travels',
      userProfile: 'assets/images/profile_3.jpeg',
      videoUrl: '',
      caption: 'Exploring hidden gems in Bali 🏝️',
      hashtags: ['travel', 'bali', 'adventure'],
      audio: 'Paradise',
      audioArtist: 'Coldplay',
      like: '89.1K',
      comment: '2.5K',
      share: '8.9K',
      isVerified: true,
    ),
    ReelModel(
      username: 'alex.tech',
      userProfile: 'assets/images/profile_4.jpeg',
      videoUrl: '',
      caption: 'New gadget unboxing! 📱',
      hashtags: ['tech', 'unboxing', 'gadgets'],
      audio: 'Tech Vibes',
      audioArtist: 'alex.tech',
      like: '23.7K',
      comment: '567',
      share: '1.2K',
      isVerified: false,
    ),
    ReelModel(
      username: 'olivia.yoga',
      userProfile: 'assets/images/profile_5.jpeg',
      videoUrl: '',
      caption: 'Morning yoga flow 🧘‍♀️',
      hashtags: ['yoga', 'wellness', 'mindfulness'],
      audio: 'Calm Mind',
      audioArtist: 'Meditation Music',
      like: '34.8K',
      comment: '890',
      share: '2.1K',
      isVerified: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ReelItem(
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
              );
            },
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 8,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          // Progress indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                _reels.length,
                (index) => Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: index <= _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
