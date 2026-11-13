import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';

/// Read from clerk.json: flutter run --dart-define-from-file=clerk.json
const clerkPublishableKey = String.fromEnvironment('CLERK_PUBLISHABLE_KEY');

/// Starts Clerk in the background so the app never waits for the internet.
///
/// Home, the timer and routines work without it; only the account screens
/// need it. A slow or failing backend must never block the first screen.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<ClerkAuthState>? _state;

  /// The one shared Clerk state. Completes when Clerk has started.
  Future<ClerkAuthState> get state => _state ??= _create();

  /// Call once in main(). Starts Clerk without waiting for it;
  /// a failure is only logged.
  void start() {
    unawaited(
      state.then(
        (_) {},
        onError: (Object e) => debugPrint('Clerk could not start: $e'),
      ),
    );
  }

  /// Starts Clerk again after an error (e.g. no internet).
  /// Used by the "Try again" button in ClerkGate.
  void retry() {
    _state = null;
    start();
  }

  Future<ClerkAuthState> _create() async {
    try {
      return await ClerkAuthState.create(
        config: ClerkAuthConfig(publishableKey: clerkPublishableKey),
      );
    } catch (e) {
      _state = null; // so the next call tries again
      rethrow;
    }
  }
}
