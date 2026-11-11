import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/onboarding/welcome_choice_store.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';
import '../../../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/mascot_sprite.dart' show MascotSprite;

/// Onboarding part 3: optional account (Flow A step 7, client doc 03:
/// "Then offer optional saving or synchronisation").
/// Create account (REST-98) or Not now = continue as guest (REST-97).
/// Wording says "can be backed up": the backup itself is story 14.
class CloudSaveScreen extends StatelessWidget {
  const CloudSaveScreen({super.key});

  Future<void> _notNow(BuildContext context) async {
    await WelcomeChoiceStore.instance.markChosen();
    if (context.mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
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
                ).copyWith(height: 1.15),
              ),
              const SizedBox(height: 12),
              Text(
                'Create a free account so your focus profiles and routines '
                'can be backed up when you change phones. '
                'An account is optional.',
                textAlign: TextAlign.center,
                style: AppFonts.manrope(size: 14, color: AppColors.lightbrown),
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
                  foregroundColor: AppColors.darkbrown,
                  textStyle: AppFonts.manrope(
                    size: 14,
                    weight: FontWeight.w600,
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
