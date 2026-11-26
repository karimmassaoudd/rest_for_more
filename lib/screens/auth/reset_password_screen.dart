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

/// "Forgot password?" step 2: the user types the 6-digit code from their
/// email and a new password. Clerk then changes the password and signs
/// the user in.
///
/// Opened from ForgotPasswordScreen, which already sent the code.
/// "Resend code" has a 30-second cooldown, like VerifyEmailScreen.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  /// Address the code was sent to (shown in bold on the screen).
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _cooldownSeconds = 30;

  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _codeError;
  String? _passwordError;
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
    _password.dispose();
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

  /// Local checks before calling Clerk. Shows the errors and returns true
  /// when the code and the new password look valid.
  bool _validate() {
    setState(() {
      _codeError = _code.text.length == CodeInput.length
          ? null
          : 'Enter the 6-digit code';
      _passwordError = _password.text.length >= 8
          ? null
          : 'Use at least 8 characters';
      _generalError = null;
    });
    return _codeError == null && _passwordError == null;
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_validate()) return;

    setState(() => _loading = true);
    try {
      final next = await AuthFlow.instance.resetPassword(
        widget.email,
        _code.text,
        _password.text,
      );
      if (!mounted) return;

      switch (next) {
        case AuthNext.signedIn:
          await WelcomeChoiceStore.instance.markChosen();
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Your password has been changed.')),
            );
          context.go('/');
        case AuthNext.verifyEmail:
          // Password is changed; Clerk wants one more check (new device).
          context.push(
            '/verify',
            extra: VerifyArgs(email: widget.email, mode: VerifyMode.signIn),
          );
      }
    } catch (error) {
      if (!mounted) return;
      final failure = describeAuthError(error);
      setState(() {
        switch (failure.field) {
          case AuthField.code:
            _codeError = failure.message;
          case AuthField.password:
            _passwordError = failure.message;
          case AuthField.email:
          case AuthField.general:
            _generalError = failure.message;
        }
      });
    } finally {
      // The code and password stay filled in after an error (e.g. offline).
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Sends a new code by starting the reset again.
  Future<void> _resend() async {
    if (_cooldown > 0 || _loading) return;
    setState(() {
      _codeError = null;
      _generalError = null;
    });
    try {
      await AuthFlow.instance.startPasswordReset(widget.email);
      _code.clear();
      _startCooldown();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('New code sent to ${widget.email}')),
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

    return AutofillGroup(
      child: AuthScaffold(
        title: 'New password',
        subtitle: Text.rich(
          TextSpan(
            text: 'Enter the 6-digit code we sent to ',
            children: [
              TextSpan(
                text: widget.email,
                style: AppFonts.manrope(
                  size: 13,
                  weight: FontWeight.w700,
                  color: context.palette.text,
                ),
              ),
              const TextSpan(text: ' and choose a new password.'),
            ],
          ),
        ),
        primaryLabel: 'Set new password',
        onPrimary: _reset,
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
          ),
          if (_codeError != null) ...[
            const SizedBox(height: 10),
            AuthErrorText(_codeError!),
          ],
          const SizedBox(height: 24),
          AuthTextField(
            label: 'New password',
            hint: 'At least 8 characters',
            controller: _password,
            enabled: !_loading,
            errorText: _passwordError,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _reset(),
          ),
          if (_generalError != null) AuthErrorText(_generalError!),
        ],
      ),
    );
  }
}
