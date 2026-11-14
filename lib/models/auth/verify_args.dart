import '../../services/auth/auth_flow.dart';

/// What the "Check your email" screen needs, passed as go_router `extra`
/// when navigating to `/verify`.
class VerifyArgs {
  const VerifyArgs({required this.email, required this.mode});

  /// Address the code was sent to (shown in bold on the screen).
  final String email;

  /// Whether the code finishes a sign-up or a log-in (Clerk device check).
  final VerifyMode mode;
}
