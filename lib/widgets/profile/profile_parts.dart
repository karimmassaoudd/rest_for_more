import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// Profile page frame: centred title above a scrollable list.
/// Same layout for signed-in and guest.
class ProfileLayout extends StatelessWidget {
  const ProfileLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Center(
          child: Text(
            l10n.profileTitle,
            style: AppFonts.cormorant(
              size: 32,
              weight: FontWeight.w600,
              color: context.palette.text,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

/// Small uppercase heading above a section, with an optional
/// "Coming soon" chip.
class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.text, {super.key, this.comingSoon = false});

  final String text;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: AppFonts.manrope(
              size: 11,
              weight: FontWeight.w700,
              color: context.palette.muted,
            ).copyWith(letterSpacing: 1.5),
          ),
          if (comingSoon) ...[const SizedBox(width: 8), const ComingSoonChip()],
        ],
      ),
    );
  }
}

/// Rounded surface-coloured panel that groups rows.
class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Round avatar showing the user's initials.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.accent,
        ),
        child: Text(
          initials,
          style: AppFonts.manrope(
            size: 17,
            weight: FontWeight.w700,
            color: palette.onAccent,
          ),
        ),
      ),
    );
  }
}

/// Tappable row with an icon and label (log out, delete account).
/// Disabled while [onTap] is null. [color] defaults to the text colour.
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? context.palette.text;
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: rowColor, size: 22),
      title: Text(
        label,
        style: AppFonts.manrope(
          size: 15,
          weight: FontWeight.w600,
          color: rowColor,
        ),
      ),
    );
  }
}

/// "Back up my data" row. Not built yet: shown with a "Coming soon" chip
/// and does nothing.
class BackupRow extends StatelessWidget {
  const BackupRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return ListTile(
      enabled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        Icons.cloud_upload_outlined,
        color: palette.muted,
        size: 22,
      ),
      title: Text(
        l10n.profileBackup,
        style: AppFonts.manrope(
          size: 15,
          weight: FontWeight.w600,
          color: palette.text,
        ),
      ),
      subtitle: Text(
        l10n.profileLastBackup,
        style: AppFonts.manrope(size: 12, color: palette.muted),
      ),
      trailing: const ComingSoonChip(),
    );
  }
}

/// "How Rest For More works" row: reopens the onboarding tutorial as a
/// manual. Done or back returns here; nothing else changes.
class ManualRow extends StatelessWidget {
  const ManualRow({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      onTap: () => context.push('/manual'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.menu_book_outlined, color: palette.muted, size: 22),
      title: Text(
        AppLocalizations.of(context).profileManual,
        style: AppFonts.manrope(
          size: 15,
          weight: FontWeight.w600,
          color: palette.text,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: palette.muted),
    );
  }
}

/// Small yellow "Coming soon" tag.
class ComingSoonChip extends StatelessWidget {
  const ComingSoonChip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.highlight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppLocalizations.of(context).profileComingSoon,
        style: AppFonts.manrope(
          size: 11,
          weight: FontWeight.w700,
          color: palette.text,
        ),
      ),
    );
  }
}
