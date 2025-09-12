import 'package:flutter/material.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic> analyticsData = {
    'bookingCount': 287,
    'totalIncomeBeforeShare': 150000.0,
    'companyShareHaveToPay': 25000.0,
    'finalIncome': 125000.0,
    'totalCancellation': 23,
    'weeklyTotals': [
      {'day': 'Mon', 'total': 18000},
      {'day': 'Tue', 'total': 22000},
      {'day': 'Wed', 'total': 15000},
      {'day': 'Thu', 'total': 25000},
      {'day': 'Fri', 'total': 30000},
      {'day': 'Sat', 'total': 20000},
      {'day': 'Sun', 'total': 12000},
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
              // Main Stats Cards
              _buildMainStats(),
              const SizedBox(height: 24),

              // Income Breakdown
              _buildIncomeBreakdown(),
              const SizedBox(height: 24),

              // Weekly Total Calculations Chart
              _buildWeeklyChart(),
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
                title: 'Total Bookings',
                value: '${analyticsData['bookingCount']}',
                icon: Icons.calendar_today,
                color: ColorConstants.primaryOrangeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Final Income',
                value: '₹${(analyticsData['finalIncome'] / 1000).toInt()}k',
                icon: Icons.account_balance_wallet,
                color: ColorConstants.color7FB3B3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Cancellations',
                value: '${analyticsData['totalCancellation']}',
                icon: Icons.cancel_outlined,
                color: ColorConstants.redColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Company Share',
                value: '₹${(analyticsData['companyShareHaveToPay'] / 1000).toInt()}k',
                icon: Icons.business,
                color: ColorConstants.themeColor,
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

  Widget _buildIncomeBreakdown() {
    double successRate = ((analyticsData['bookingCount'] - analyticsData['totalCancellation']) / analyticsData['bookingCount'] * 100);

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
            'Income Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            'Total Income (Before Share)',
            '₹${analyticsData['totalIncomeBeforeShare'].toInt()}',
            Icons.trending_up,
            ColorConstants.primaryOrangeColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Company Share to Pay',
            '₹${analyticsData['companyShareHaveToPay'].toInt()}',
            Icons.remove_circle_outline,
            ColorConstants.redColor,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Final Income',
            '₹${analyticsData['finalIncome'].toInt()}',
            Icons.check_circle_outline,
            ColorConstants.color7FB3B3,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Success Rate',
            '${successRate.toInt()}%',
            Icons.analytics,
            ColorConstants.themeColor,
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
                style: TextStyle(
                  fontSize: 14, 
                  color: ColorConstants.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
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
            'Weekly Total Calculations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConstants.primaryBrownColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last 7 days earnings overview',
            style: TextStyle(
              fontSize: 14,
              color: ColorConstants.grey,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}