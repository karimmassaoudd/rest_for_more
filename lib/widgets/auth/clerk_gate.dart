import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Wrap account screens in this. Shows [child] once Clerk is ready;
/// until then (or offline) shows a calm message instead of blocking the app.
class ClerkGate extends StatefulWidget {
  const ClerkGate({super.key, required this.child});

  final Widget child;

  @override
  State<ClerkGate> createState() => _ClerkGateState();
}

class _ClerkGateState extends State<ClerkGate> {
  late Future<ClerkAuthState> _future = AuthService.instance.state;

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
        if (snapshot.hasData) {
          return ClerkAuth(authState: snapshot.data!, child: widget.child);
        }
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
                  style: AppFonts.cormorant(size: 22, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your focus sessions, profiles and routines still work '
                  'without internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.lightbrown),
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
