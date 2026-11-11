import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';
import '../../../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/rfm_logo.dart';

/// Welcome (Flow A step 1, client doc 03): what the app does, one primary
/// action. New users → questions → tutorial → cloud. Returning → Log in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // RfmLogo is drawn at 64×48; FittedBox scales it up sharply.
              const ExcludeSemantics(
                child: SizedBox(
                  width: 160,
                  height: 120,
                  child: FittedBox(
                    child: RfmLogo(textColor: AppColors.mediumbrown),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to \n Rest For More',
                textAlign: TextAlign.center,
                style: AppFonts.cormorant(
                  size: 36,
                  weight: FontWeight.w600,
                ).copyWith(height: 1.1),
              ),
              const SizedBox(height: 16),
              Text(
                'Put your phone away, build calm routines.\n'
                'A RestNest is optional.',
                textAlign: TextAlign.center,
                style: AppFonts.manrope(size: 14, color: AppColors.lightbrown),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/language'),
                  child: const Text('Get started'),
                ),
              ),
              const SizedBox(height: 8),
              AuthFooterLink(
                text: 'Already have an account?',
                linkText: 'Log in',
                onTap: () => context.push('/log-in'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
