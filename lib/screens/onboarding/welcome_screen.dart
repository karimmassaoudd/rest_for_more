import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/rfm_logo.dart';

/// The first screen for new users: what the app does and one main action.
///
/// "Get started" begins onboarding (language → questions → tutorial →
/// cloud save); returning users tap "Log in".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // RfmLogo is drawn at 64×48; FittedBox scales it up sharply.
              ExcludeSemantics(
                child: SizedBox(
                  width: 160,
                  height: 120,
                  child: FittedBox(child: RfmLogo(textColor: palette.accent)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.welcomeTitle,
                textAlign: TextAlign.center,
                style: AppFonts.manrope(
                  size: 32,
                  weight: FontWeight.w700,
                  color: palette.text,
                ).copyWith(height: 1.15),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: AppFonts.manrope(size: 14, color: palette.muted),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/language'),
                  child: Text(l10n.welcomeGetStarted),
                ),
              ),
              const SizedBox(height: 8),
              AuthFooterLink(
                text: l10n.welcomeHaveAccount,
                linkText: l10n.welcomeLogIn,
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
