import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../services/onboarding/welcome_choice_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/clerk_gate.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/mascot_sprite.dart' show MascotSprite;
import '../../widgets/profile/appearance_selector.dart';
import '../../widgets/profile/language_row.dart';
import '../../widgets/profile/profile_parts.dart';

/// Profile tab.
///
/// Signed in: name, email and initials avatar, appearance, language,
/// manual, backup (coming soon), log out and delete account.
/// Guest: explains data stays on this phone, with buttons to create an
/// account or log in, plus appearance, language and the manual.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ClerkGate(
          child: ClerkAuthBuilder(
            signedInBuilder: (context, auth) =>
                _SignedInProfile(user: auth.user!),
            signedOutBuilder: (context, auth) => const _GuestProfile(),
          ),
        ),
      ),
    );
  }
}

class _SignedInProfile extends StatefulWidget {
  const _SignedInProfile({required this.user});

  final clerk.User user;

  @override
  State<_SignedInProfile> createState() => _SignedInProfileState();
}

class _SignedInProfileState extends State<_SignedInProfile> {
  bool _busy = false;

  Future<void> _logOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.profileLogoutTitle,
      message: l10n.profileLogoutMessage,
      confirmLabel: l10n.profileLogout,
    );
    if (!confirmed || !mounted) return;
    await _run(AuthFlow.instance.signOut);
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.profileDeleteTitle,
      message: l10n.profileDeleteMessage,
      confirmLabel: l10n.profileDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(AuthFlow.instance.deleteAccount);
  }

  /// Runs log out or delete, then goes back to Welcome.
  /// A running focus session is not touched.
  Future<void> _run(Future<void> Function() action) async {
    // Grab these first: once signed out, ClerkAuthBuilder swaps this
    // widget for the guest view, so `context` is gone when we navigate.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      await action();
      await WelcomeChoiceStore.instance.clearChoice();
      router.go('/welcome');
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(describeAuthError(error).message)),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final user = widget.user;
    final email = user.email ?? '';
    final name = user.hasName ? user.name : email;

    return ProfileLayout(
      children: [
        ProfilePanel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProfileAvatar(initials: _initials(name)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cormorant(
                          size: 22,
                          weight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      if (email.isNotEmpty && email != name)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.manrope(
                            size: 13,
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ProfileSectionLabel(l10n.profileAppearance),
        const AppearanceSelector(),
        ProfileSectionLabel(l10n.profileLanguage),
        const LanguageRow(),
        ProfileSectionLabel(l10n.profileHelp),
        const ProfilePanel(child: ManualRow()),
        ProfileSectionLabel(l10n.profileYourData),
        const ProfilePanel(child: BackupRow()),
        ProfileSectionLabel(l10n.profileAccount),
        ProfilePanel(
          child: Column(
            children: [
              ProfileActionRow(
                label: l10n.profileLogout,
                icon: Icons.logout,
                onTap: _busy ? null : _logOut,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ProfileActionRow(
                label: l10n.profileDelete,
                icon: Icons.delete_outline,
                color: AppColors.error,
                onTap: _busy ? null : _deleteAccount,
              ),
            ],
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }

  /// First letter of the first two words, e.g. "Anna de Vries" → "AD".
  /// Falls back to the email ("anna@x.nl" → "AX").
  static String _initials(String text) {
    final parts = text
        .split(RegExp(r'[\s@.]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return ProfileLayout(
      children: [
        Center(
          child: Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
            ),
            child: const ExcludeSemantics(
              child: MascotSprite(
                sheet: 'assets/mascot/sheep-reactions.webp',
                cell: 0,
                size: 86,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.profileGuestTitle,
          textAlign: TextAlign.center,
          style: AppFonts.cormorant(
            size: 24,
            weight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.profileGuestDescription,
          textAlign: TextAlign.center,
          style: AppFonts.manrope(size: 13, color: palette.muted),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.push('/sign-up'),
            child: Text(l10n.profileCreateAccount),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => context.push('/log-in'),
            style: TextButton.styleFrom(
              foregroundColor: palette.text,
              textStyle: AppFonts.manrope(size: 14, weight: FontWeight.w600),
            ),
            child: Text(l10n.profileLogin),
          ),
        ),
        ProfileSectionLabel(l10n.profileAppearance),
        const AppearanceSelector(),
        ProfileSectionLabel(l10n.profileLanguage),
        const LanguageRow(),
        ProfileSectionLabel(l10n.profileHelp),
        const ProfilePanel(child: ManualRow()),
      ],
    );
  }
}
