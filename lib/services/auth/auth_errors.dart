import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;

import 'auth_flow.dart';

/// Which field an error message belongs under.
enum AuthField { email, password, code, general }

/// A calm, user-facing error message and where to show it.
class AuthFailure {
  const AuthFailure(this.field, this.message);
  final AuthField field;
  final String message;
}

const _offline =
    "Can't reach Rest For More right now. Check your internet and try again.";
const _somethingWrong = 'Something went wrong. Please try again.';

/// Turns a Clerk or network error into our own message, in the brand tone:
/// supportive, never "You failed".
///
/// Clerk error codes: https://clerk.com/docs/errors/overview
AuthFailure describeAuthError(Object error) {
  if (_looksOffline(error)) {
    return const AuthFailure(AuthField.general, _offline);
  }

  if (error is AuthIncomplete) {
    return error.detail == AuthIncomplete.codeNotAccepted
        ? const AuthFailure(AuthField.code, 'Wrong code, try again')
        : const AuthFailure(AuthField.general, _somethingWrong);
  }

  if (error is clerk.ClerkError) {
    final codes = <String>{for (final e in error.errors?.errors ?? []) ?e.code};

    if (codes.contains('form_identifier_exists')) {
      return const AuthFailure(AuthField.email, 'This email is already in use');
    }
    if (codes.contains('form_param_format_invalid') ||
        codes.contains('form_email_address_invalid')) {
      return const AuthFailure(AuthField.email, 'Enter a valid email address');
    }
    // Don't reveal whether the email or the password was wrong.
    if (codes.contains('form_password_incorrect') ||
        codes.contains('form_identifier_not_found')) {
      return const AuthFailure(
        AuthField.password,
        'Email or password is incorrect',
      );
    }
    if (codes.contains('form_password_pwned')) {
      return const AuthFailure(
        AuthField.password,
        'This password appeared in a data leak. Please choose another one.',
      );
    }
    if (codes.any((c) => c.startsWith('form_password'))) {
      return const AuthFailure(AuthField.password, 'Use at least 8 characters');
    }
    if (codes.contains('form_code_incorrect') ||
        codes.contains('verification_failed')) {
      return const AuthFailure(AuthField.code, 'Wrong code, try again');
    }
    if (codes.contains('verification_expired')) {
      return const AuthFailure(
        AuthField.code,
        'This code has expired. Tap Resend code.',
      );
    }
    if (codes.contains('too_many_requests')) {
      return const AuthFailure(
        AuthField.general,
        'Too many attempts. Wait a minute and try again.',
      );
    }
    // Unknown server error: show Clerk's own text so we can still act on it.
    final text = error.errors?.errorMessage;
    if (text != null && text.isNotEmpty) {
      return AuthFailure(AuthField.general, text);
    }
  }

  return const AuthFailure(AuthField.general, _somethingWrong);
}

/// True for timeouts and the usual "no internet" errors from the HTTP layer.
bool _looksOffline(Object error) {
  if (error is TimeoutException) return true;
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('ClientException') ||
      text.contains('Connection refused');
}
