import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';

class VerificationDialog extends StatefulWidget {
  final String type; // 'email' or 'phone'
  final String contact; // email address or phone number
  final VoidCallback? onSuccess;

  const VerificationDialog({
    super.key,
    required this.type,
    required this.contact,
    this.onSuccess,
  });

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isCodeSent = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400.sp),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(24.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Professional Header
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.sp),
                  topRight: Radius.circular(24.sp),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                    child: Icon(
                      widget.type == 'email' ? Icons.email_outlined : Icons.phone_outlined,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify ${widget.type == 'email' ? 'Email' : 'Phone'}',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 20.sp,
                            color: AppColors.getOnSurfaceColor(isDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          'Secure your account',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: EdgeInsets.all(8.sp),
                      decoration: BoxDecoration(
                        color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
                        size: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(24.sp),
              child: Column(
                children: [
                  // Contact Info
                  Container(
                    padding: EdgeInsets.all(16.sp),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(isDark),
                      borderRadius: BorderRadius.circular(12.sp),
                      border: Border.all(
                        color: AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.type == 'email' ? Icons.email : Icons.phone,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verification will be sent to:',
                                style: TextStyle(
                                  color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 2.sp),
                              Text(
                                widget.contact,
                                style: TextStyle(
                                  color: AppColors.getOnSurfaceColor(isDark),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.sp),
                  
                  // Code Input Section
                  if (_isCodeSent) ...[
                    Text(
                      'Enter the 6-digit verification code',
                      style: TextStyle(
                        color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    ModernInputField(
                      controller: _codeController,
                      label: 'Verification Code',
                      hint: '000000',
                      prefixIcon: Icons.security,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      isRequired: true,
                      autovalidateMode: true,
                      isDark: isDark,
                    ),
                    SizedBox(height: 24.sp),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: 'Verify Code',
                            onPressed: _isLoading ? null : _verifyCode,
                            isLoading: _isLoading,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: ModernButton(
                            text: 'Resend',
                            onPressed: _isSendingCode ? null : _sendCode,
                            variant: ButtonVariant.outlined,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Initial State
                    Container(
                      padding: EdgeInsets.all(20.sp),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12.sp),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.security,
                            color: AppColors.primary,
                            size: 32.sp,
                          ),
                          SizedBox(height: 12.sp),
                          Text(
                            'Secure Verification',
                            style: TextStyle(
                              color: AppColors.getOnSurfaceColor(isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 8.sp),
                          Text(
                            'We\'ll send a verification code to your ${widget.type == 'email' ? 'email' : 'phone'} to confirm your identity.',
                            style: TextStyle(
                              color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.sp),
                    
                    // Send Code Button
                    ModernButton(
                      text: 'Send Verification Code',
                      onPressed: _isSendingCode ? null : _sendCode,
                      isLoading: _isSendingCode,
                      fullWidth: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSendingCode = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (widget.type == 'email') {
      success = await authProvider.sendEmailVerification();
    } else {
      success = await authProvider.sendPhoneVerification();
    }

    if (mounted) {
      setState(() {
        _isSendingCode = false;
        if (success) {
          _isCodeSent = true;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to send verification code'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (widget.type == 'email') {
      success = await authProvider.confirmEmailVerification(_codeController.text.trim());
    } else {
      success = await authProvider.confirmPhoneVerification(_codeController.text.trim());
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Refresh user profile to get updated verification status
        await authProvider.refreshProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.type == 'email' ? 'Email' : 'Phone'} verified successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to verify code'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
