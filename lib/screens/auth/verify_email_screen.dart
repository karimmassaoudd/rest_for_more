import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../services/onboarding/welcome_choice_store.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';
import '../../../../widgets/auth/auth_widgets.dart';

/// What the Check your email screen needs (passed as go_router `extra`).
class VerifyArgs {
  const VerifyArgs({required this.email, required this.mode});
  final String email;
  final VerifyMode mode;
}

/// REST-99 Verify email (Figma screen 3 + error variant).
/// Also used when Clerk asks for a code on log-in (Device Trust).
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
  int _cooldown = _cooldownSeconds; // a code was just sent

  @override
  void initState() {
    super.initState();
    _runCooldownTimer(); // a code was just sent: wait before "Resend"
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = _cooldownSeconds);
    _runCooldownTimer();
  }

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
                color: AppColors.darkbrown,
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
          foregroundColor: AppColors.darkbrown,
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
