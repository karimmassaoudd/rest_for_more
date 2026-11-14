import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/onboarding/welcome_choice_store.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/mascot_sprite.dart';

/// Onboarding step 4 (last): offer an optional account.
///
/// "Create account" goes to sign-up; "Not now" continues as a guest and
/// goes Home. Either way, Welcome isn't shown again.
/// The text says profiles and routines "can be backed up": the backup
/// itself isn't built yet.
class CloudSaveScreen extends StatelessWidget {
  const CloudSaveScreen({super.key});

  /// Continue as a guest.
  Future<void> _notNow(BuildContext context) async {
    await WelcomeChoiceStore.instance.markChosen();
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Row(children: [AuthBackButton()]),
              const Spacer(flex: 2),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                ),
                alignment: Alignment.center,
                child: const ExcludeSemantics(
                  child: MascotSprite(
                    sheet: 'assets/mascot/sheep-reactions.webp',
                    cell: 1, // smile with heart
                    size: 110,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Save your things to the cloud?',
                textAlign: TextAlign.center,
                style: AppFonts.cormorant(
                  size: 32,
                  weight: FontWeight.w600,
                  color: palette.text,
                ).copyWith(height: 1.15),
              ),
              const SizedBox(height: 12),
              Text(
                'Create a free account so your focus profiles and routines '
                'can be backed up when you change phones. '
                'An account is optional.',
                textAlign: TextAlign.center,
                style: AppFonts.manrope(size: 14, color: palette.muted),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/sign-up'),
                  child: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _notNow(context),
                style: TextButton.styleFrom(
                  foregroundColor: palette.text,
                  textStyle: AppFonts.manrope(
                    size: 14,
                    weight: FontWeight.w600,
                    color: palette.text,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
                child: const Text('Not now, continue as guest'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
