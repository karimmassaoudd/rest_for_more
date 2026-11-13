import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth/verify_args.dart';
import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../services/onboarding/welcome_choice_store.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';

// Re-exported so files that import this screen (e.g. router.dart)
// still get VerifyArgs without an extra import.
export '../../models/auth/verify_args.dart';

/// "Check your email" screen.
///
/// The user types the 6-digit code from their email. Used after sign-up,
/// and when Clerk asks for a code on log-in from a new device.
/// "Resend code" has a 30-second cooldown.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.args});

  final VerifyArgs args;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldownSeconds = 30;

  final _code = TextEditingController();
  bool _loading = false;
  String? _codeError;
  String? _generalError;

  Timer? _cooldownTimer;

  /// Seconds left before "Resend code" can be tapped again.
  int _cooldown = _cooldownSeconds;

  @override
  void initState() {
    super.initState();
    // A code was just sent before this screen opened: wait before resending.
    _runCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Resend cooldown
  // ------------------------------------------------------------------

  void _startCooldown() {
    setState(() => _cooldown = _cooldownSeconds);
    _runCooldownTimer();
  }

  /// Counts [_cooldown] down to 0, once per second.
  void _runCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _verify() async {
    final code = _code.text;
    if (_loading) return;
    if (code.length != 6) {
      setState(() => _codeError = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _loading = true;
      _codeError = null;
      _generalError = null;
    });
    try {
      await AuthFlow.instance.verifyCode(widget.args.mode, code);
      await WelcomeChoiceStore.instance.markChosen();
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      final failure = describeAuthError(error);
      setState(() {
        // Everything that isn't a general error (e.g. offline) is about the code.
        if (failure.field == AuthField.general) {
          _generalError = failure.message;
        } else {
          _codeError = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _loading) return;
    setState(() {
      _codeError = null;
      _generalError = null;
    });
    try {
      await AuthFlow.instance.resendCode();
      _code.clear();
      _startCooldown();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('New code sent to ${widget.args.email}')),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _generalError = describeAuthError(error).message);
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final canResend = _cooldown <= 0 && !_loading;

    return AuthScaffold(
      title: 'Check your email',
      subtitle: Text.rich(
        TextSpan(
          text: 'We sent a 6-digit code to ',
          children: [
            TextSpan(
              text: widget.args.email,
              style: AppFonts.manrope(
                size: 13,
                weight: FontWeight.w700,
                color: context.palette.text,
              ),
            ),
          ],
        ),
      ),
      primaryLabel: 'Verify',
      onPrimary: _verify,
      loading: _loading,
      footer: TextButton(
        onPressed: canResend ? _resend : null,
        style: TextButton.styleFrom(
          foregroundColor: context.palette.text,
          textStyle: AppFonts.manrope(size: 13, weight: FontWeight.w700),
        ),
        child: Text(
          _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
        ),
      ),
      children: [
        CodeInput(
          controller: _code,
          hasError: _codeError != null,
          enabled: !_loading,
          onCompleted: (_) => _verify(),
        ),
        if (_codeError != null) ...[
          const SizedBox(height: 10),
          AuthErrorText(_codeError!, center: true),
        ],
        if (_generalError != null) ...[
          const SizedBox(height: 10),
          AuthErrorText(_generalError!, center: true),
        ],
      ],
    );
  }
}
