import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/presentation/widgets/form_container.dart';
import 'package:manna_donate_app/presentation/widgets/input_field.dart';
import 'package:manna_donate_app/presentation/widgets/submit_button.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      setState(() {
        _error = 'Please enter your PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyPin(_pinController.text);

      if (mounted) {
        if (success) {
          // PIN verified successfully, navigate to home
          context.go('/home');
        } else {
          setState(() {
            _error = 'Invalid PIN';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to verify PIN: $e';
          _isLoading = false;
        });
      }
    }
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
                  'Enter PIN to Unlock',
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
                    InputField(
                      controller: _pinController,
                      label: 'PIN',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      isPassword: true,
                    ),
                    if (_error != null)
                      Text(_error!, style: AppTextStyles.error()),
                    const SizedBox(height: 24),
                    SubmitButton(
                      text: 'Unlock',
                      onPressed: _verifyPin,
                      loading: _isLoading,
                    ),
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
