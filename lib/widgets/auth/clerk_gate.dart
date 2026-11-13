import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// Wraps the account screens. Shows [child] once Clerk has started;
/// until then, or when offline, it shows a calm message (with "Try again"
/// after an error) instead of blocking the rest of the app.
class ClerkGate extends StatefulWidget {
  const ClerkGate({super.key, required this.child});

  final Widget child;

  @override
  State<ClerkGate> createState() => _ClerkGateState();
}

class _ClerkGateState extends State<ClerkGate> {
  late Future<ClerkAuthState> _future = AuthService.instance.state;

  /// Starts Clerk again and waits for the new attempt.
  void _retry() {
    AuthService.instance.retry();
    setState(() {
      _future = AuthService.instance.state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClerkAuthState>(
      future: _future,
      builder: (context, snapshot) {
        final palette = context.palette;
        if (snapshot.hasData) {
          return ClerkAuth(authState: snapshot.data!, child: widget.child);
        }
        // Still connecting, or failed.
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.hasError
                      ? "Can't reach your account right now"
                      : 'Connecting to your account…',
                  textAlign: TextAlign.center,
                  style: AppFonts.cormorant(
                    size: 22,
                    weight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your focus sessions, profiles and routines still work '
                  'without internet.',
                  textAlign: TextAlign.center,
                  style: AppFonts.manrope(size: 14, color: palette.muted),
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _retry,
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
