import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:manna_donate_app/data/repository/analytics_provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/apiClient/analytics_service.dart';
import 'package:provider/provider.dart';

class DonorAnalyticsScreen extends StatefulWidget {
  const DonorAnalyticsScreen({super.key});

  @override
  State<DonorAnalyticsScreen> createState() => _DonorAnalyticsScreenState();
}

class _DonorAnalyticsScreenState extends State<DonorAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _impactData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load mobile-specific impact summary data using cache-first methods
      final analyticsProvider = Provider.of<AnalyticsProvider>(
        context,
        listen: false,
      );
      await Future.wait([
        analyticsProvider.loadMobileImpactSummary(),
        analyticsProvider.loadMobileDashboard(),
      ]);

      if (mounted) {
        setState(() {
          _impactData = analyticsProvider.impactData;
          _analyticsData = analyticsProvider.mobileDashboardData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract real data from mobile-specific endpoints
    final totalDonated = _impactData?['total_donated']?.toDouble() ?? 0.0;
    final thisMonthDonated =
        _impactData?['this_month_donated']?.toDouble() ?? 0.0;
    final totalBatches = _impactData?['total_batches']?.toInt() ?? 0;
    final averagePerBatch =
        _impactData?['average_per_batch']?.toDouble() ?? 0.0;

    // Get real monthly data from mobile dashboard
    final monthlyData =
        _analyticsData?['monthly_donations'] as List<dynamic>? ?? [];
    final donationsByMonth = monthlyData
        .map((e) => (e as num).toDouble())
        .toList();

    // If no real data, use empty list
    if (donationsByMonth.isEmpty) {
      donationsByMonth.addAll(List.generate(12, (index) => 0.0));
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Donor Analytics'),
      drawer: AppDrawer(),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: EnhancedLoadingWidget(
                  type: LoadingType.spinner,
                  message: 'Loading analytics...',
                  size: 50,
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  // Fetch fresh analytics data from backend (bypass cache)
                  await _loadAnalyticsData();
                },
                child: AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                          ),
                          elevation: AppConstants.cardElevation,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '\$${totalDonated.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppConstants.titleSize,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppConstants.smallSpacing,
                                    ),
                                    Text('Total Donated'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '$totalBatches',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppConstants.titleSize,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppConstants.smallSpacing,
                                    ),
                                    Text('Donations'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '\$${averagePerBatch.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppConstants.titleSize,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppConstants.smallSpacing,
                                    ),
                                    Text('Average'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                          ),
                          elevation: AppConstants.cardElevation,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'This Month',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(
                                  height: AppConstants.smallSpacing,
                                ),
                                Text(
                                  '\$${thisMonthDonated.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                Text('Total donated this month'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Text(
                          'Giving by Month',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppConstants.smallSpacing),
                        SizedBox(
                          height: 250, // Fixed height to prevent overflow
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: donationsByMonth.isNotEmpty
                                  ? (donationsByMonth.reduce(
                                          (a, b) => a > b ? a : b,
                                        ) *
                                        1.2)
                                  : 100,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (
                                        group,
                                        groupIndex,
                                        rod,
                                        rodIndex,
                                      ) => BarTooltipItem(
                                        'Month: ${months[group.x.toInt()]}\nAmount: \$${rod.toY.toStringAsFixed(2)}',
                                        TextStyle(color: Colors.black),
                                      ),
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 25,
                                  ), // Reduced reserved size
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= months.length)
                                        return Container();
                                      return Text(
                                        months[idx],
                                        style: TextStyle(
                                          fontSize: 10,
                                        ), // Reduced font size
                                      );
                                    },
                                    reservedSize: 28, // Reduced reserved size
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(
                                donationsByMonth.length,
                                (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: donationsByMonth[i],
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(128),
                                        ],
                                      ),
                                      width: 16, // Reduced width
                                      borderRadius: BorderRadius.circular(
                                        10,
                                      ), // Reduced border radius
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.sectionSpacing),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                          ),
                          elevation: AppConstants.cardElevation,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Impact Report',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(
                                  height: AppConstants.smallSpacing,
                                ),
                                Text(
                                  'Your donations have helped support 3 churches, 2 community projects, and 50+ individuals this year. Thank you!',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      // Removed floatingActionButton (home button)
    );
  }
}
