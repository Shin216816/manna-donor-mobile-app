import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

class EnhancedCardInput extends StatefulWidget {
  final Function(Map<String, dynamic> cardData) onCardValidated;
  final Function(String error) onValidationError;
  final bool isLoading;
  final String? initialCardNumber;
  final String? initialExpiry;
  final String? initialCvc;

  const EnhancedCardInput({
    super.key,
    required this.onCardValidated,
    required this.onValidationError,
    this.isLoading = false,
    this.initialCardNumber,
    this.initialExpiry,
    this.initialCvc,
  });

  @override
  State<EnhancedCardInput> createState() => _EnhancedCardInputState();
}

class _EnhancedCardInputState extends State<EnhancedCardInput> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expiryFocus = FocusNode();
  final FocusNode _cvcFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();

  bool _isCardNumberValid = false;
  bool _isExpiryValid = false;
  bool _isCvcValid = false;
  bool _isNameValid = false;
  String _cardType = 'unknown';

  @override
  void initState() {
    super.initState();
    _cardNumberController.text = widget.initialCardNumber ?? '';
    _expiryController.text = widget.initialExpiry ?? '';
    _cvcController.text = widget.initialCvc ?? '';

    _cardNumberController.addListener(_validateCardNumber);
    _expiryController.addListener(_validateExpiry);
    _cvcController.addListener(_validateCvc);
    _nameController.addListener(_validateName);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvcFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _validateCardNumber() {
    final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'\s'), '');
    setState(() {
      _isCardNumberValid = _isValidCardNumber(cardNumber);
      _cardType = _getCardType(cardNumber);
    });
    _validateForm();
  }

  void _validateExpiry() {
    final expiry = _expiryController.text;
    setState(() {
      _isExpiryValid = _isValidExpiry(expiry);
    });
    _validateForm();
  }

  void _validateCvc() {
    final cvc = _cvcController.text;
    setState(() {
      _isCvcValid = _isValidCvc(cvc);
    });
    _validateForm();
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      _isNameValid = name.length >= 2;
    });
    _validateForm();
  }

  void _validateForm() {
    if (_isCardNumberValid && _isExpiryValid && _isCvcValid && _isNameValid) {
      final cardData = {
        'number': _cardNumberController.text.replaceAll(RegExp(r'\s'), ''),
        'expiryMonth': _expiryController.text.split('/')[0],
        'expiryYear': '20${_expiryController.text.split('/')[1]}',
        'cvc': _cvcController.text,
        'name': _nameController.text.trim(),
        'type': _cardType,
      };
      widget.onCardValidated(cardData);
    } else {
      widget.onValidationError('Please fill in all fields correctly');
    }
  }

  bool _isValidCardNumber(String cardNumber) {
    if (cardNumber.length < 13 || cardNumber.length > 19) return false;

    // Luhn algorithm for card validation
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  bool _isValidExpiry(String expiry) {
    if (expiry.length != 5 || !expiry.contains('/')) return false;

    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }

    return true;
  }

  bool _isValidCvc(String cvc) {
    return cvc.length >= 3 && cvc.length <= 4 && RegExp(r'^\d+$').hasMatch(cvc);
  }

  String _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'visa';
    if (RegExp(r'^5[1-5]').hasMatch(cardNumber)) return 'mastercard';
    if (RegExp(r'^3[47]').hasMatch(cardNumber)) return 'amex';
    if (RegExp(r'^6').hasMatch(cardNumber)) return 'discover';
    return 'unknown';
  }

  String _formatCardNumber(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];

    for (int i = 0; i < digits.length; i += 4) {
      final end = (i + 4 < digits.length) ? i + 4 : digits.length;
      groups.add(digits.substring(i, end));
    }

    return groups.join(' ');
  }

  String _formatExpiry(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      return '${digits.substring(0, 2)}/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.credit_card, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Card Information',
                style: AppTextStyles.headlineSmall().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Card Number Field
          _buildCardNumberField(),

          const SizedBox(height: 16),

          // Expiry and CVC Row
          Row(
            children: [
              Expanded(flex: 2, child: _buildExpiryField()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildCvcField()),
            ],
          ),

          const SizedBox(height: 16),

          // Cardholder Name Field
          _buildNameField(),

          const SizedBox(height: 24),

          // Card Preview
          _buildCardPreview(),

          const SizedBox(height: 24),

          // Validation Status
          _buildValidationStatus(),
        ],
      ),
    );
  }

  Widget _buildCardNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Number',
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40.sp,
          child: TextFormField(
            controller: _cardNumberController,
            focusNode: _cardNumberFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
            ],
            decoration: InputDecoration(
              hintText: '1234 5678 9012 3456',
              prefixIcon: _getCardTypeIcon(),
              suffixIcon: _isCardNumberValid
                  ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.sp,
                vertical: 8.sp,
              ),
            ),
            onChanged: (value) {
              final formatted = _formatCardNumber(value);
              if (formatted != value) {
                _cardNumberController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Date',
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40.sp,
          child: TextFormField(
            controller: _expiryController,
            focusNode: _expiryFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: 'MM/YY',
              suffixIcon: _isExpiryValid
                  ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.sp,
                vertical: 8.sp,
              ),
            ),
            onChanged: (value) {
              final formatted = _formatExpiry(value);
              if (formatted != value) {
                _expiryController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCvcField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CVC',
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40.sp,
          child: TextFormField(
            controller: _cvcController,
            focusNode: _cvcFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '123',
              suffixIcon: _isCvcValid
                  ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.sp,
                vertical: 8.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cardholder Name',
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40.sp,
          child: TextFormField(
            controller: _nameController,
            focusNode: _nameFocus,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'John Doe',
              suffixIcon: _isNameValid
                  ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.sp,
                vertical: 8.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final cardNumber = _cardNumberController.text;
    final expiry = _expiryController.text;
    final name = _nameController.text;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _getCardTypeIcon(white: true),
                Icon(
                  Icons.credit_card,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 32,
                ),
              ],
            ),
            const Spacer(),
            Text(
              cardNumber.isEmpty ? '•••• •••• •••• ••••' : cardNumber,
              style: AppTextStyles.title.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARDHOLDER',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      name.isEmpty ? 'YOUR NAME' : name.toUpperCase(),
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPIRES',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      expiry.isEmpty ? 'MM/YY' : expiry,
                      style: AppTextStyles.bodyMedium().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationStatus() {
    final allValid =
        _isCardNumberValid && _isExpiryValid && _isCvcValid && _isNameValid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allValid
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allValid
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allValid ? Icons.check_circle : Icons.info,
            color: allValid ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allValid
                  ? 'Card information is valid and ready to use'
                  : 'Please complete all fields correctly',
              style: AppTextStyles.bodyMedium().copyWith(
                color: allValid ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCardTypeIcon({bool white = false}) {
    final color = white ? Colors.white : Colors.grey[600];
    final size = white ? 32.0 : 24.0;

    switch (_cardType) {
      case 'visa':
        return Icon(Icons.credit_card, color: color, size: size);
      case 'mastercard':
        return Icon(Icons.credit_card, color: color, size: size);
      case 'amex':
        return Icon(Icons.credit_card, color: color, size: size);
      case 'discover':
        return Icon(Icons.credit_card, color: color, size: size);
      default:
        return Icon(Icons.credit_card, color: color, size: size);
    }
  }
}
