import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/services/match/match_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final MatchService _matchService = MatchService();

  List<dynamic> _matches = [];
  List<dynamic> _recommendations = [];
  bool _isLoadingMatches = true;
  bool _isLoadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMatches(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoadingMatches = true;
    });

    try {
      final matches = await _matchService.getMatches();
      setState(() {
        _matches = matches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMatches = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final recommendations = await _matchService.getRecommendations();
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRecommendations = false;
      });

      debugPrint('Error loading recommendations: $e');
    }
  }

  Future<void> _acceptMatch(int matchId, int userId) async {
    try {
      await _matchService.acceptMatch(matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match accepted! Start chatting now'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
        _loadMatches(); // Refresh matches
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectMatch(int matchId) async {
    try {
      await _matchService.rejectMatch(matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match rejected'),
            backgroundColor: AppColors.greyColor,
            duration: const Duration(seconds: 1),
          ),
        );
        _loadMatches(); // Refresh matches
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToChat(dynamic match) {
    // TODO: Navigate to chat screen
    debugPrint('Navigate to chat with: ${match['name']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.blackTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connections',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.greyColor.withOpacity(0.1),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New Matches Section
                _buildNewMatchesSection(),
                const SizedBox(height: 32),
                // Recent Connections Section
                _buildRecentConnectionsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NEW MATCHES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.greyColor,
              ),
            ),
            if (_recommendations.isNotEmpty)
              Text(
                '${_recommendations.length} available',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.greyColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingRecommendations)
          SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          )
        else if (_recommendations.isEmpty)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.greyColor.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 32,
                    color: AppColors.greyColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No new matches yet',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep swiping to find more people',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final user = _recommendations[index];
                return _buildRecommendationCard(user);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(dynamic user) {
    final bool isNew = true;
    final String name = user['name'] ?? 'User';
    final String? avatar = user['image'];
    final int userId = user['id'] ?? 0;
    final int matchScore = user['matchScore'] ?? 0;

    return GestureDetector(
      onTap: () => _acceptMatch(userId, userId),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: avatar != null && avatar.isNotEmpty
                        ? (avatar.startsWith('http')
                            ? Image.network(avatar, fit: BoxFit.cover)
                            : Image.asset(avatar, fit: BoxFit.cover))
                        : Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (isNew)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: AppColors.whiteColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$matchScore%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentConnectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT CONNECTIONS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.greyColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingMatches)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          )
        else if (_matches.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.greyColor.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColors.greyColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No connections yet',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start swiping to find your matches',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final match = _matches[index];
              return _buildConnectionCard(match);
            },
          ),
      ],
    );
  }

  Widget _buildConnectionCard(dynamic match) {
    final String name = match['name'] ?? 'User';
    final String? avatar = match['image'];
    final String time = match['matchedAt'] ?? 'Recently';
    final bool isAccepted = match['accepted'] ?? false;
    final int matchId = match['id'] ?? 0;
    final int userId = match['user']['id'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greyColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? (avatar.startsWith('http')
                      ? Image.network(avatar, fit: BoxFit.cover)
                      : Image.asset(avatar, fit: BoxFit.cover))
                  : Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAccepted ? 'Connected · $time' : 'Pending response · $time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAccepted ? AppColors.primary : AppColors.greyColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isAccepted)
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.greyColor,
                    size: 22,
                  ),
                  onPressed: () => _rejectMatch(matchId),
                ),
                IconButton(
                  icon: Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onPressed: () => _acceptMatch(matchId, userId),
                ),
              ],
            )
          else
            IconButton(
              icon: Icon(
                Icons.message_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: () => _navigateToChat(match),
            ),
        ],
      ),
    );
  }
}
