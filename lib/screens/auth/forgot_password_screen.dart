import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../widgets/auth/auth_widgets.dart';

/// "Forgot password?" step 1: the user enters their email and Clerk
/// emails a 6-digit reset code. Step 2 (code + new password) is
/// ResetPasswordScreen.
///
/// Opened from the log-in screen. [initialEmail] is what the user already
/// typed there, so they don't have to type it again.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);

  bool _loading = false;
  String? _emailError;
  String? _generalError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// Local check before calling Clerk (same rule as Create account).
  bool _validate() {
    final email = _email.text.trim();
    setState(() {
      _emailError = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
          ? null
          : 'Enter a valid email address';
      _generalError = null;
    });
    return _emailError == null;
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_validate()) return;

    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await AuthFlow.instance.startPasswordReset(email);
      if (!mounted) return;
      context.push('/reset-password', extra: email);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        // Log-in hides whether the email exists; here we say it plainly.
        if (isUnknownAccount(error)) {
          _emailError = "We couldn't find an account with this email";
        } else {
          final failure = describeAuthError(error);
          if (failure.field == AuthField.email) {
            _emailError = failure.message;
          } else {
            _generalError = failure.message;
          }
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: AuthScaffold(
        title: 'Reset password',
        subtitle: const Text(
          "Enter your email and we'll send you a code to choose a new password.",
        ),
        primaryLabel: 'Send code',
        onPrimary: _sendCode,
        loading: _loading,
        footer: AuthFooterLink(
          text: 'Remembered it?',
          linkText: 'Log in',
          onTap: _loading
              ? null
              : () => context.canPop() ? context.pop() : context.go('/log-in'),
        ),
        children: [
          AuthTextField(
            label: 'Email',
            hint: 'name@email.com',
            controller: _email,
            enabled: !_loading,
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendCode(),
          ),
          if (_generalError != null) AuthErrorText(_generalError!),
        ],
      ),
    );
  }
}
