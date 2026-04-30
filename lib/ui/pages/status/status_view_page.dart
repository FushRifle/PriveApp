import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/data/status_model.dart';

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

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });

    _progressController.forward();
    _setupAutoAdvance();
  }

  void _setupAutoAdvance() {
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
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
      Navigator.pop(context);
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
        statusBarColor: Colors.black,
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
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.statuses.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
                _progressController.reset();
                _progressController.forward();
              },
              itemBuilder: (context, index) {
                return _buildStatusContent(widget.statuses[index]);
              },
            ),
            _buildHeader(),
            _buildProgressBars(),
            _buildReplyBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage(status.statusImage),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final status = widget.statuses[currentIndex];
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(status.imgProfile),
          ),
          const SizedBox(width: 12),
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 5,
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
                color: Colors.white.withOpacity(0.3),
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
                      ? FractionallySizedBox(
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
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

  Widget _buildReplyBar() {
    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Send message',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {
                // Handle like
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purpleColor,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                // Handle send
              },
            ),
          ),
        ],
      ),
    );
  }
}
