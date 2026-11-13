import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth/verify_args.dart';
import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../services/onboarding/welcome_choice_store.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';

/// Log-in screen.
///
/// On success the user goes to Home. If Clerk wants extra proof
/// (new device), it sends an email code and we go to the verify screen.
class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Light local checks; Clerk does the real check.
  /// Shows the errors under the fields and returns true when both are filled in.
  bool _validate() {
    setState(() {
      _emailError = _email.text.trim().contains('@')
          ? null
          : 'Enter a valid email address';
      _passwordError = _password.text.isEmpty ? 'Enter your password' : null;
      _generalError = null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _logIn() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_validate()) return;

    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      final next = await AuthFlow.instance.logIn(
        email: email,
        password: _password.text,
      );
      if (!mounted) return;

      switch (next) {
        case AuthNext.signedIn:
          await WelcomeChoiceStore.instance.markChosen();
          if (mounted) context.go('/');
        case AuthNext.verifyEmail:
          context.push(
            '/verify',
            extra: VerifyArgs(email: email, mode: VerifyMode.signIn),
          );
      }
    } catch (error) {
      if (!mounted) return;
      final failure = describeAuthError(error);
      setState(() {
        switch (failure.field) {
          case AuthField.email:
            _emailError = failure.message;
          case AuthField.password:
            _passwordError = failure.message;
          // No code field on this screen, so code errors show as general.
          case AuthField.code:
          case AuthField.general:
            _generalError = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Placeholder until password reset is built.
  void _forgotPassword() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Password reset is coming soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: AuthScaffold(
        title: 'Log in',
        titleCentered: true,
        subtitle: const Text('Welcome back. Your calm routines are waiting.'),
        primaryLabel: 'Log in',
        onPrimary: _logIn,
        loading: _loading,
        footer: AuthFooterLink(
          text: 'No account yet?',
          linkText: 'Create one',
          onTap: _loading ? null : () => context.pushReplacement('/sign-up'),
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
          ),
          AuthTextField(
            label: 'Password',
            hint: 'Your password',
            controller: _password,
            enabled: !_loading,
            errorText: _passwordError,
            isPassword: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _logIn(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: context.palette.text,
                textStyle: AppFonts.manrope(size: 12, weight: FontWeight.w600),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_generalError != null) ...[
            const SizedBox(height: 8),
            AuthErrorText(_generalError!),
          ],
        ],
      ),
    );
  }
}
