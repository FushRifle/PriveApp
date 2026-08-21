import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _refreshInsights(int days) async {
    final bloc = context.read<InsightsBloc>()
      ..add(RefreshInsights(days: days))
      ..add(RefreshRealtimeStats());
    await bloc.stream.firstWhere(
      (state) =>
          state.status == InsightsStatus.success ||
          state.status == InsightsStatus.error,
    );
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
                  return _buildLoadingWidget();
                }

                if (state.status == InsightsStatus.error &&
                    state.insights == null) {
                  return _buildErrorWidget();
                }

                return RefreshIndicator(
                  onRefresh: () => _refreshInsights(state.currentPeriodDays),
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.status == InsightsStatus.refreshing)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: LinearProgressIndicator(
                                  color: AppColors.primary,
                                  minHeight: 2,
                                ),
                              ),
                            _buildPerformanceHero(state),
                            const SizedBox(height: 14),
                            _buildPeriodSelector(state),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              'Overview',
                              'A snapshot of your account performance',
                            ),
                            const SizedBox(height: 12),
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
                          ],
                        ),
                      ),
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
    return AppPageHeader(
      title: 'Insights',
      subtitle: 'Your performance and audience',
      leadingIcon: Icons.arrow_back_ios_new,
      onLeadingTap: () => Navigator.pop(context),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.query_stats_rounded,
                size: 34,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Insights are unavailable',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'We couldn’t load your performance data. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadData,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Container(
          height: 188,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: List.generate(
            2,
            (_) => Expanded(
              child: Container(
                height: 142,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            2,
            (_) => Expanded(
              child: Container(
                height: 142,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceHero(InsightsState state) {
    final viewers = state.realtimeStats?.onlineViewers ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Last ${state.currentPeriodDays} days',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Performance dashboard',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'See how people discover and interact with your content.',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.78),
              fontSize: 13,
            ),
          ),
          if (state.realtimeStats != null) ...[
            const SizedBox(height: 18),
            Row(
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
                  '$viewers ${viewers == 1 ? 'viewer' : 'viewers'} online now',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(InsightsState state) {
    const periods = [(7, '7D'), (30, '30D'), (90, '90D')];

    return Row(
      children: [
        Expanded(
          child: Text(
            'Reporting period',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((period) {
              final selected = state.currentPeriodDays == period.$1;
              return Semantics(
                button: true,
                selected: selected,
                label: '${period.$1} days',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: selected || state.status == InsightsStatus.refreshing
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          context.read<InsightsBloc>().add(
                                RefreshInsights(days: period.$1),
                              );
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primary : AppColors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      period.$2,
                      style: TextStyle(
                        color: selected
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(InsightsState state) {
    final insights = state.insights;
    if (insights == null) return const SizedBox.shrink();

    final cards = [
      _buildInsightCard(
        title: 'Total Views',
        value: _formatValue(insights.totalViews),
        change: insights.totalViewsChange,
        isPositive: insights.totalViewsChange >= 0,
        icon: Icons.visibility,
        color: AppColors.blue,
      ),
      _buildInsightCard(
        title: 'Engagement',
        value: _formatValue(insights.totalEngagement),
        change: insights.totalEngagementChange,
        isPositive: insights.totalEngagementChange >= 0,
        icon: Icons.favorite,
        color: AppColors.redColor,
      ),
      _buildInsightCard(
        title: 'New Followers',
        value: _formatValue(insights.newFollowers),
        change: insights.newFollowersChange,
        isPositive: insights.newFollowersChange >= 0,
        icon: Icons.person_add,
        color: AppColors.greenColor,
      ),
      _buildInsightCard(
        title: 'Reach',
        value: _formatValue(insights.totalReach),
        change: insights.totalReachChange,
        isPositive: insights.totalReachChange >= 0,
        icon: Icons.trending_up,
        color: AppColors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isPositive ? AppColors.greenColor : AppColors.redColor)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: isPositive
                          ? AppColors.greenColor
                          : AppColors.redColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.greenColor
                            : AppColors.redColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(InsightsState state) {
    final insights = state.insights;
    if (insights?.chartData == null) return const SizedBox.shrink();
    final selectedData = _getSelectedChartData(insights!.chartData);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.11),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Daily activity across your content',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChartTabs(),
          const SizedBox(height: 20),
          if (selectedData.isEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: AppColors.textHint,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No ${_getChartLabel().toLowerCase()} yet',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(_buildChartData(insights.chartData)),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.13),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engagement rate',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Previous ${insights.previousEngagementRate.toStringAsFixed(1)}%',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${insights.engagementRate.toStringAsFixed(1)}%',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: (insights.engagementRate / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.greyColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
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
        _buildSectionTitle(
          'Audience',
          'Who is interacting with your content',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
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
        _buildSectionTitle(
          'Top locations',
          'Where your audience is based',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
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
        _buildSectionTitle(
          'Age range',
          'The age distribution of your audience',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
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
