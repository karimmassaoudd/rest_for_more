import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings/locale_controller.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/rfm_logo.dart';

/// Onboarding step 1: choose English or Nederlands.
///
/// Tapping a language switches the whole app straight away and saves the
/// choice (see LocaleController).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = Localizations.localeOf(context).languageCode;
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Row(children: [AuthBackButton()]), // back to Welcome
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  child: Column(
                    children: [
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 80,
                          height: 60,
                          child: FittedBox(
                            child: RfmLogo(textColor: palette.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      Text(
                        l10n.languageTitle,
                        textAlign: TextAlign.center,
                        style: AppFonts.cormorant(
                          size: 34,
                          weight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.languageSubtitle,
                        textAlign: TextAlign.center,
                        style: AppFonts.manrope(size: 14, color: palette.muted),
                      ),
                      const SizedBox(height: 48),
                      for (final entry
                          in LocaleController.languageNames.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _LanguageCard(
                            label: entry.value,
                            selected: selected == entry.key,
                            onTap: () => LocaleController.instance.setLanguage(
                              entry.key,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AuthPrimaryButton(
                label: l10n.languageContinue,
                onPressed: () => context.push('/onboarding/questions'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// One language option, styled like a radio button.
///
/// Selected: white, brown border and a filled dot.
/// Unselected: sand, no border and an empty circle.
/// The border and dot show the choice, so it doesn't rely on colour alone.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      // Read out as one radio button in a group.
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.card : palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? palette.accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.manrope(
                      size: 16,
                      weight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                _RadioDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round radio indicator on the right of a language card.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? palette.accent : palette.muted,
          width: 1.5,
        ),
      ),
      // The inner dot grows in when selected.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 12 : 0,
        height: selected ? 12 : 0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.accent,
        ),
      ),
    );
  }
}
