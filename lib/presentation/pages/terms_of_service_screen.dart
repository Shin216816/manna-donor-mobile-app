import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  String _termsContent = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTermsContent();
  }

  Future<void> _loadTermsContent() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.getTermsOfService();

      if (mounted) {
        if (response.success) {
          setState(() {
            _termsContent =
                response.data?['content'] ?? 'Terms of service not available.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading terms of service: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = authProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Terms of Service'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: _isLoading
              ? Center(
                  child: EnhancedLoadingWidget(
                    type: LoadingType.spinner,
                    message: 'Loading terms of service...',
                    size: 40,
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTermsContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Text(
                    _termsContent,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.getOnSurfaceColor(isDark),
                      height: 1.6,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
