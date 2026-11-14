import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings/theme_controller.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// Light / Dark / System switch. Saves the choice in [ThemeController],
/// which makes the whole app rebuild in the new mode.
class AppearanceSelector extends StatelessWidget {
  const AppearanceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ThemeController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final selected = controller.themeMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _AppearanceOption(
                label: l10n.profileAppearanceLight,
                icon: Icons.light_mode_outlined,
                mode: ThemeMode.light,
                selected: selected,
                onTap: controller.setThemeMode,
              ),
              _AppearanceOption(
                label: l10n.profileAppearanceDark,
                icon: Icons.dark_mode_outlined,
                mode: ThemeMode.dark,
                selected: selected,
                onTap: controller.setThemeMode,
              ),
              _AppearanceOption(
                label: l10n.profileAppearanceSystem,
                icon: Icons.smartphone_outlined,
                mode: ThemeMode.system,
                selected: selected,
                onTap: controller.setThemeMode,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One segment of the switch; highlighted and bold when selected.
class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isSelected = selected == mode;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () => onTap(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? palette.background : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? palette.accent : palette.muted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.manrope(
                      size: 13,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
