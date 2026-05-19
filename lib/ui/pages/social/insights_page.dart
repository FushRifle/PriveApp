import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/services/socials/insights_service.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final InsightsService _insightsService = InsightsService();

  bool _isLoading = true;
  String? _error;

  // Insights data
  Map<String, dynamic> _insights = {};
  Map<String, dynamic> _realtimeStats = {};

  // Selected days filter
  int _selectedDays = 30;
  final List<int> _daysOptions = [7, 14, 30, 60, 90];

  // Chart tab selection
  int _selectedChartTab = 0; // 0: Views, 1: Engagement, 2: Reach

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final insights = await _insightsService.getInsights(days: _selectedDays);
      final realtimeStats = await _insightsService.getRealtimeStats();

      setState(() {
        _insights = insights;
        _realtimeStats = realtimeStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _changeDaysRange(int days) {
    setState(() {
      _selectedDays = days;
    });
    _loadData();
  }

  String _getFormattedValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is int || value is double) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      }
      return value.toString();
    }
    return value.toString();
  }

  String _getChangePercentage(dynamic current, dynamic previous) {
    if (current == null || previous == null || previous == 0) return '+0%';
    final change = ((current - previous) / previous * 100);
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  bool _isPositiveChange(dynamic current, dynamic previous) {
    if (current == null || previous == null) return true;
    return current >= previous;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Insights',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today_outlined),
            color: cardColor,
            onSelected: _changeDaysRange,
            itemBuilder: (context) => [
              for (int days in _daysOptions)
                PopupMenuItem<int>(
                  value: days,
                  child: Row(
                    children: [
                      Radio<int>(
                        value: days,
                        groupValue: _selectedDays,
                        onChanged: (_) => _changeDaysRange(days),
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last $days days',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: AppTheme.greyTextStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Real-time indicator
                          if (_realtimeStats.isNotEmpty)
                            _buildRealtimeIndicator(),

                          // Overview cards
                          _buildOverviewCards(),
                          const SizedBox(height: 24),

                          // Chart Section
                          _buildChartSection(cardColor, textColor, isDarkMode),
                          const SizedBox(height: 24),

                          // Engagement Rate
                          if (_insights['engagementRate'] != null)
                            _buildEngagementRateCard(cardColor, textColor),
                          const SizedBox(height: 24),

                          // Audience
                          if (_insights['demographics'] != null)
                            _buildDemographicsSection(cardColor, textColor),
                          const SizedBox(height: 24),

                          // Top Locations
                          if (_insights['topLocations'] != null)
                            _buildLocationsSection(cardColor, textColor),
                          const SizedBox(height: 24),

                          // Age Range
                          if (_insights['ageRanges'] != null)
                            _buildAgeRangeSection(cardColor, textColor),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildRealtimeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.greenColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live: ${_realtimeStats['onlineViewers'] ?? 0} viewers online',
            style: TextStyle(
              color: AppColors.blackTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'Total Views',
                value: _getFormattedValue(_insights['totalViews'], '0'),
                change: _getChangePercentage(
                  _insights['totalViews'],
                  _insights['previousTotalViews'],
                ),
                isPositive: _isPositiveChange(
                  _insights['totalViews'],
                  _insights['previousTotalViews'],
                ),
                icon: Icons.visibility,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                title: 'Engagement',
                value: _getFormattedValue(_insights['totalEngagement'], '0'),
                change: _getChangePercentage(
                  _insights['totalEngagement'],
                  _insights['previousTotalEngagement'],
                ),
                isPositive: _isPositiveChange(
                  _insights['totalEngagement'],
                  _insights['previousTotalEngagement'],
                ),
                icon: Icons.favorite,
                color: AppColors.redColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'New Followers',
                value: _getFormattedValue(_insights['newFollowers'], '0'),
                change: _getChangePercentage(
                  _insights['newFollowers'],
                  _insights['previousNewFollowers'],
                ),
                isPositive: _isPositiveChange(
                  _insights['newFollowers'],
                  _insights['previousNewFollowers'],
                ),
                icon: Icons.person_add,
                color: AppColors.greenColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                title: 'Reach',
                value: _getFormattedValue(_insights['totalReach'], '0'),
                change: _getChangePercentage(
                  _insights['totalReach'],
                  _insights['previousTotalReach'],
                ),
                isPositive: _isPositiveChange(
                  _insights['totalReach'],
                  _insights['previousTotalReach'],
                ),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(Color cardColor, Color textColor, bool isDarkMode) {
    final chartData =
        _insights['chartData'] as List? ?? _generateMockChartData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Chart tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildChartTab('Views', 0, isDarkMode),
                _buildChartTab('Engagement', 1, isDarkMode),
                _buildChartTab('Reach', 2, isDarkMode),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 220,
            child: LineChart(
              _buildChartData(chartData, textColor),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _getChartLabel(),
                style: TextStyle(
                  color: AppColors.greyColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(String label, int index, bool isDarkMode) {
    final isSelected = _selectedChartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChartTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<dynamic> data, Color textColor) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: data.isNotEmpty
            ? (data
                    .map((e) => e[_getChartDataKey()] as num)
                    .reduce((a, b) => a > b ? a : b) /
                4)
            : 100,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.greyColor.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index]['day']?.toString() ?? '',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatChartValue(value.toInt()),
                style: TextStyle(
                  color: AppColors.greyColor,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: data.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              (entry.value[_getChartDataKey()] as num).toDouble(),
            );
          }).toList(),
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  String _getChartDataKey() {
    switch (_selectedChartTab) {
      case 0:
        return 'views';
      case 1:
        return 'engagement';
      case 2:
        return 'reach';
      default:
        return 'views';
    }
  }

  String _getChartLabel() {
    switch (_selectedChartTab) {
      case 0:
        return 'Daily Views';
      case 1:
        return 'Daily Engagement';
      case 2:
        return 'Daily Reach';
      default:
        return 'Daily Views';
    }
  }

  String _formatChartValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }

  List<Map<String, dynamic>> _generateMockChartData() {
    final List<Map<String, dynamic>> data = [];
    for (int i = 0; i < 7; i++) {
      data.add({
        'day': 'Day ${i + 1}',
        'views': 1000 + (i * 200) + (i * 50),
        'engagement': 100 + (i * 30),
        'reach': 800 + (i * 150),
      });
    }
    return data;
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositive ? AppColors.greenColor : AppColors.redColor,
              ),
              const SizedBox(width: 2),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? AppColors.greenColor : AppColors.redColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRateCard(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Rate',
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(_insights['engagementRate'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'vs ${(_insights['previousEngagementRate'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                  style: TextStyle(
                    color: AppColors.greyColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value:
                ((_insights['engagementRate'] as num?)?.toDouble() ?? 0) / 100,
            backgroundColor: AppColors.greyColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection(Color cardColor, Color textColor) {
    final demographics =
        _insights['demographics'] as Map<String, dynamic>? ?? {};
    final total = (demographics['male'] ?? 0) +
        (demographics['female'] ?? 0) +
        (demographics['other'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audience',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAudienceRow(
                'Male',
                '${total > 0 ? ((demographics['male'] ?? 0) / total * 100).toStringAsFixed(0) : '0'}%',
                (demographics['male'] ?? 0) / total,
              ),
              const SizedBox(height: 16),
              _buildAudienceRow(
                'Female',
                '${total > 0 ? ((demographics['female'] ?? 0) / total * 100).toStringAsFixed(0) : '0'}%',
                (demographics['female'] ?? 0) / total,
              ),
              const SizedBox(height: 16),
              _buildAudienceRow(
                'Other',
                '${total > 0 ? ((demographics['other'] ?? 0) / total * 100).toStringAsFixed(0) : '0'}%',
                (demographics['other'] ?? 0) / total,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceRow(String label, String percentage, double progress) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.isFinite ? progress : 0,
            backgroundColor: AppColors.greyColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsSection(Color cardColor, Color textColor) {
    final locations = _insights['topLocations'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Locations',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < locations.length; i++)
                Column(
                  children: [
                    _buildLocationRow(
                      locations[i]['location'] ?? 'Unknown',
                      locations[i]['percentage']?.toString() ?? '0%',
                    ),
                    if (i < locations.length - 1) const Divider(),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String location, String percentage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 16, color: AppColors.redColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeSection(Color cardColor, Color textColor) {
    final ageRanges = _insights['ageRanges'] as List? ?? [];
    final total = ageRanges.fold<int>(
      0,
      (sum, item) => sum + (item['count'] as int? ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Range',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < ageRanges.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: i < ageRanges.length - 1 ? 12 : 0),
                  child: _buildAgeRow(
                    ageRanges[i]['range'] ?? 'Unknown',
                    '${total > 0 ? ((ageRanges[i]['count'] ?? 0) / total * 100).toStringAsFixed(0) : '0'}%',
                    (ageRanges[i]['count'] ?? 0) / total,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRow(String range, String percentage, double progress) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            range,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.isFinite ? progress : 0,
              backgroundColor: AppColors.greyColor.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            percentage,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
