import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool enabled;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final void Function(String)? onChanged;

  const InputField({
    Key? key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.keyboardType,
    this.hintText,
    this.enabled = true,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  }) : super(key: key);

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> 
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
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _borderColorAnimation = ColorTween(
      begin: AppColors.border,
      end: AppColors.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return AnimatedBuilder(
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
                obscureText: widget.isPassword ? _obscure : false,
                readOnly: widget.readOnly,
                textInputAction: widget.textInputAction,
                onTap: widget.onTap,
                onFieldSubmitted: (_) => widget.onSubmitted?.call(),
                onChanged: widget.onChanged,
                validator: widget.validator,
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon != null 
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: widget.prefixIcon!,
                        )
                      : null,
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              key: ValueKey(_obscure),
                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.neutral600,
                            ),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )
                      : widget.suffixIcon,
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? AppColors.darkInputFill : AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _isFocused 
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: _isFocused ? 2.0 : 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.sp,
                    vertical: 8.sp,
                  ),
                  labelStyle: TextStyle(
                    color: _isFocused 
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.neutral600),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.neutral800,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
