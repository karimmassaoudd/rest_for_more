import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/onboarding/tutorial_page.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/onboarding/onboarding_progress.dart';

/// How the app works, as swipeable pages with a progress bar and one
/// "Next" button (no skip).
///
/// Two uses:
/// - Onboarding step 3: the last button says "Start" and goes on to
///   cloud save.
/// - Manual ([asManual]), opened from Profile: the last button says
///   "Done" and goes back to Profile. Login and settings are untouched.
///
/// Placeholder content: change the pages in [_pages] (and their texts in
/// the .arb files); the progress bar and buttons adapt.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.asManual = false});

  /// True when opened from Profile instead of during onboarding.
  final bool asManual;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// The pages, in the current language.
  List<TutorialPage> _pages(AppLocalizations l10n) => [
    TutorialPage(
      icon: Icons.timer_outlined,
      title: l10n.tutorialFocusTitle,
      text: l10n.tutorialFocusText,
    ),
    TutorialPage(
      icon: Icons.call_outlined,
      title: l10n.tutorialReachableTitle,
      text: l10n.tutorialReachableText,
    ),
    TutorialPage(
      icon: Icons.wb_sunny_outlined,
      title: l10n.tutorialRoutinesTitle,
      text: l10n.tutorialRoutinesText,
    ),
    TutorialPage(
      icon: Icons.lock_open_outlined,
      title: l10n.tutorialControlTitle,
      text: l10n.tutorialControlText,
    ),
  ];

  void _goTo(int page) => _pageController.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  void _next({required bool isLast}) {
    if (!isLast) {
      _goTo(_page + 1);
    } else if (widget.asManual) {
      _leave();
    } else {
      context.push('/onboarding/cloud');
    }
  }

  /// Previous page; on the first page, leave the tutorial.
  void _back() {
    if (_page > 0) {
      _goTo(_page - 1);
    } else {
      _leave();
    }
  }

  /// Back to where the tutorial was opened from (Profile or Welcome).
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.asManual ? '/profile' : '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;
    final lastLabel = widget.asManual ? l10n.tutorialDone : l10n.tutorialStart;

    return PopScope(
      // Android back gesture: previous page first, then leave the tutorial.
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    _RoundBackButton(onTap: _back, label: l10n.tutorialBack),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OnboardingProgress(
                        step: _page + 1,
                        total: pages.length,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) =>
                        _TutorialPageView(page: pages[i]),
                  ),
                ),
                AuthPrimaryButton(
                  label: isLast ? lastLabel : l10n.tutorialNext,
                  onPressed: () => _next(isLast: isLast),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tutorial page: icon in a sand circle, title and text, centred.
class _TutorialPageView extends StatelessWidget {
  const _TutorialPageView({required this.page});

  final TutorialPage page;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: palette.accent),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppFonts.cormorant(
              size: 32,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.text,
            textAlign: TextAlign.center,
            style: AppFonts.manrope(size: 15, color: palette.muted),
          ),
        ],
      ),
    );
  }
}

/// Looks like AuthBackButton, but goes to the previous tutorial page
/// and has a translated screen-reader label.
class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(Icons.arrow_back, size: 18, color: palette.text),
        ),
      ),
    );
  }
}
