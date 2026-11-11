import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth/auth_errors.dart';
import '../../services/auth/auth_flow.dart';
import '../../services/onboarding/welcome_choice_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/auth/clerk_gate.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/mascot_sprite.dart' show MascotSprite;

const _red = Color(0xFFB0473A);

/// Profile tab (Figma screens 6, 7, 9, 10).
/// Signed in: REST-103 (name, email, avatar) + log out / delete account.
/// Guest: REST-105 (data only on this phone + create account / log in).
///
/// Appearance (story 11) and Language (story 12) get their own sections
/// here once they are built.
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

/// Page title + scrollable content, same layout for both states.
class _ProfileLayout extends StatelessWidget {
  const _ProfileLayout({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Center(
          child: Text(
            'Profile',
            style: AppFonts.cormorant(size: 32, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

// ---------------------------------------------------------------- signed in

class _SignedInProfile extends StatefulWidget {
  const _SignedInProfile({required this.user});
  final clerk.User user;

  @override
  State<_SignedInProfile> createState() => _SignedInProfileState();
}

class _SignedInProfileState extends State<_SignedInProfile> {
  bool _busy = false;

  Future<void> _logOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'Your focus profiles and routines stay on this phone.',
      confirmLabel: 'Log out',
    );
    if (!confirmed || !mounted) return;
    await _run(AuthFlow.instance.signOut);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete your account?',
      message:
          'This permanently removes your account and backed-up data. '
          "This can't be undone.",
      confirmLabel: 'Delete account',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(AuthFlow.instance.deleteAccount);
  }

  /// Log out / delete, then back to Welcome (REST-101, story 8).
  /// A running focus session is not touched.
  Future<void> _run(Future<void> Function() action) async {
    // Grab these first: once signed out, ClerkAuthBuilder swaps this widget
    // for the guest view, so `context` is gone by the time we navigate.
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
    final user = widget.user;
    final email = user.email ?? '';
    final name = user.hasName ? user.name : email; // REST-103 fallback

    return _ProfileLayout(
      children: [
        _Panel(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _Avatar(initials: _initials(name)),
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
                        ),
                      ),
                      if (email.isNotEmpty && email != name)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.manrope(
                            size: 13,
                            color: AppColors.lightbrown,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const _SectionLabel('Appearance', comingSoon: true),
        const _AppearanceSelector(),
        const _SectionLabel('Language', comingSoon: true),
        const _LanguageRow(),
        const _SectionLabel('Your data'),
        const _Panel(child: _BackupRow()),
        const _SectionLabel('Account'),
        _Panel(
          child: Column(
            children: [
              _ActionRow(
                label: 'Log out',
                icon: Icons.logout,
                onTap: _busy ? null : _logOut,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ActionRow(
                label: 'Delete account',
                icon: Icons.delete_outline,
                color: _red,
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

  static String _initials(String text) {
    final parts = text
        .split(RegExp(r'[\s@.]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}

// -------------------------------------------------------------------- guest

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return _ProfileLayout(
      children: [
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            alignment: Alignment.center,
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
          "You're using Rest For More as a guest",
          textAlign: TextAlign.center,
          style: AppFonts.cormorant(size: 24, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Your data is only saved on this phone.',
          textAlign: TextAlign.center,
          style: AppFonts.manrope(size: 13, color: AppColors.lightbrown),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.push('/sign-up'),
            child: const Text('Create account to keep your data'),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => context.push('/log-in'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkbrown,
              textStyle: AppFonts.manrope(size: 14, weight: FontWeight.w600),
            ),
            child: const Text('Log in'),
          ),
        ),
        const _SectionLabel('Appearance', comingSoon: true),
        const _AppearanceSelector(),
        const _SectionLabel('Language', comingSoon: true),
        const _LanguageRow(),
      ],
    );
  }
}

// ------------------------------------------------------------ small pieces

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.comingSoon = false});
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
              color: AppColors.lightbrown,
            ).copyWith(letterSpacing: 1.5),
          ),
          if (comingSoon) ...[
            const SizedBox(width: 8),
            const _ComingSoonChip(),
          ],
        ],
      ),
    );
  }
}

/// Sand-coloured rounded panel (brand: Sand = panels).
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mediumbrown,
        ),
        child: Text(
          initials,
          style: AppFonts.manrope(
            size: 17,
            weight: FontWeight.w700,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.darkbrown,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: AppFonts.manrope(
          size: 15,
          weight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Story 14 comes in a later sprint: shown, clearly labelled, does nothing.
class _BackupRow extends StatelessWidget {
  const _BackupRow();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(
        Icons.cloud_upload_outlined,
        color: AppColors.lightbrown,
        size: 22,
      ),
      title: Text(
        'Back up my data',
        style: AppFonts.manrope(size: 15, weight: FontWeight.w600),
      ),
      subtitle: Text(
        'Last backup: never',
        style: AppFonts.manrope(size: 12, color: AppColors.lightbrown),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.yellowhighlight.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Coming soon',
          style: AppFonts.manrope(
            size: 11,
            weight: FontWeight.w700,
            color: AppColors.darkbrown,
          ),
        ),
      ),
    );
  }
}

/// Small yellow "Coming soon" tag (same look as on Back up my data).
class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.yellowhighlight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Coming soon',
        style: AppFonts.manrope(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.darkbrown,
        ),
      ),
    );
  }
}

/// Story 11 (Light / Dark / System): looks final, not tappable yet.
class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector();

  static const _options = ['Light', 'Dark', 'System'];
  static const _icons = [
    Icons.light_mode,
    Icons.dark_mode,
    Icons.smartphone_outlined,
  ];
  static const _selected = 'System'; // default from story 11

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Appearance: System. Coming soon',
      child: IgnorePointer(
        child: _Panel(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (var i = 0; i < _options.length; i++)
                  Expanded(
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: _options[i] == _selected
                          ? BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkbrown.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            )
                          : null,
                      child: _segment(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Icon + label for one segment; brown and bold when selected.
  Widget _segment(int i) {
    final selected = _options[i] == _selected;
    final color = selected ? AppColors.darkbrown : AppColors.lightbrown;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icons[i], size: 16, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _options[i],
            overflow: TextOverflow.ellipsis,
            style: AppFonts.manrope(
              size: 13,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Story 12 (English / Nederlands): looks final, not tappable yet.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: ListTile(
        enabled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(
          Icons.language,
          color: AppColors.lightbrown,
          size: 22,
        ),
        title: Text(
          'Language',
          style: AppFonts.manrope(size: 15, weight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'English',
              style: AppFonts.manrope(size: 13, color: AppColors.lightbrown),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lightbrown),
          ],
        ),
      ),
    );
  }
}
