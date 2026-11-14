import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth/verify_args.dart';
import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../services/onboarding/welcome_choice_store.dart';
import '../../widgets/auth/auth_widgets.dart';

/// Create-account screen.
///
/// Name, email and password are checked locally first, then sent to Clerk.
/// Clerk either signs the user in straight away or asks for an email code,
/// in which case we go to the verify screen.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Local checks before calling Clerk. Shows the errors under the fields
  /// and returns true when everything is valid.
  bool _validate() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _nameError = name.isEmpty ? 'Enter your name' : null;
      _emailError = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
          ? null
          : 'Enter a valid email address';
      _passwordError = password.length >= 8
          ? null
          : 'Use at least 8 characters';
      _generalError = null;
    });
    return _nameError == null && _emailError == null && _passwordError == null;
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (_loading || !_validate()) return;

    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      final next = await AuthFlow.instance.signUp(
        name: _name.text.trim(),
        email: email,
        password: _password.text,
      );
      if (!mounted) return;

      switch (next) {
        case AuthNext.verifyEmail:
          context.push(
            '/verify',
            extra: VerifyArgs(email: email, mode: VerifyMode.signUp),
          );
        case AuthNext.signedIn:
          await WelcomeChoiceStore.instance.markChosen();
          if (mounted) context.go('/');
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
          // This screen has no code field; show code errors as a general error.
          case AuthField.code:
          case AuthField.general:
            _generalError = failure.message;
        }
      });
    } finally {
      // Inputs stay filled in after an error (e.g. offline).
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: AuthScaffold(
        title: 'Create account',
        subtitle: const Text(
          'Keep your routines available when you change phones.',
        ),
        primaryLabel: 'Sign up',
        onPrimary: _signUp,
        loading: _loading,
        footer: AuthFooterLink(
          text: 'Already have an account?',
          linkText: 'Log in',
          onTap: _loading ? null : () => context.pushReplacement('/log-in'),
        ),
        children: [
          AuthTextField(
            label: 'Name',
            hint: 'Your name',
            controller: _name,
            enabled: !_loading,
            errorText: _nameError,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
          ),
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
            hint: 'At least 8 characters',
            controller: _password,
            enabled: !_loading,
            errorText: _passwordError,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signUp(),
          ),
          if (_generalError != null) AuthErrorText(_generalError!),
        ],
      ),
    );
  }
}
