import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? initialCountryCode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool isDark;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.initialCountryCode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    required this.isDark,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountryCode = '+1'; // Default to US
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+91', 'country': 'IN', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'CN', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'JP', 'flag': '🇯🇵'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'FR', 'flag': '🇫🇷'},
    {'code': '+39', 'country': 'IT', 'flag': '🇮🇹'},
    {'code': '+34', 'country': 'ES', 'flag': '🇪🇸'},
    {'code': '+61', 'country': 'AU', 'flag': '🇦🇺'},
    {'code': '+52', 'country': 'MX', 'flag': '🇲🇽'},
    {'code': '+55', 'country': 'BR', 'flag': '🇧🇷'},
    {'code': '+7', 'country': 'RU', 'flag': '🇷🇺'},
    {'code': '+82', 'country': 'KR', 'flag': '🇰🇷'},
    {'code': '+65', 'country': 'SG', 'flag': '🇸🇬'},
    {'code': '+971', 'country': 'AE', 'flag': '🇦🇪'},
    {'code': '+966', 'country': 'SA', 'flag': '🇸🇦'},
    {'code': '+27', 'country': 'ZA', 'flag': '🇿🇦'},
    {'code': '+234', 'country': 'NG', 'flag': '🇳🇬'},
    {'code': '+254', 'country': 'KE', 'flag': '🇰🇪'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCountryCode != null) {
      _selectedCountryCode = widget.initialCountryCode!;
    }

    // Set up controller listener
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _notifyPhoneNumberChanged();
  }

  String get fullPhoneNumber {
    return '$_selectedCountryCode${widget.controller.text}';
  }

  void _updatePhoneNumber() {
    _notifyPhoneNumberChanged();
  }

  void _notifyPhoneNumberChanged() {
    if (widget.onChanged != null) {
      final fullNumber = '$_selectedCountryCode${widget.controller.text}';
      widget.onChanged!(fullNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.getBody(isDark: widget.isDark).copyWith(
              fontWeight: FontWeight.w500,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.sp),
        ],
        // Enhanced Phone Input with Perfect Alignment
        Row(
          children: [
            // Country Code Dropdown
            Container(
              width: 100.sp,
              height: 40.sp, // Match modern input field height
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.darkInputFill
                    : AppColors.inputFill,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.sp),
                  bottomLeft: Radius.circular(12.sp),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCountryCode,
                decoration: InputDecoration(
                  labelText: 'Code',
                  labelStyle: AppTextStyles.getBody(isDark: widget.isDark)
                      .copyWith(
                        color: AppColors.getOnSurfaceColor(
                          widget.isDark,
                        ).withValues(alpha: 0.7),
                      ),
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.sp),
                      bottomLeft: Radius.circular(12.sp),
                    ),
                    borderSide: BorderSide(
                      color: widget.isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.sp),
                      bottomLeft: Radius.circular(12.sp),
                    ),
                    borderSide: BorderSide(
                      color: widget.isDark ? AppColors.darkPrimary : AppColors.primary,
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.sp),
                      bottomLeft: Radius.circular(12.sp),
                    ),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 1.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.sp,
                    vertical: 8.sp, // Match modern input field padding
                  ),
                  filled: true,
                  fillColor: widget.isDark
                      ? AppColors.darkInputFill
                      : AppColors.inputFill,
                ),
                items: _countryCodes.map((country) {
                  return DropdownMenuItem(
                    value: country['code'],
                    child: Row(
                      children: [
                        Text(
                          country['flag']!,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        SizedBox(width: 8.sp),
                        Text(
                          country['code']!,
                          style: AppTextStyles.getBody(isDark: widget.isDark)
                              .copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                style: AppTextStyles.getBody(
                  isDark: widget.isDark,
                ).copyWith(fontSize: 12.sp, fontWeight: FontWeight.w500),
                dropdownColor: widget.isDark
                    ? AppColors.darkInputFill
                    : AppColors.inputFill,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.getOnSurfaceColor(widget.isDark),
                  size: 16.sp,
                ),
                onChanged: widget.enabled
                    ? (value) {
                        setState(() {
                          _selectedCountryCode = value!;
                        });
                        _updatePhoneNumber();
                      }
                    : null,
              ),
            ),
            // Phone Number Input
            Expanded(
              child: Container(
                height: 40.sp, // Match modern input field height
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkInputFill
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.sp),
                    bottomRight: Radius.circular(12.sp),
                  ),
                ),
                child: TextFormField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  style: AppTextStyles.getBody(
                    isDark: widget.isDark,
                  ).copyWith(fontSize: 12.sp, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'Enter your phone number',
                    hintStyle: AppTextStyles.getBody(isDark: widget.isDark)
                        .copyWith(
                          color: AppColors.getOnSurfaceColor(
                            widget.isDark,
                          ).withValues(alpha: 0.5),
                          fontSize: 12.sp,
                        ),
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.sp),
                        bottomRight: Radius.circular(12.sp),
                      ),
                      borderSide: BorderSide(
                        color: widget.isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.sp),
                        bottomRight: Radius.circular(12.sp),
                      ),
                      borderSide: BorderSide(
                        color: widget.isDark ? AppColors.darkPrimary : AppColors.primary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.sp),
                        bottomRight: Radius.circular(12.sp),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.0,
                      ),
                    ),
                    filled: true,
                    fillColor: widget.isDark
                        ? AppColors.darkInputFill
                        : AppColors.inputFill,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.sp,
                      vertical: 8.sp, // Match modern input field padding
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.getOnSurfaceColor(
                        widget.isDark,
                      ).withValues(alpha: 0.7),
                      size: 16.sp,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction:
                      widget.textInputAction ?? TextInputAction.next,
                  onChanged: (value) {
                    _updatePhoneNumber();
                  },
                  onFieldSubmitted: (_) => widget.onSubmitted?.call(),
                  validator: widget.validator,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
