import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// What the screen should do after a sign-up or log-in call.
enum AuthNext {
  /// Done: the user is signed in.
  signedIn,

  /// Clerk emailed a 6-digit code: open "Check your email".
  verifyEmail,
}

/// Which flow the "Check your email" screen is finishing.
enum VerifyMode { signUp, signIn }

/// Thrown when Clerk answered without an error but the user is still not
/// signed in (e.g. the code was not accepted).
class AuthIncomplete implements Exception {
  const AuthIncomplete([this.detail = '']);

  /// [detail] when the 6-digit code was rejected; auth_errors.dart
  /// turns this into "Wrong code, try again".
  static const codeNotAccepted = 'code not accepted';

  final String detail;

  @override
  String toString() => 'AuthIncomplete: $detail';
}

/// All Clerk calls for the account screens, so the screens only do UI.
///
/// Based on clerk_auth 0.0.18-beta (Auth.attemptSignUp / attemptSignIn):
/// - attemptSignUp with Strategy.emailCode creates the sign-up and
///   automatically emails the code when only the email is unverified.
/// - Calling it again with `code:` verifies the email and signs the user in.
class AuthFlow {
  AuthFlow._();
  static final AuthFlow instance = AuthFlow._();

  /// Waits for Clerk (started in the background in main), max 15 s,
  /// so an offline phone gets a clear error instead of waiting forever.
  Future<ClerkAuthState> _auth() =>
      AuthService.instance.state.timeout(const Duration(seconds: 15));

  /// Creates the account; Clerk then emails a 6-digit code.
  /// [name] is stored as the Clerk first name.
  Future<AuthNext> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = await _auth();
    await auth.attemptSignUp(
      strategy: clerk.Strategy.emailCode,
      firstName: name,
      emailAddress: email,
      password: password,
      passwordConfirmation: password,
    );

    if (auth.isSignedIn) return AuthNext.signedIn;

    final signUp = auth.signUp;
    if (signUp != null && signUp.unverified(clerk.Field.emailAddress)) {
      return AuthNext.verifyEmail;
    }
    debugPrint('Sign-up incomplete. Missing: ${signUp?.missingFields}');
    throw AuthIncomplete('missing ${signUp?.missingFields}');
  }

  /// Checks the 6-digit code, after sign-up or after the extra device check on log-in.
  Future<void> verifyCode(VerifyMode mode, String code) async {
    final auth = await _auth();
    switch (mode) {
      case VerifyMode.signUp:
        await auth.attemptSignUp(
          strategy: clerk.Strategy.emailCode,
          code: code,
        );
      case VerifyMode.signIn:
        await auth.attemptSignIn(
          strategy: clerk.Strategy.emailCode,
          code: code,
        );
    }
    if (!auth.isSignedIn) {
      throw const AuthIncomplete(AuthIncomplete.codeNotAccepted);
    }
  }

  /// "Resend code" on the Check your email screen.
  Future<void> resendCode() async {
    final auth = await _auth();
    await auth.resendCode(clerk.Strategy.emailCode);
  }

  /// Logs in with email and password.
  Future<AuthNext> logIn({
    required String email,
    required String password,
  }) async {
    final auth = await _auth();
    await auth.attemptSignIn(
      strategy: clerk.Strategy.password,
      identifier: email,
      password: password,
    );

    if (auth.isSignedIn) return AuthNext.signedIn;

    // Device Trust (new device) or another extra check: Clerk wants a code.
    // This call emails it; the user enters it on "Check your email".
    if (auth.signIn?.status.needsFactor == true) {
      await auth.attemptSignIn(strategy: clerk.Strategy.emailCode);
      return AuthNext.verifyEmail;
    }
    throw AuthIncomplete('sign-in status ${auth.signIn?.status}');
  }

  /// Logs out. Only the Clerk session ends; focus profiles,
  /// routines and a running focus session stay on the phone.
  Future<void> signOut() async {
    final auth = await _auth();
    await auth.signOut();
  }

  /// Deletes the Clerk user.
  /// Needs "Allow users to delete their account" on in the Clerk dashboard.
  /// Once there is a database, the user's rows must be deleted here too.
  Future<void> deleteAccount() async {
    final auth = await _auth();
    await auth.deleteUser();
    // deleteUser() doesn't report every server error, so check the result.
    if (auth.isSignedIn) throw const AuthIncomplete('account not deleted');
  }
}
