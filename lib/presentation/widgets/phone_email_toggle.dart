import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

enum ContactMethod { email, phone }

class PhoneEmailToggle extends StatelessWidget {
  final ContactMethod selectedMethod;
  final ValueChanged<ContactMethod> onMethodChanged;
  final bool isDark;

  const PhoneEmailToggle({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.sp),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onMethodChanged(ContactMethod.email),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.sp),
                decoration: BoxDecoration(
                  color: selectedMethod == ContactMethod.email
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18.sp,
                      color: selectedMethod == ContactMethod.email
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'Email',
                      style: AppTextStyles.getSubtitle(isDark: isDark).copyWith(
                        color: selectedMethod == ContactMethod.email
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: selectedMethod == ContactMethod.email
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onMethodChanged(ContactMethod.phone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.sp),
                decoration: BoxDecoration(
                  color: selectedMethod == ContactMethod.phone
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.sp),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 18.sp,
                      color: selectedMethod == ContactMethod.phone
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'Phone',
                      style: AppTextStyles.getSubtitle(isDark: isDark).copyWith(
                        color: selectedMethod == ContactMethod.phone
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: selectedMethod == ContactMethod.phone
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
