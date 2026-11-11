import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';
import '../../../../widgets/auth/auth_widgets.dart';
import '../../widgets/onboarding/onboarding_progress.dart';
import '../../../../l10n/app_localizations.dart';

/// One tutorial page.
class TutorialPage {
  const TutorialPage({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;
}

/// Tutorial screen.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Load translations dynamically.
  List<TutorialPage> _getPages(AppLocalizations l10n) {
    return [
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
  }

  bool get _isLast => _page == 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_isLast) {
      context.push('/onboarding/cloud');
    } else {
      _goTo(_page + 1);
    }
  }

  void _back() {
    if (_page > 0) {
      _goTo(_page - 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _getPages(l10n);

    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) {
          _goTo(_page - 1);
        }
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
                    onPageChanged: (i) {
                      setState(() => _page = i);
                    },
                    itemBuilder: (context, i) {
                      return _TutorialPageView(page: pages[i]);
                    },
                  ),
                ),

                AuthPrimaryButton(
                  label: _isLast ? l10n.tutorialStart : l10n.tutorialNext,
                  onPressed: _next,
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

class _TutorialPageView extends StatelessWidget {
  const _TutorialPageView({required this.page});

  final TutorialPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: AppColors.mediumbrown),
          ),

          const SizedBox(height: 40),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppFonts.cormorant(size: 32, weight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Text(
            page.text,
            textAlign: TextAlign.center,
            style: AppFonts.manrope(size: 15, color: AppColors.lightbrown),
          ),
        ],
      ),
    );
  }
}

/// Back button with translated accessibility label.
class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: AppColors.surface),
          ),
          child: const Icon(
            Icons.arrow_back,
            size: 18,
            color: AppColors.darkbrown,
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../../../theme/app_colors.dart';
// import '../../../../theme/app_fonts.dart';
// import '../../../../widgets/auth/auth_widgets.dart';
// import '../../../../widgets/onboarding/onboarding_progress.dart';

// /// One tutorial page. To add or change a page, edit [kTutorialPages].
// class TutorialPage {
//   const TutorialPage({
//     required this.icon,
//     required this.title,
//     required this.text,
//   });

//   final IconData icon;
//   final String title;
//   final String text;
// }

// /// Onboarding part 2: how to use the app. PLACEHOLDER content —
// /// replace or add pages here; the progress bar and buttons adapt.
// const List<TutorialPage> kTutorialPages = [
//   TutorialPage(
//     icon: Icons.timer_outlined,
//     title: 'Focus sessions',
//     text:
//         'Pick a profile like Study or Read, choose a time, and distracting '
//         'apps are blocked until it ends.',
//   ),
//   TutorialPage(
//     icon: Icons.call_outlined,
//     title: 'Always reachable',
//     text:
//         'Calls, messages and the apps you choose stay available during '
//         'every session.',
//   ),
//   TutorialPage(
//     icon: Icons.wb_sunny_outlined,
//     title: 'Morning and evening routines',
//     text: 'Small calm steps to start and end your day without your phone.',
//   ),
//   TutorialPage(
//     icon: Icons.lock_open_outlined,
//     title: 'You stay in control',
//     text:
//         'Need your phone after all? Emergency unlock ends a session '
//         'whenever you need it.',
//   ),
// ];

// /// Swipeable tutorial with a progress bar and one "Next" button per page
// /// (no skip). Back arrow goes to the previous page, or back to Questions.
// class TutorialScreen extends StatefulWidget {
//   const TutorialScreen({super.key});

//   @override
//   State<TutorialScreen> createState() => _TutorialScreenState();
// }

// class _TutorialScreenState extends State<TutorialScreen> {
//   final _pageController = PageController();
//   int _page = 0;

//   bool get _isLast => _page == kTutorialPages.length - 1;

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _goTo(int page) => _pageController.animateToPage(
//     page,
//     duration: const Duration(milliseconds: 300),
//     curve: Curves.easeOut,
//   );

//   void _next() {
//     if (_isLast) {
//       context.push('/onboarding/cloud');
//     } else {
//       _goTo(_page + 1);
//     }
//   }

//   void _back() {
//     if (_page > 0) {
//       _goTo(_page - 1);
//     } else if (context.canPop()) {
//       context.pop();
//     } else {
//       context.go('/welcome');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       // Android back gesture: previous page first, then leave the tutorial.
//       canPop: _page == 0,
//       onPopInvokedWithResult: (didPop, _) {
//         if (!didPop) _goTo(_page - 1);
//       },
//       child: Scaffold(
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               children: [
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     _RoundBackButton(onTap: _back),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: OnboardingProgress(
//                         step: _page + 1,
//                         total: kTutorialPages.length,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: PageView.builder(
//                     controller: _pageController,
//                     itemCount: kTutorialPages.length,
//                     onPageChanged: (i) => setState(() => _page = i),
//                     itemBuilder: (context, i) =>
//                         _TutorialPageView(page: kTutorialPages[i]),
//                   ),
//                 ),
//                 AuthPrimaryButton(
//                   label: _isLast ? 'Start' : 'Next',
//                   onPressed: _next,
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _TutorialPageView extends StatelessWidget {
//   const _TutorialPageView({required this.page});
//   final TutorialPage page;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(vertical: 32),
//       child: Column(
//         children: [
//           const SizedBox(height: 24),
//           Container(
//             width: 132,
//             height: 132,
//             decoration: const BoxDecoration(
//               color: AppColors.surface,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(page.icon, size: 56, color: AppColors.mediumbrown),
//           ),
//           const SizedBox(height: 40),
//           Text(
//             page.title,
//             textAlign: TextAlign.center,
//             style: AppFonts.cormorant(size: 32, weight: FontWeight.w600),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             page.text,
//             textAlign: TextAlign.center,
//             style: AppFonts.manrope(size: 15, color: AppColors.lightbrown),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Same look as AuthBackButton, but with a custom action (previous page).
// class _RoundBackButton extends StatelessWidget {
//   const _RoundBackButton({required this.onTap});
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Semantics(
//       button: true,
//       label: 'Back',
//       child: InkWell(
//         customBorder: const CircleBorder(),
//         onTap: onTap,
//         child: Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: AppColors.surface),
//           ),
//           child: const Icon(
//             Icons.arrow_back,
//             size: 18,
//             color: AppColors.darkbrown,
//           ),
//         ),
//       ),
//     );
//   }
// }
