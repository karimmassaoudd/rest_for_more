import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';

/// Read from clerk.json: flutter run --dart-define-from-file=clerk.json
const clerkPublishableKey = String.fromEnvironment('CLERK_PUBLISHABLE_KEY');

/// Starts Clerk in the background so the app never waits for the internet.
/// Home, timer and routines work without it; only account screens use it
/// (client doc 05: backend failure must not block the first screen; T07/T19).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<ClerkAuthState>? _state;

  /// The one shared Clerk state. Completes when Clerk has started.
  Future<ClerkAuthState> get state => _state ??= _create();

  /// Call once in main(). Does not wait.
  void start() {
    unawaited(
      state.then(
        (_) {},
        onError: (Object e) {
          debugPrint('Clerk could not start: $e');
        },
      ),
    );
  }

  /// Try again after an error (e.g. no internet).
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
      _state = null; // allow retry
      rethrow;
    }
  }
}
