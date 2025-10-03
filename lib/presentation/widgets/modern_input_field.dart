import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';

class ModernInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixIconPressed;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool autofocus;
  final bool expands;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final bool showCursor;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;
  final bool autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double? borderRadius;
  final double? borderWidth;
  final bool isDark;
  final String? helperText;
  final String? errorText;
  final bool showErrorIcon;
  final bool showSuccessIcon;
  final bool isRequired;

  const ModernInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSuffixIconPressed,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.expands = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical = TextAlignVertical.center,
    this.showCursor = true,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection = true,
    this.autovalidateMode = false,
    this.contentPadding,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.isDark = false,
    this.helperText,
    this.errorText,
    this.showErrorIcon = true,
    this.showSuccessIcon = false,
    this.isRequired = false,
  });

  @override
  State<ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<ModernInputField>
    with SingleTickerProviderStateMixin {
  bool _obscure = true;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _borderColorAnimation =
        ColorTween(begin: AppColors.border, end: AppColors.primary).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  String? _getDefaultValidator(String? value) {
    if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      return 'This field is required';
    }

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Email validation
    if (widget.keyboardType == TextInputType.emailAddress) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
    }

    // Phone validation
    if (widget.keyboardType == TextInputType.phone) {
      final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{0,15}$');
      if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
        return 'Please enter a valid phone number';
      }
    }

    // Password validation
    if (widget.obscureText && widget.label.toLowerCase().contains('password')) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters long';
      }
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Password must contain at least one uppercase letter';
      }
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return 'Password must contain at least one lowercase letter';
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain at least one number';
      }
      if (!RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
      ).hasMatch(value)) {
        return 'Password must be 8+ characters with upper, lower, digit, and special character';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTextStyles.inputLabel(
                    color: isDark
                        ? Colors
                              .white // Pure white in dark mode
                        : AppColors.getOnSurfaceColor(
                            isDark,
                          ).withValues(alpha: 0.8),
                    isDark: isDark,
                  ),
                ),
              ),
              if (widget.isRequired) ...[
                Text(
                  ' *',
                  style: AppTextStyles.inputLabel(
                    color: AppColors.error,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.sp),
        ],

        // Input Field - Using working InputField approach
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Focus(
                onFocusChange: _onFocusChange,
                child: SizedBox(
                  height: 40.sp,
                  child: TextFormField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    keyboardType: widget.keyboardType,
                    maxLength: widget.maxLength,
                    obscureText: widget.obscureText ? _obscure : false,
                    readOnly: widget.readOnly,
                    textInputAction: widget.textInputAction,
                    onTap: widget.onTap,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: (_) =>
                        widget.onSubmitted?.call(widget.controller.text),
                    validator: widget.validator ?? _getDefaultValidator,
                    autofocus: widget.autofocus,
                    expands: widget.expands,
                    textAlign: widget.textAlign,
                    textAlignVertical: widget.textAlignVertical,
                    showCursor: widget.showCursor,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.enableSuggestions,
                    enableInteractiveSelection:
                        widget.enableInteractiveSelection,
                    inputFormatters: widget.inputFormatters,
                    focusNode: widget.focusNode,
                    style: AppTextStyles.getBody(
                      isDark: isDark,
                    ).copyWith(
                      fontSize: 12.sp, 
                      fontWeight: FontWeight.w500,
                      color: widget.enabled
                          ? null
                          : (isDark
                              ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.5)
                              : AppColors.neutral600.withValues(alpha: 0.5)),
                    ),
                    decoration: InputDecoration(
                      labelText: widget.label.isNotEmpty ? null : widget.label,
                      hintText: widget.hint,
                      prefixIcon: widget.prefixIcon != null
                          ? Padding(
                              padding: EdgeInsets.all(8.sp),
                              child: Icon(
                                widget.prefixIcon,
                                color: widget.enabled
                                    ? (isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : AppColors.neutral600)
                                    : (isDark
                                        ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.5)
                                        : AppColors.neutral600.withValues(alpha: 0.5)),
                                size: 16.sp,
                              ),
                            )
                          : null,
                      suffixIcon: widget.obscureText
                          ? IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  key: ValueKey(_obscure),
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.neutral600,
                                ),
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            )
                          : widget.suffixIcon != null
                          ? IconButton(
                              icon: Icon(
                                widget.suffixIcon,
                                color: isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : AppColors.neutral600,
                                size: 16.sp,
                              ),
                              onPressed: widget.onSuffixIconPressed,
                            )
                          : null,
                      counterText: '',
                      filled: true,
                      fillColor: widget.enabled
                          ? (isDark
                              ? AppColors.darkInputFill
                              : AppColors.inputFill)
                          : (isDark
                              ? AppColors.darkInputFill.withValues(alpha: 0.5)
                              : AppColors.inputFill.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                        borderSide: BorderSide(
                          color: _isFocused
                              ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary)
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          width: _isFocused ? 2.0 : 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2.0,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.5)
                              : AppColors.border.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.sp,
                        vertical: 8.sp,
                      ),
                      labelStyle: TextStyle(
                        color: _isFocused
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary)
                            : (isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.neutral600),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      hintStyle: TextStyle(
                        color: widget.enabled
                            ? (isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.neutral800)
                            : (isDark
                                ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.5)
                                : AppColors.neutral800.withValues(alpha: 0.5)),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Helper Text
        if (widget.helperText != null) ...[
          SizedBox(height: 6.sp),
          Text(
            widget.helperText!,
            style: AppTextStyles.caption(
              color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.6),
              isDark: isDark,
            ),
          ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1, end: 0),
        ],
      ],
    );
  }
}
