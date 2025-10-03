import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final VoidCallback? onTap;

  const AnalyticsSummaryCard({
    super.key,
    required this.analytics,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(16.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.sp),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.sp),
                    Text(
                      'Analytics Summary',
                      style: AppTextStyles.getTitle(isDark: isDark),
                    ),
                  ],
                ),
                SizedBox(height: 16.sp),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Donations',
                        '\$${(analytics['totalDonations'] ?? 0.0).toStringAsFixed(2)}',
                        Icons.attach_money,
                        isDark,
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: _buildStatItem(
                        'This Month',
                        '\$${(analytics['monthlyDonations'] ?? 0.0).toStringAsFixed(2)}',
                        Icons.calendar_today,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 16.sp,
            ),
            SizedBox(width: 8.sp),
            Text(
              title,
              style: AppTextStyles.getCaption(isDark: isDark),
            ),
          ],
        ),
        SizedBox(height: 8.sp),
        Text(
          value,
          style: AppTextStyles.getTitle(isDark: isDark).copyWith(
            color: AppColors.primary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 