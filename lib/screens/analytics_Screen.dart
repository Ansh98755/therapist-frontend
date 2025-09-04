import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Hardcoded analytics data
  Map<String, dynamic> analyticsData = {
    'bookingsToday': 12,
    'bookingsThisMonth': 287,
    'cancellationsThisMonth': 23,
    'earningsThisMonth': 125000.0,
    'lastMonthBookings': 245,
    'lastMonthEarnings': 98000.0,
    'weeklyBookings': [15, 18, 22, 19, 25, 20, 12], // Last 7 days
    'monthlyData': [
      {'month': 'Jan', 'bookings': 185, 'earnings': 75000},
      {'month': 'Feb', 'bookings': 210, 'earnings': 85000},
      {'month': 'Mar', 'bookings': 245, 'earnings': 98000},
      {'month': 'Apr', 'bookings': 268, 'earnings': 110000},
      {'month': 'May', 'bookings': 287, 'earnings': 125000},
      {'month': 'Jun', 'bookings': 295, 'earnings': 132000},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.colorF5F5F5,
      appBar: AppBar(
        backgroundColor: ColorConstants.boxShadowOrangeOpacity,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Analytics',
          style: TextStyle(
            color: ColorConstants.blackColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ColorConstants.blackColor),
            onPressed: () {
              // Show a simple message when refresh is tapped
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Analytics refreshed!'),
                  backgroundColor: ColorConstants.primaryBrownColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Show a simple message when refreshed
          await Future.delayed(Duration(milliseconds: 500));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analytics refreshed!'),
              backgroundColor: ColorConstants.primaryBrownColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        color: ColorConstants.primaryBrownColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Stats
              _buildMainStats(),
              const SizedBox(height: 24),

              // Quick Summary
              _buildQuickSummary(),
              const SizedBox(height: 24),

              // Simple Monthly Chart
              _buildSimpleChart(),
              const SizedBox(height: 24),

              // Success Rate
              _buildSuccessRate(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Today\'s Bookings',
                value: '${analyticsData['bookingsToday']}',
                icon: Icons.today,
                color: ColorConstants.primaryOrangeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'This Month',
                value: '${analyticsData['bookingsThisMonth']}',
                icon: Icons.calendar_month,
                color: ColorConstants.themeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Monthly Earnings',
                value:
                    '₹${(analyticsData['earningsThisMonth'] / 1000).toInt()}k',
                icon: Icons.account_balance_wallet,
                color: ColorConstants.color7FB3B3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Cancellations',
                value: '${analyticsData['cancellationsThisMonth']}',
                icon: Icons.cancel_outlined,
                color: ColorConstants.redColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: ColorConstants.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    int bookingIncrease =
        analyticsData['bookingsThisMonth'] - analyticsData['lastMonthBookings'];
    double earningIncrease =
        analyticsData['earningsThisMonth'] - analyticsData['lastMonthEarnings'];
    double successRate =
        ((analyticsData['bookingsThisMonth'] -
            analyticsData['cancellationsThisMonth']) /
        analyticsData['bookingsThisMonth'] *
        100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.boxShadowBrownOpacity,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            'Bookings Growth',
            '+$bookingIncrease from last month',
            bookingIncrease > 0 ? Icons.trending_up : Icons.trending_down,
            bookingIncrease > 0
                ? ColorConstants.primaryOrangeColor
                : ColorConstants.redColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Earnings Growth',
            '${earningIncrease > 0 ? '+' : ''}₹${earningIncrease.toInt()}',
            earningIncrease > 0 ? Icons.trending_up : Icons.trending_down,
            earningIncrease > 0
                ? ColorConstants.primaryOrangeColor
                : ColorConstants.redColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Success Rate',
            '${successRate.toInt()}%',
            Icons.check_circle_outline,
            ColorConstants.color7FB3B3,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primaryBrownColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: ColorConstants.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.boxShadowBrownOpacity,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 400,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            months[value.toInt()],
                            style: TextStyle(
                              color: ColorConstants.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 100,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: ColorConstants.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  analyticsData['monthlyData'].length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: analyticsData['monthlyData'][index]['bookings']
                            .toDouble(),
                        color: ColorConstants.primaryOrangeColor,
                        width: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRate() {
    double totalBookings = analyticsData['bookingsThisMonth'].toDouble();
    double cancellations = analyticsData['cancellationsThisMonth'].toDouble();
    double successful = totalBookings - cancellations;
    double successPercentage = (successful / totalBookings) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.boxShadowBrownOpacity,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Success Rate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${successPercentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryOrangeColor,
                      ),
                    ),
                    Text(
                      'Success Rate',
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorConstants.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildSuccessItem(
                      'Successful',
                      successful.toInt().toString(),
                      ColorConstants.primaryOrangeColor,
                    ),
                    const SizedBox(height: 16),
                    _buildSuccessItem(
                      'Cancelled',
                      cancellations.toInt().toString(),
                      ColorConstants.redColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryBrownColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: ColorConstants.grey),
            ),
          ],
        ),
      ],
    );
  }
}
