import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/settings/locale_controller.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';
import '../../../../widgets/auth/auth_widgets.dart';
import '../../widgets/common/rfm_logo.dart';

/// First screen of the app: choose English or Nederlands (Figma "Choose your
/// language"). Tapping a language switches the whole app at once and saves
/// the choice (LocaleController, REST-107 / REST-116).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// Language code -> name. Names stay in their own language on purpose,
  /// so people can always find theirs.
  static const _languages = {'en': 'English', 'nl': 'Nederlands'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = Localizations.localeOf(context).languageCode;

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
                      const ExcludeSemantics(
                        child: SizedBox(
                          width: 80,
                          height: 60,
                          child: FittedBox(
                            child: RfmLogo(textColor: AppColors.mediumbrown),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.languageSubtitle,
                        textAlign: TextAlign.center,
                        style: AppFonts.manrope(
                          size: 14,
                          color: AppColors.lightbrown,
                        ),
                      ),
                      const SizedBox(height: 48),
                      for (final entry in _languages.entries)
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

/// Selected: white + brown border + filled radio dot.
/// Unselected: sand, no border, empty radio circle.
/// (Selection is shown by border + dot, not by colour alone.)
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
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? Colors.white : AppColors.surface,
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
                color: selected ? AppColors.mediumbrown : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.manrope(size: 16, weight: FontWeight.w600),
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.mediumbrown : AppColors.lightbrown,
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 12 : 0,
        height: selected ? 12 : 0,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mediumbrown,
        ),
      ),
    );
  }
}
