import 'package:flutter/material.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';

class FormContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const FormContainer({Key? key, required this.child, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
} 