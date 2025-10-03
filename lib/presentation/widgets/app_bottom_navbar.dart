import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:awesome_bottom_bar/widgets/inspired/inspired.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';

class AppBottomNavBar extends StatefulWidget {
  final int activeIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const List<TabItem> items = [
      TabItem(icon: Icons.home_rounded, title: 'Home'),
      TabItem(icon: Icons.volunteer_activism_rounded, title: 'Roundup'),
      TabItem(icon: Icons.account_balance_rounded, title: 'Bank'),
      TabItem(icon: Icons.person_rounded, title: 'Profile'),
    ];

    return BottomBarInspiredInside(
      items: items,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
      color: Colors.white,
      colorSelected: isDark ? AppColors.darkSurface : AppColors.primary,
      sizeInside: 50,
      height: 40,
      iconSize: 20,
      padTop: 5,
      padbottom: 2,
      indexSelected: widget.activeIndex,
      onTap: (index) {
        widget.onTap(index);
      },
      animated: true,
      chipStyle: const ChipStyle(
        isHexagon: false,
        convexBridge: true,
        background: Colors.white,
        notchSmoothness: NotchSmoothness.smoothEdge,
      ),
      itemStyle: ItemStyle.circle,
    );
  }
}
