import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

class RecentActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final VoidCallback? onViewAll;

  const RecentActivityCard({
    super.key,
    required this.activities,
    this.onViewAll,
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
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: AppTextStyles.getTitle(isDark: isDark),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'View All',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.sp),
            if (activities.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32.sp),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 48.sp,
                      ),
                      SizedBox(height: 16.sp),
                      Text(
                        'No recent activity',
                        style: AppTextStyles.getBody(isDark: isDark).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: activities.take(3).map((activity) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.sp),
                    child: Row(
                      children: [
                        Container(
                          width: 40.sp,
                          height: 40.sp,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title'] ?? 'Donation',
                                style: AppTextStyles.getBody(isDark: isDark),
                              ),
                              Text(
                                activity['subtitle'] ?? '',
                                style: AppTextStyles.getCaption(isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          activity['amount'] ?? '\$0.00',
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
} 