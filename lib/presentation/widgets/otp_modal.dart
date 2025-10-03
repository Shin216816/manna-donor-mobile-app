import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'submit_button.dart';

class OTPModal extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool loading;

  const OTPModal({
    Key? key,
    required this.controller,
    required this.onVerify,
    required this.onResend,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Enter OTP', style: AppTextStyles.title),
            const SizedBox(height: 24),
            ModernInputField(
              controller: controller,
              label: '',
              hint: '------',
              keyboardType: TextInputType.text,
              maxLength: 6,
              textAlign: TextAlign.center,
              isRequired: true,
              isDark: false, // OTP modal typically uses light theme
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40.sp,
                    child: OutlinedButton(
                      onPressed: loading ? null : onResend,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Resend'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 7,
                  child: SubmitButton(
                    text: 'Verify',
                    onPressed: onVerify,
                    loading: loading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
