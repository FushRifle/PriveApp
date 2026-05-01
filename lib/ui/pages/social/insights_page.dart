import 'package:flutter/material.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Insights',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.calendar_today_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview cards
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      title: 'Total Views',
                      value: '45.2K',
                      change: '+12.5%',
                      isPositive: true,
                      icon: Icons.visibility,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      title: 'Engagement',
                      value: '8.1K',
                      change: '+5.2%',
                      isPositive: true,
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
                      title: 'Followers',
                      value: '3.4K',
                      change: '+18.3%',
                      isPositive: true,
                      icon: Icons.person_add,
                      color: AppColors.greenColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      title: 'Reach',
                      value: '28.9K',
                      change: '+8.7%',
                      isPositive: true,
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Audience
              Text(
                'Audience',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildAudienceRow('Male', '55%', 0.55),
                    const SizedBox(height: 16),
                    _buildAudienceRow('Female', '42%', 0.42),
                    const SizedBox(height: 16),
                    _buildAudienceRow('Other', '3%', 0.03),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Locations
              Text(
                'Top Locations',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildLocationRow('New York, USA', '28%'),
                    const Divider(),
                    _buildLocationRow('Los Angeles, USA', '22%'),
                    const Divider(),
                    _buildLocationRow('London, UK', '15%'),
                    const Divider(),
                    _buildLocationRow('Tokyo, Japan', '10%'),
                    const Divider(),
                    _buildLocationRow('Mumbai, India', '8%'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Age Range
              Text(
                'Age Range',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildAgeRow('18-24', '35%', 0.35),
                    const SizedBox(height: 12),
                    _buildAgeRow('25-34', '40%', 0.40),
                    const SizedBox(height: 12),
                    _buildAgeRow('35-44', '15%', 0.15),
                    const SizedBox(height: 12),
                    _buildAgeRow('45-54', '7%', 0.07),
                    const SizedBox(height: 12),
                    _buildAgeRow('55+', '3%', 0.03),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content Performance
              Text(
                'Top Performing Content',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Container(
                                color: AppColors.purpleColor.withOpacity(0.1),
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color:
                                        AppColors.purpleColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Post ${index + 1}',
                                  style: AppTheme.blackTextStyle.copyWith(
                                    fontWeight: AppTheme.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.favorite,
                                        size: 12, color: AppColors.redColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${12 - index}.${index}K',
                                      style: AppTheme.greyTextStyle
                                          .copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              fontWeight: AppTheme.bold,
              fontSize: 22,
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
            style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceRow(String label, String percentage, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.blackTextStyle.copyWith(
                fontWeight: AppTheme.medium,
                fontSize: 14,
              ),
            ),
            Text(
              percentage,
              style: AppTheme.blackTextStyle.copyWith(
                fontWeight: AppTheme.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.greyColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.purpleColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String location, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: AppColors.redColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location,
              style: AppTheme.blackTextStyle.copyWith(fontSize: 14),
            ),
          ),
          Text(
            percentage,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRow(String range, String percentage, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            range,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.medium,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.greyColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purpleColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            percentage,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
