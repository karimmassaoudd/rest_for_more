import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings/locale_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import 'profile_parts.dart';

/// Shows the current language; tapping opens a bottom sheet to pick
/// another. The choice is applied when the user taps Done.
class LanguageRow extends StatelessWidget {
  const LanguageRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final code = Localizations.localeOf(context).languageCode;

    return ProfilePanel(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(Icons.language, color: palette.muted, size: 22),
        title: Text(
          l10n.profileLanguage,
          style: AppFonts.manrope(
            size: 15,
            weight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleController.languageNames[code] ??
                  LocaleController.languageNames['en']!,
              style: AppFonts.manrope(size: 13, color: palette.muted),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: palette.muted),
          ],
        ),
        onTap: () => _showPicker(context, code),
      ),
    );
  }

  void _showPicker(BuildContext context, String currentCode) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => _LanguageSheet(
        initialCode: LocaleController.languageNames.containsKey(currentCode)
            ? currentCode
            : 'en',
      ),
    );
  }
}

/// Bottom sheet with one row per language and a Done button.
class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.initialCode});

  final String initialCode;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  late String _selected = widget.initialCode;

  void _done() {
    LocaleController.instance.setLanguage(_selected);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.profileChooseLanguage,
              style: AppFonts.cormorant(
                size: 28,
                weight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: palette.surface),
            for (final entry in LocaleController.languageNames.entries)
              _LanguageOption(
                label: entry.value,
                selected: _selected == entry.key,
                onTap: () => setState(() => _selected = entry.key),
              ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _done,
                child: Text(
                  l10n.profileLanguageDone,
                  style: AppFonts.manrope(size: 13, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One language row; shows a yellow check when selected.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
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
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.surface)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppFonts.manrope(
                  size: 13,
                  weight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: palette.highlight,
                  shape: BoxShape.circle,
                ),
                // Always dark: it sits on yellow in both modes.
                child: const Icon(
                  Icons.check,
                  size: 17,
                  color: AppColors.darkBrown,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
