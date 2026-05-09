import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/data/models/status_model.dart';

class StatusViewPage extends StatefulWidget {
  final List<StatusModel> statuses;
  final int initialIndex;

  const StatusViewPage({
    super.key,
    required this.statuses,
    required this.initialIndex,
  });

  @override
  State<StatusViewPage> createState() => _StatusViewPageState();
}

class _StatusViewPageState extends State<StatusViewPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late int currentIndex;
  late PageController _pageController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _progressController.forward();
    _setupAutoAdvance();
  }

  void _setupAutoAdvance() {
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _nextStatus();
      }
    });
  }

  void _nextStatus() {
    if (currentIndex < widget.statuses.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _progressController.forward();
      } else {
        _progressController.stop();
      }
      _isPaused = !_isPaused;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
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
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousStatus();
          } else {
            _nextStatus();
          }
        },
        onLongPress: _togglePause,
        onLongPressUp: _togglePause,
        child: Stack(
          children: [
            // Status Content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.statuses.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
                _progressController.reset();
                if (!_isPaused) {
                  _progressController.forward();
                }
              },
              itemBuilder: (context, index) {
                return _buildStatusContent(widget.statuses[index]);
              },
            ),

            // Header
            _buildHeader(),

            // Progress Bars
            _buildProgressBars(),

            // Bottom Actions
            _buildBottomActions(),

            // Pause Indicator
            if (_isPaused)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Icon(
                    Icons.pause_circle_filled,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    final hasImage = status.statusImage.isNotEmpty;
    final hasText = status.statusText != null && status.statusText!.isNotEmpty;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: hasImage
          ? BoxDecoration(
              image: DecorationImage(
                image: _getImageProvider(status.statusImage),
                fit: BoxFit.cover,
              ),
            )
          : BoxDecoration(
              color: _getBackgroundColor(status.backgroundColor),
            ),
      child: Container(
        decoration: hasImage
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              )
            : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: hasText
                ? SingleChildScrollView(
                    child: Text(
                      status.statusText!,
                      textAlign: _getTextAlign(status.textAlign),
                      style: _getTextStyle(status),
                    ),
                  )
                : hasImage
                    ? const SizedBox.shrink()
                    : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return AssetImage(imageUrl);
  }

  TextAlign _getTextAlign(String? textAlign) {
    switch (textAlign) {
      case 'center':
        return TextAlign.center;
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  TextStyle _getTextStyle(StatusModel status) {
    final hasImage = status.statusImage.isNotEmpty;
    return TextStyle(
      color: Colors.white,
      fontSize: status.effectiveFontSize,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.5,
      shadows: hasImage
          ? [
              const Shadow(
                blurRadius: 10,
                color: Colors.black45,
                offset: Offset(2, 2),
              ),
            ]
          : null,
    );
  }

  Color _getBackgroundColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF1D1B20);
    }

    try {
      String colorStr = hexColor;
      if (colorStr.startsWith('#')) {
        colorStr = colorStr.substring(1);
      }
      if (colorStr.startsWith('0x')) {
        colorStr = colorStr.substring(2);
      }

      if (colorStr.length == 6) {
        return Color(int.parse('FF$colorStr', radix: 16));
      } else if (colorStr.length == 8) {
        return Color(int.parse(colorStr, radix: 16));
      }
    } catch (e) {
      print('Error parsing color: $e');
    }

    return const Color(0xFF1D1B20);
  }

  Widget _buildHeader() {
    final status = widget.statuses[currentIndex];
    return Positioned(
      top: MediaQuery.of(context).padding.top + 30,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: _buildAvatar(status.imgProfile),
            ),
          ),
          const SizedBox(width: 12),

          // Name and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  status.time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Close button - Navigates back to home screen
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushReplacementNamed(
                context,
                NamedRoutes.homeScreen,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.isEmpty) {
      return Container(
        color: Colors.grey,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      );
    }

    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey,
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      );
    }

    return Image.asset(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(
          widget.statuses.length,
          (index) => Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: index < currentIndex
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : index == currentIndex
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progressController.value,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        )
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final status = widget.statuses[currentIndex];
    final TextEditingController replyController = TextEditingController();

    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Message Input
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: replyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Send message',
                  hintStyle: TextStyle(
                    color: AppColors.blackTextColor.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _sendReply(value, status);
                    replyController.clear();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Like Button
          IconButton(
            onPressed: () => _likeStatus(status),
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              side: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              padding: const EdgeInsets.all(10),
            ),
          ),

          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: () {
              if (replyController.text.isNotEmpty) {
                _sendReply(replyController.text, status);
                replyController.clear();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendReply(String message, StatusModel status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply sent to ${status.name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _likeStatus(StatusModel status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liked ${status.name}\'s story'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
