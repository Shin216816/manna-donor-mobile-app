import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:go_router/go_router.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'dart:async';
import 'package:manna_donate_app/core/api_service.dart';

class BankLinkScreen extends StatefulWidget {
  const BankLinkScreen({super.key});

  @override
  State<BankLinkScreen> createState() => _BankLinkScreenState();
}

class _BankLinkScreenState extends State<BankLinkScreen> {
  bool _isLoading = false;
  String? _error;
  StreamSubscription<LinkSuccess>? _successSub;
  StreamSubscription<LinkExit>? _exitSub;
  StreamSubscription<LinkEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _fetchLinkTokenAndOpenPlaid();
    _successSub = PlaidLink.onSuccess.listen(_onSuccess);
    _exitSub = PlaidLink.onExit.listen(_onExit);
    _eventSub = PlaidLink.onEvent.listen(_onEvent);
  }

  @override
  void dispose() {
    _successSub?.cancel();
    _exitSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLinkTokenAndOpenPlaid() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Set Plaid linking flag to prevent logout
    ApiService.setPlaidLinking(true);

    try {
      final response = await Provider.of<BankProvider>(
        context,
        listen: false,
      ).createLinkToken();
      if (response.success &&
          response.data != null &&
          response.data!['link_token'] != null) {
        final linkToken = response.data!['link_token'];
        final configuration = LinkTokenConfiguration(token: linkToken);
        await PlaidLink.create(configuration: configuration);
        setState(() => _isLoading = false);
        PlaidLink.open();
      } else {
        setState(() {
          _isLoading = false;
          _error = response.message.isNotEmpty
              ? response.message
              : 'Unable to generate link token.';
        });
        // Clear Plaid linking flag on error
        ApiService.setPlaidLinking(false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Handle authentication errors gracefully without triggering logout
        if (e.toString().contains('401') || e.toString().contains('403')) {
          _error = 'Authentication error. Please try logging in again.';
        } else {
          _error = 'Failed to fetch link token.';
        }
      });
      // Clear Plaid linking flag on error
      ApiService.setPlaidLinking(false);
    }
  }

  Future<void> _exchangePublicToken(String publicToken) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Provider.of<BankProvider>(
        context,
        listen: false,
      ).linkBankAccount(publicToken);
      if (response.success) {
        setState(() => _isLoading = false);

        // Clear Plaid linking flag on success
        ApiService.setPlaidLinking(false);
        context.go('/bank-accounts');
      } else {
        setState(() {
          _isLoading = false;
          _error = response.message.isNotEmpty
              ? response.message
              : 'Failed to link account.';
        });
        // Clear Plaid linking flag on error
        ApiService.setPlaidLinking(false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Handle authentication errors gracefully without triggering logout
        if (e.toString().contains('401') || e.toString().contains('403')) {
          _error = 'Authentication error. Please try logging in again.';
        } else {
          _error = 'Failed to link account.';
        }
      });
      // Clear Plaid linking flag on error
      ApiService.setPlaidLinking(false);
    }
  }

  void _onSuccess(LinkSuccess event) {
    // Step 2: Exchange public_token for access_token
    final publicToken = event.publicToken;
    _exchangePublicToken(publicToken);
  }

  void _onExit(LinkExit event) {
    // On exit/cancel, just pop
    context.go('/home');
  }

  void _onEvent(LinkEvent event) {
    // Handle Plaid events
    // If Plaid emits an error event, show a user-friendly message
    if (event.name == 'ERROR' || event.name == 'HANDOFF') {
      setState(() {
        _error =
            'Plaid error: ' +
            (event.metadata.errorMessage?.toString() ?? 'Unknown error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(title: 'Link Bank Account'),
      body: Center(
        child: _isLoading
            ? EnhancedLoadingWidget(
                type: LoadingType.spinner,
                message: 'Loading bank link...',
                size: 50,
              )
            : _error != null
            ? Text(_error!, style: AppTextStyles.error())
            : const Text('Launching Plaid Link...'),
      ),
    );
  }
}
