import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/security_provider.dart';
import 'package:manna_donate_app/presentation/widgets/form_container.dart';
import 'package:manna_donate_app/presentation/widgets/submit_button.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? _error;
  bool _loading = false;

  Future<void> _unlock() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final securityProvider = Provider.of<SecurityProvider>(
      context,
      listen: false,
    );
    final success = await securityProvider.unlockWithBiometrics();
    setState(() {
      _loading = false;
      if (!success) {
        _error = 'Unlock failed.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 16),
                child: Text(
                  'Unlock with Biometrics',
                  style: AppTextStyles.header.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              FormContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 64),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Text(_error!, style: AppTextStyles.error()),
                    _loading
                        ? EnhancedLoadingWidget(
                            type: LoadingType.spinner,
                            message: 'Unlocking...',
                            size: 30,
                          )
                        : SubmitButton(text: 'Unlock', onPressed: _unlock),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
