import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
    with SingleTickerProviderStateMixin {
  final List<int> _daysOptions = [7, 14, 30, 60, 90];
  int _selectedChartTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<InsightsBloc>().add(LoadInsights(days: 30));
    context.read<InsightsBloc>().add(LoadRealtimeStats());
  }

  String _formatValue(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  String _formatChartValue(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: BlocConsumer<InsightsBloc, InsightsState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: AppColors.card,
                    ),
                  );
                  context.read<InsightsBloc>().add(ClearInsightsError());
                }
              },
              builder: (context, state) {
                if (state.status == InsightsStatus.loading &&
                    state.insights == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state.status == InsightsStatus.error &&
                    state.insights == null) {
                  return _buildErrorWidget();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<InsightsBloc>().add(
                          RefreshInsights(days: state.currentPeriodDays),
                        );
                    context.read<InsightsBloc>().add(RefreshRealtimeStats());
                  },
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.realtimeStats != null)
                          _buildRealtimeIndicator(state),
                        _buildOverviewCards(state),
                        const SizedBox(height: 24),
                        _buildChartSection(state),
                        const SizedBox(height: 24),
                        if (state.insights != null) ...[
                          _buildEngagementRateCard(state),
                          const SizedBox(height: 24),
                          _buildDemographicsSection(state),
                          const SizedBox(height: 24),
                          _buildLocationsSection(state),
                          const SizedBox(height: 24),
                          _buildAgeRangeSection(state),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, state) {
        return AppPageHeader(
          title: 'Insights',
          subtitle: 'Last ${state.currentPeriodDays} days',
          leadingIcon: Icons.arrow_back_ios_new,
          onLeadingTap: () => Navigator.pop(context),
          action: PopupMenuButton<int>(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: AppColors.text,
            ),
            color: AppColors.cardColor,
            onSelected: (days) {
              context
                  .read<InsightsBloc>()
                  .add(ChangeInsightsPeriod(days: days));
            },
            itemBuilder: (context) => [
              for (int days in _daysOptions)
                PopupMenuItem<int>(
                  value: days,
                  child: Row(
                    children: [
                      Radio<int>(
                        value: days,
                        groupValue: state.currentPeriodDays,
                        onChanged: (_) {
                          context
                              .read<InsightsBloc>()
                              .add(ChangeInsightsPeriod(days: days));
                          Navigator.pop(context);
                        },
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('Last $days days'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.greyColor),
          const SizedBox(height: 16),
          Text('Failed to load insights', style: AppTheme.greyTextStyle),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeIndicator(InsightsState state) {
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.githubGreen,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live: ${state.realtimeStats?.onlineViewers ?? 0} viewers online',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(InsightsState state) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'Total Views',
                value: _formatValue(insights.totalViews),
                change: insights.totalViewsChange,
                isPositive: insights.totalViewsChange >= 0,
                icon: Icons.visibility,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                title: 'Engagement',
                value: _formatValue(insights.totalEngagement),
                change: insights.totalEngagementChange,
                isPositive: insights.totalEngagementChange >= 0,
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
                value: _formatValue(insights.newFollowers),
                change: insights.newFollowersChange,
                isPositive: insights.newFollowersChange >= 0,
                icon: Icons.person_add,
                color: AppColors.greenColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                title: 'Reach',
                value: _formatValue(insights.totalReach),
                change: insights.totalReachChange,
                isPositive: insights.totalReachChange >= 0,
                icon: Icons.trending_up,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required double change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
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
            style: AppTheme.blackTextStyle.copyWith(
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
                '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? AppColors.greenColor : AppColors.redColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTheme.greyTextStyle.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChartSection(InsightsState state) {
    final insights = state.insights;
    if (insights?.chartData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
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
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartTabs(),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(_buildChartData(insights!.chartData)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getChartLabel(),
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTabs() {
    final tabs = ['Views', 'Engagement', 'Reach'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedChartTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  LineChartData _buildChartData(Map<String, List<ChartDataPoint>> chartData) {
    final dataPoints = _getSelectedChartData(chartData);
    if (dataPoints.isEmpty) return _getEmptyChartData();

    final rawMaxValue =
        dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxValue = rawMaxValue <= 0 ? 1.0 : rawMaxValue;
    final horizontalInterval = (maxValue / 4).clamp(1.0, double.infinity);

    return LineChartData(
      minX: 0,
      maxX: (dataPoints.length - 1).clamp(1, dataPoints.length).toDouble(),
      minY: 0,
      maxY: maxValue == 1.0 ? 1.0 : maxValue * 1.15,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: horizontalInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.greyColor.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < dataPoints.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dataPoints[index].label,
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 10),
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
            getTitlesWidget: (value, meta) => Text(
              _formatChartValue(value.toInt()),
              style: AppTheme.greyTextStyle.copyWith(fontSize: 10),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: dataPoints
              .asMap()
              .entries
              .map((e) => FlSpot(
                    e.key.toDouble(),
                    e.value.value < 0 ? 0 : e.value.value,
                  ))
              .toList(),
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 4,
              color: AppColors.primary,
              strokeWidth: 2,
              strokeColor: AppColors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  LineChartData _getEmptyChartData() {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [],
    );
  }

  List<ChartDataPoint> _getSelectedChartData(
      Map<String, List<ChartDataPoint>> chartData) {
    switch (_selectedChartTab) {
      case 0:
        return chartData['views'] ?? [];
      case 1:
        return chartData['engagement'] ?? [];
      case 2:
        return chartData['reach'] ?? [];
      default:
        return chartData['views'] ?? [];
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

  Widget _buildEngagementRateCard(InsightsState state) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engagement Rate',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${insights.engagementRate.toStringAsFixed(1)}%',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'vs ${insights.previousEngagementRate.toStringAsFixed(1)}%',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: insights.engagementRate / 100,
            backgroundColor: AppColors.greyColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection(InsightsState state) {
    final demographics = state.insights?.demographics;
    if (demographics == null) return const SizedBox.shrink();

    final total = demographics.male + demographics.female + demographics.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audience',
            style: AppTheme.blackTextStyle
                .copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildProgressRow('Male', demographics.male, total),
              const SizedBox(height: 16),
              _buildProgressRow('Female', demographics.female, total),
              const SizedBox(height: 16),
              _buildProgressRow('Other', demographics.other, total),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, int value, int total) {
    final percentage = total > 0 ? (value / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTheme.blackTextStyle
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
            Text('${(percentage * 100).toStringAsFixed(0)}%',
                style: AppTheme.blackTextStyle
                    .copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppColors.greyColor.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildLocationsSection(InsightsState state) {
    final locations = state.insights?.topLocations ?? [];
    if (locations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Locations',
            style: AppTheme.blackTextStyle
                .copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
                locations.length,
                (i) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: AppColors.redColor),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(locations[i].location,
                                      style: AppTheme.blackTextStyle
                                          .copyWith(fontSize: 14))),
                              Text(
                                  '${locations[i].percentage.toStringAsFixed(0)}%',
                                  style: AppTheme.blackTextStyle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (i < locations.length - 1) const Divider(),
                      ],
                    )),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRangeSection(InsightsState state) {
    final ageRanges = state.insights?.ageRanges ?? [];
    if (ageRanges.isEmpty) return const SizedBox.shrink();

    final total = ageRanges.fold(0, (sum, item) => sum + item.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Age Range',
            style: AppTheme.blackTextStyle
                .copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
                ageRanges.length,
                (i) => Padding(
                      padding: EdgeInsets.only(
                          bottom: i < ageRanges.length - 1 ? 12 : 0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(ageRanges[i].range,
                                style: AppTheme.blackTextStyle.copyWith(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: total > 0 ? ageRanges[i].count / total : 0,
                              backgroundColor:
                                  AppColors.greyColor.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 35,
                            child: Text(
                              '${total > 0 ? ((ageRanges[i].count / total) * 100).toStringAsFixed(0) : 0}%',
                              style: AppTheme.blackTextStyle.copyWith(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )),
          ),
        ),
      ],
    );
  }
}
