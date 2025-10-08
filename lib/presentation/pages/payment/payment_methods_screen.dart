import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/apiClient/bank_service.dart';
import 'package:manna_donate_app/data/models/payment_method.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/core/utils.dart';

class CardBackgroundPainter extends CustomPainter {
  final String? brand;

  CardBackgroundPainter(this.brand);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(13)
      ..style = PaintingStyle.fill;

    // Draw subtle background patterns based on card brand
    switch (brand?.toLowerCase()) {
      case 'visa':
        _drawVisaPattern(canvas, size, paint);
        break;
      case 'mastercard':
        _drawMastercardPattern(canvas, size, paint);
        break;
      case 'amex':
        _drawAmexPattern(canvas, size, paint);
        break;
      default:
        _drawDefaultPattern(canvas, size, paint);
    }
  }

  void _drawVisaPattern(Canvas canvas, Size size, Paint paint) {
    // Draw diagonal lines
    for (int i = 0; i < 20; i++) {
      final path = Path()
        ..moveTo(i * 30.0, 0)
        ..lineTo(i * 30.0 + 20, size.height);
      canvas.drawPath(path, paint);
    }
  }

  void _drawMastercardPattern(Canvas canvas, Size size, Paint paint) {
    // Draw circles
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 50, paint);
  }

  void _drawAmexPattern(Canvas canvas, Size size, Paint paint) {
    // Draw horizontal lines
    for (int i = 0; i < 15; i++) {
      final rect = Rect.fromLTWH(0, i * 25.0, size.width, 10);
      canvas.drawRect(rect, paint);
    }
  }

  void _drawDefaultPattern(Canvas canvas, Size size, Paint paint) {
    // Draw subtle dots
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawCircle(Offset(i * 60.0, j * 80.0), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen>
    with TickerProviderStateMixin {
  bool _isKeyboardVisible = false;
  int _expandedCardIndex = -1; // Track which card is expanded

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BankProvider>(
        context,
        listen: false,
      ).smartFetchPaymentMethods();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes active (e.g., returning from add payment method or link bank account)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Use smart fetch to use cached data instead of bypassing cache
        await Provider.of<BankProvider>(
          context,
          listen: false,
        ).smartFetchPaymentMethods();
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupKeyboardListener() {
    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (mounted) {
        setState(() {
          _isKeyboardVisible = visible;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildPaymentCard(PaymentMethod method, bool isDark, int index) {
    final isCard = method.type == 'card';
    final isExpanded = _expandedCardIndex == index;

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.sp),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: method.isDefault ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: () => _showCardDetails(method, isDark),
                      child: Container(
                        height: isExpanded ? 200.sp : 180.sp,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCard
                                ? _getCardGradient(method.cardBrand, isDark)
                                : _getBankGradient(isDark),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.sp),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color:
                                  (isCard
                                          ? _getCardGradient(
                                              method.cardBrand,
                                              isDark,
                                            ).first
                                          : _getBankGradient(isDark).first)
                                      .withValues(alpha: 0.15),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background pattern for cards
                            if (isCard)
                              _buildCardBackground(method.cardBrand, isDark),

                            // Card content
                            Padding(
                              padding: EdgeInsets.all(16.sp),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with type and default badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8.sp),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.sp),
                                            ),
                                            child: Icon(
                                              isCard
                                                  ? Icons.credit_card
                                                  : Icons.account_balance,
                                              color: Colors.white,
                                              size: 18.sp,
                                            ),
                                          ),
                                          SizedBox(width: 8.sp),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isCard
                                                    ? 'CREDIT CARD'
                                                    : 'BANK ACCOUNT',
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              if (isCard &&
                                                  method.cardBrand != null)
                                                Text(
                                                  method.cardBrand!
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Default badge
                                  if (method.isDefault) ...[
                                    SizedBox(height: 6.sp),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.sp,
                                          vertical: 4.sp,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.sp,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 14.sp,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 4.sp),
                                            Text(
                                              'DEFAULT',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: 6.sp),

                                  // Card number with enhanced styling
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.sp,
                                      vertical: 8.sp,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        16.sp,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(64),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          isCard
                                              ? '•••• •••• •••• ${method.cardLast4 ?? '••••'}'
                                              : '•••• ${method.bankLast4 ?? '****'}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 2.5,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 6.sp),

                                  // Card details with enhanced styling
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildEnhancedDetailColumn(
                                        'CARD HOLDER',
                                        isCard
                                            ? (method.cardBrand
                                                      ?.toUpperCase() ??
                                                  'N/A')
                                            : (method.billingName ?? 'N/A'),
                                        isDark,
                                      ),
                                      if (isCard) ...[
                                        _buildEnhancedDetailColumn(
                                          'EXPIRES',
                                          '${method.cardExpMonth?.toString().padLeft(2, '0') ?? '**'}/${method.cardExpYear?.toString().substring(2) ?? '**'}',
                                          isDark,
                                        ),
                                      ] else ...[
                                        _buildEnhancedDetailColumn(
                                          'BANK',
                                          method.bankName ?? 'N/A',
                                          isDark,
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Additional info for expanded view
                                  if (isExpanded) ...[
                                    SizedBox(height: 16.sp),
                                    Container(
                                      padding: EdgeInsets.all(12.sp),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.sp,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            size: 14.sp,
                                          ),
                                          SizedBox(width: 8.sp),
                                          Text(
                                            'Added ${_formatDate(method.createdAt)}',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Action buttons with enhanced styling
                            Positioned(
                              top: 16.sp,
                              right: 16.sp,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showDeleteDialog(method.id),
                                    child: Container(
                                      padding: EdgeInsets.all(8.sp),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          10.sp,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.error.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 16.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBackground(String? brand, bool isDark) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.sp),
        child: CustomPaint(painter: CardBackgroundPainter(brand)),
      ),
    );
  }

  List<Color> _getCardGradient(String? brand, bool isDark) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return [
          const Color(0xFF1A1F71),
          const Color(0xFF00539C),
          const Color(0xFF1E3A8A),
        ];
      case 'mastercard':
        return [
          const Color(0xFFEB001B),
          const Color(0xFFF79E1B),
          const Color(0xFFDC2626),
        ];
      case 'amex':
        return [
          const Color(0xFF006FCF),
          const Color(0xFF00A3E0),
          const Color(0xFF2563EB),
        ];
      case 'discover':
        return [
          const Color(0xFFFF6000),
          const Color(0xFFFF8C00),
          const Color(0xFFEA580C),
        ];
      default:
        return isDark
            ? [
                AppColors.darkPrimary,
                AppColors.darkPrimaryDark,
                AppColors.darkPrimary.withValues(alpha: 0.8),
              ]
            : [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.primary.withValues(alpha: 0.8),
              ];
    }
  }

  List<Color> _getBankGradient(bool isDark) {
    return isDark
        ? [
            const Color(0xFF2E7D32),
            const Color(0xFF1B5E20),
            const Color(0xFF166534),
          ]
        : [
            const Color(0xFF4CAF50),
            const Color(0xFF388E3C),
            const Color(0xFF22C55E),
          ];
  }

  Widget _buildHeader(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.all(20.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.05),
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.03),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.sp),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.8),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56.sp,
                    height: 56.sp,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18.sp),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Methods',
                          style: AppTextStyles.getHeader(isDark: isDark)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 24.sp,
                                letterSpacing: -0.5,
                              ),
                        ),
                        SizedBox(height: 6.sp),
                        Text(
                          'Securely manage your payment options',
                          style: AppTextStyles.getSubtitle(isDark: isDark)
                              .copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary.withValues(
                                        alpha: 0.8,
                                      )
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Payment Methods Summary
              Consumer<BankProvider>(
                builder: (context, bankProvider, _) {
                  final paymentMethods = bankProvider.paymentMethods;
                  final cardCount = paymentMethods
                      .where((pm) => pm.type == 'card')
                      .length;
                  final bankCount = paymentMethods
                      .where((pm) => pm.type == 'bank_account')
                      .length;

                  return Row(
                    children: [
                      _buildSummaryItem(
                        isDark,
                        'Total',
                        '${paymentMethods.length}',
                        Icons.credit_card,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryItem(
                        isDark,
                        'Cards',
                        '$cardCount',
                        Icons.credit_card,
                        AppColors.success,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryItem(
                        isDark,
                        'Bank',
                        '$bankCount',
                        Icons.account_balance,
                        AppColors.info,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(32.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140.sp,
                    height: 140.sp,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.15),
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withValues(alpha: 0.2),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary)
                                  .withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64.sp,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 24.sp),
                  Text(
                    'No Payment Methods Yet',
                    style: AppTextStyles.titleLarge(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28.sp,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.sp),
                  Text(
                    'Add your first payment method to start\nmaking secure donations',
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.getOnSurfaceColor(
                        isDark,
                      ).withValues(alpha: 0.6),
                      isDark: isDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.sp),
                  Container(
                    padding: EdgeInsets.all(20.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.darkCard,
                                AppColors.darkCard.withAlpha(204),
                              ]
                            : [AppColors.card, AppColors.card.withAlpha(204)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.sp),
                      border: Border.all(
                        color:
                            (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withAlpha(25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          isDark,
                          Icons.security,
                          'Secure & Encrypted',
                          'Your payment information is protected with bank-level security',
                          AppColors.success,
                        ),
                        SizedBox(height: 16.sp),
                        _buildInfoItem(
                          isDark,
                          Icons.speed,
                          'Fast & Convenient',
                          'Quick setup process with instant verification',
                          AppColors.info,
                        ),
                        SizedBox(height: 16.sp),
                        _buildInfoItem(
                          isDark,
                          Icons.favorite,
                          'Support Churches',
                          'Help your church save on processing fees',
                          AppColors.primary,
                        ),
                        SizedBox(height: 6.sp),
                        Text(
                          'Consider linking your bank account (ACH) instead of a card. ACH transfers have lower processing fees, meaning churches receive more of your donation!',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.getOnSurfaceColor(
                              isDark,
                            ).withAlpha(204),
                            isDark: isDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.sp),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDetails(PaymentMethod method, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: 40.sp,
              height: 4.sp,
              margin: EdgeInsets.only(top: 12.sp, bottom: 20.sp),
              decoration: BoxDecoration(
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.sp),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48.sp,
                          height: 48.sp,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: method.type == 'card'
                                  ? _getCardGradient(method.cardBrand, isDark)
                                  : _getBankGradient(isDark),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14.sp),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (method.type == 'card'
                                            ? _getCardGradient(
                                                method.cardBrand,
                                                isDark,
                                              ).first
                                            : _getBankGradient(isDark).first)
                                        .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            method.type == 'card'
                                ? Icons.credit_card
                                : Icons.account_balance,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Method Details',
                                style: AppTextStyles.titleLarge(isDark: isDark),
                              ),
                              SizedBox(height: 4.sp),
                              Text(
                                method.displayName,
                                style: AppTextStyles.bodyMedium(
                                  color: AppColors.getOnSurfaceColor(
                                    isDark,
                                  ).withValues(alpha: 0.7),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.sp),
                    _buildEnhancedDetailCard(method, isDark),
                    SizedBox(height: 24.sp),
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: method.isDefault
                                ? 'Default Method'
                                : 'Set as Default',
                            onPressed: method.isDefault
                                ? null
                                : () => _setAsDefault(method.id),
                            variant: method.isDefault
                                ? ButtonVariant.outlined
                                : ButtonVariant.primary,
                            isDark: isDark,
                            icon: method.isDefault
                                ? Icons.star
                                : Icons.star_outline,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: ModernButton(
                            text: 'Delete',
                            onPressed: () {
                              context.pop();
                              _showDeleteDialog(method.id);
                            },
                            variant: ButtonVariant.danger,
                            isDark: isDark,
                            icon: Icons.delete_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailCard(PaymentMethod method, bool isDark) {
    final isCard = method.type == 'card';

    return Container(
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.getSurfaceColor(isDark),
            AppColors.getSurfaceColor(isDark).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.sp),
        border: Border.all(
          color: AppColors.getOutlineColor(isDark).withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.sp),
                  border: Border.all(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  isCard ? Icons.credit_card : Icons.account_balance,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCard ? 'Credit Card' : 'Bank Account',
                      style: AppTextStyles.titleMedium(isDark: isDark),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      method.displayName,
                      style: AppTextStyles.bodySmall(
                        color: AppColors.getOnSurfaceColor(
                          isDark,
                        ).withValues(alpha: 0.7),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 4.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.sp),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12.sp, color: Colors.amber),
                      SizedBox(width: 4.sp),
                      Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.sp),
          _buildEnhancedDetailRow('Type', method.type.toUpperCase(), isDark),
          if (isCard) ...[
            _buildEnhancedDetailRow(
              'Brand',
              method.cardBrand?.toUpperCase() ?? 'N/A',
              isDark,
            ),
            _buildEnhancedDetailRow(
              'Last 4',
              method.cardLast4 ?? 'N/A',
              isDark,
            ),
            _buildEnhancedDetailRow(
              'Expires',
              '${method.cardExpMonth?.toString().padLeft(2, '0') ?? '**'}/${method.cardExpYear?.toString() ?? '****'}',
              isDark,
            ),
          ] else ...[
            _buildEnhancedDetailRow('Bank', method.bankName ?? 'N/A', isDark),
            _buildEnhancedDetailRow(
              'Last 4',
              method.bankLast4 ?? 'N/A',
              isDark,
            ),
            _buildEnhancedDetailRow(
              'Account Type',
              method.bankAccountType?.toUpperCase() ?? 'N/A',
              isDark,
            ),
          ],
          _buildEnhancedDetailRow(
            'Default',
            method.isDefault ? 'Yes' : 'No',
            isDark,
          ),
          _buildEnhancedDetailRow(
            'Added',
            _formatDate(method.createdAt),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailRow(String label, String value, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(
          color: AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium(
              color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
              isDark: isDark,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium(
              weight: FontWeight.w600,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _setAsDefault(String paymentMethodId) async {
    try {
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      final response = await bankProvider.setDefaultPaymentMethod(
        paymentMethodId,
      );

      if (mounted) {
        if (response.success) {
          AppUtils.showSnackBar(
            context,
            'Payment method set as default',
            backgroundColor: Colors.green,
          );
          // Data is already refreshed by the bank provider
        } else {
          AppUtils.showSnackBar(
            context,
            response.message,
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'Failed to set default payment method: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppHeader(
        title: 'Payment Methods',
        showThemeToggle: true,
        showBackButton: true,
      ),
      body: Consumer<BankProvider>(
        builder: (context, bankProvider, _) {
          if (bankProvider.loading) {
            return _buildLoadingState(isDark);
          }

          if (bankProvider.error != null) {
            return _buildErrorState(bankProvider.error!, isDark, bankProvider);
          }

          final paymentMethods = bankProvider.paymentMethods;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: _buildModernHeader(isDark, paymentMethods.length),
              ),

              // Content section
              if (paymentMethods.isEmpty)
                SliverFillRemaining(child: _buildModernEmptyState(isDark))
              else ...[
                // Payment methods list
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildModernPaymentCard(
                        paymentMethods[index],
                        isDark,
                        index,
                      ),
                      childCount: paymentMethods.length,
                    ),
                  ),
                ),

                // Add another payment method button
                SliverToBoxAdapter(child: _buildAddMethodButton(isDark)),

                // Bottom spacing
                SliverToBoxAdapter(child: SizedBox(height: 100.sp)),
              ],
            ],
          );
        },
      ),
      // Add bottom padding for floating action button
      bottomNavigationBar: SizedBox(height: 60.sp),
      floatingActionButton: Consumer<BankProvider>(
        builder: (context, bankProvider, _) {
          if (bankProvider.paymentMethods.isEmpty && !bankProvider.loading) {
            return _buildFloatingAddButton(isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoItem(
    bool isDark,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40.sp,
          height: 40.sp,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.sp),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.getBody(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 14.sp),
              ),
              SizedBox(height: 2.sp),
              Text(
                description,
                style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDetailColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 4.sp),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 3.sp),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.sp),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addPaymentMethod() async {
    final result = await context.push('/add-payment-method');

    // If payment method was added successfully, refresh the list
    if (result == true) {
      if (mounted) {
        // Payment methods are already refreshed by the add payment method screen
        // Additional refresh to ensure data is current (use cached data)
        await Provider.of<BankProvider>(
          context,
          listen: false,
        ).smartFetchPaymentMethods();

        AppUtils.showSnackBar(
          context,
          'Payment method added successfully!',
          backgroundColor: Colors.green,
        );
        // Stay on payment methods screen instead of navigating to profile
      }
    }
  }

  Future<void> _showDeleteDialog(String paymentMethodId) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Delete Payment Method',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Text(
          'Are you sure you want to delete this payment method?',
          style: AppTextStyles.getBody(isDark: isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.getBody(
                isDark: isDark,
                color: AppColors.getOnSurfaceColor(isDark),
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: AppTextStyles.getBody(
                isDark: isDark,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final bankProvider = Provider.of<BankProvider>(context, listen: false);
        final response = await bankProvider.deletePaymentMethod(
          paymentMethodId,
        );

        if (mounted) {
          if (response.success) {
            AppUtils.showSnackBar(
              context,
              'Payment method deleted successfully',
              backgroundColor: Colors.green,
            );
            // Data is already refreshed by the bank provider
          } else {
            AppUtils.showSnackBar(
              context,
              response.message,
              backgroundColor: Colors.red,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          AppUtils.showSnackBar(
            context,
            'Failed to delete payment method: $e',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  // ==================== MODERN UI METHODS ====================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingWave(
            message: 'Loading payment methods...',
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            size: 60,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String error,
    bool isDark,
    BankProvider bankProvider,
  ) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24.sp),
        padding: EdgeInsets.all(32.sp),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 24.sp),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12.sp),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.sp),
            ModernButton(
              text: 'Try Again',
              onPressed: () => bankProvider.smartFetchPaymentMethods(),
              isDark: isDark,
              width: 140.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, int paymentMethodCount) {
    return Container(
      margin: EdgeInsets.all(20.sp),
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkPrimary.withValues(alpha: 0.15),
                  AppColors.darkPrimary.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.primary)
              .withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                .withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColors.darkPrimary : AppColors.primary,
                  (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16.sp),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.credit_card_outlined,
              size: 32.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 20.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Payment Methods',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  paymentMethodCount > 0
                      ? '$paymentMethodCount method${paymentMethodCount > 1 ? 's' : ''} saved'
                      : 'Add your first payment method',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: (isDark ? Colors.white : Colors.black87).withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (paymentMethodCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$paymentMethodCount',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState(bool isDark) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24.sp),
        padding: EdgeInsets.all(40.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.15),
                    (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 80.sp,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
            SizedBox(height: 32.sp),
            Text(
              'No Payment Methods',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.sp),
            Text(
              'Add your first payment method to start\nmaking secure donations to your church',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: (isDark ? Colors.white : Colors.black87).withValues(
                  alpha: 0.6,
                ),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.sp),
            _buildFeaturesList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(bool isDark) {
    final features = [
      {
        'icon': Icons.security_rounded,
        'title': 'Bank-level Security',
        'description': 'Your data is encrypted and protected',
        'color': AppColors.success,
      },
      {
        'icon': Icons.flash_on_rounded,
        'title': 'Instant Setup',
        'description': 'Add payment methods in seconds',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Lower Fees',
        'description': 'Help churches save on processing costs',
        'color': AppColors.error,
      },
    ];

    return Container(
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20.sp),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.sp),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    size: 20.sp,
                    color: feature['color'] as Color,
                  ),
                ),
                SizedBox(width: 16.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: (isDark ? Colors.white : Colors.black87)
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModernPaymentCard(PaymentMethod method, bool isDark, int index) {
    final isCard = method.type == 'card';

    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.sp),
        child: InkWell(
          onTap: () => _showCardDetails(method, isDark),
          borderRadius: BorderRadius.circular(20.sp),
          child: Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCard
                    ? _getCardGradient(method.cardBrand, isDark)
                    : _getBankGradient(isDark),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.sp),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color:
                      (isCard
                              ? _getCardGradient(method.cardBrand, isDark).first
                              : _getBankGradient(isDark).first)
                          .withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and default badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.sp),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                          child: Icon(
                            isCard
                                ? Icons.credit_card_rounded
                                : Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCard ? 'Credit Card' : 'Bank Account',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isCard && method.cardBrand != null)
                              Text(
                                method.cardBrand!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (method.isDefault)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.sp,
                          vertical: 4.sp,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.sp),
                            Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20.sp),

                // Card/Account number
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 12.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.sp),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCard
                              ? '•••• •••• •••• ${method.cardLast4 ?? '••••'}'
                              : '•••••••• ${method.bankLast4 ?? '••••'}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.sp),

                // Bottom details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildModernDetailColumn(
                      isCard ? 'Expires' : 'Bank',
                      isCard
                          ? '${method.cardExpMonth?.toString().padLeft(2, '0') ?? '••'}/${method.cardExpYear?.toString().substring(2) ?? '••'}'
                          : method.bankName ?? 'N/A',
                    ),
                    _buildModernDetailColumn(
                      'Added',
                      _formatDate(method.createdAt),
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

  Widget _buildModernDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.sp),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAddMethodButton(bool isDark) {
    return Container(
      margin: EdgeInsets.all(20.sp),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.sp),
        child: InkWell(
          onTap: _addPaymentMethod,
          borderRadius: BorderRadius.circular(16.sp),
          child: Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.1),
                  (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16.sp),
              border: Border.all(
                color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                    .withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 20.sp,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.sp),
                Text(
                  'Add Another Payment Method',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAddButton(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _addPaymentMethod,
      icon: Icon(Icons.add_rounded, size: 24.sp),
      label: Text(
        'Add Payment Method',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
      ),
      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.sp)),
    );
  }
}
