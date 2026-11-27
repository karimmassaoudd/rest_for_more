import 'dart:convert';
import 'dart:math';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  /// [name] is split into Clerk first and last name.
  Future<AuthNext> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = await _auth();
    // Split the name into first and last name, like Google does,
    // so a Google sign-in later doesn't add the last name a second time.
    final parts = name.trim().split(RegExp(r'\s+'));
    await auth.attemptSignUp(
      strategy: clerk.Strategy.emailCode,
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
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

  /// "Forgot password?": Clerk emails a 6-digit reset code.
  ///
  /// Starts a new sign-in with the reset strategy. Also used for
  /// "Resend code" on the reset screen: calling it again sends a new code.
  /// An unknown email throws a ClerkError (form_identifier_not_found).
  Future<void> startPasswordReset(String email) async {
    final auth = await _auth();
    await auth.initiatePasswordReset(
      identifier: email,
      strategy: clerk.Strategy.resetPasswordEmailCode,
    );

    // Clerk now waits for the code. Anything else means no code was sent.
    if (auth.signIn?.status != clerk.Status.needsFirstFactor) {
      debugPrint('Reset not started. Status: ${auth.signIn?.status}');
      throw AuthIncomplete('reset not started: ${auth.signIn?.status}');
    }
  }

  /// Checks the reset code and sets [newPassword]. Clerk then signs the
  /// user in.
  ///
  /// [email] is only used when no reset is in progress anymore (e.g. the
  /// app was restarted); otherwise Clerk reuses the sign-in from
  /// [startPasswordReset]. Passing it every time could start a new
  /// sign-in, which makes the emailed code invalid.
  Future<AuthNext> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    // attemptSignIn only resets with a full 6-digit code; with anything
    // else it would quietly send a new code instead.
    if (code.length != 6) {
      throw const AuthIncomplete(AuthIncomplete.codeNotAccepted);
    }

    final auth = await _auth();
    await auth.attemptSignIn(
      strategy: clerk.Strategy.resetPasswordEmailCode,
      identifier: auth.signIn == null ? email : null,
      code: code,
      password: newPassword,
    );

    if (auth.isSignedIn) return AuthNext.signedIn;

    // Password is changed, but Clerk wants an extra check (new device or
    // 2FA), like on log-in: email a code for "Check your email".
    final status = auth.signIn?.status;
    if (status == clerk.Status.needsSecondFactor ||
        status == clerk.Status.needsClientTrust) {
      await auth.attemptSignIn(strategy: clerk.Strategy.emailCode);
      return AuthNext.verifyEmail;
    }

    // Still waiting for the first factor: the code wasn't accepted.
    throw const AuthIncomplete(AuthIncomplete.codeNotAccepted);
  }

  /// Google sign-in is only set up for Android so far (iOS needs an
  /// Apple developer account first). Screens hide the button otherwise.
  bool get googleAvailable =>
      defaultTargetPlatform == TargetPlatform.android &&
      googleServerClientId.isNotEmpty;

  /// Prepares Google sign-in with a fresh nonce before every sign-in.
  /// Clerk only accepts Google ID tokens from Android that carry a nonce
  /// (a random one-time value), and each nonce only once. On Android,
  /// initialize() just stores these values, so calling it again is safe.
  Future<void> _initGoogle() async {
    await GoogleSignIn.instance.initialize(
      serverClientId: googleServerClientId,
      nonce: _randomNonce(),
    );
  }

  /// 32 random bytes, URL-safe, without padding.
  String _randomNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// "Continue with Google": Google's account picker, then Clerk signs the
  /// user in, or creates the account if this Google account is new.
  /// Returns null when the user closes the picker.
  Future<AuthNext?> signInWithGoogle() async {
    // Already signed in (e.g. a session restored after a restart):
    // nothing to do, the screen just goes Home.
    final auth = await _auth();
    if (auth.isSignedIn) return AuthNext.signedIn;

    await _initGoogle();

    String? idToken;
    try {
      final account = await GoogleSignIn.instance.authenticate();
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    if (idToken == null) throw const AuthIncomplete('no Google ID token');

    await auth.idTokenSignIn(
      provider: clerk.IdTokenProvider.google,
      token: idToken,
    );

    if (auth.isSignedIn) return AuthNext.signedIn;
    debugPrint('Google sign-in incomplete: ${auth.signUp?.missingFields}');
    throw AuthIncomplete('google: missing ${auth.signUp?.missingFields}');
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
    if (googleAvailable) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign-out failed: $e');
      }
    }
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
