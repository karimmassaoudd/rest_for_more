import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/onboarding/onboarding_progress.dart';

// Pictures from the assets folder. Change the paths to your file names
// (and list the folder under `flutter: assets:` in pubspec.yaml).
const _blockImage = 'assets/images/onboarding_apps_examples.png';
const _timerImage = 'assets/images/onboarding_timerpage_example.png';
const _routineImage = 'assets/images/onboarding_cards_example.png';

// Where the arrow goes when there is nothing to pop back to: the screen
// before the tutorial in onboarding (questions_screen.dart). Set this to
// that screen's route if it is not this one.
const _questionsRoute = '/onboarding/questions';

/// Size of the lock icon on the last page. The icons on the "Always
/// reachable" page are drawn with the same line thickness.
const _lockIconSize = 56.0;

/// How the app works, as swipeable pages with a progress bar and
/// Back / Next buttons side by side (no skip).
///
/// Two uses:
/// - Onboarding step 3: the last button says "Start" and goes on to
///   cloud save.
/// - Manual ([asManual]), opened from Profile: the last button says
///   "Done" and goes back to Profile. Login and settings are untouched.
///
/// Every page is built from a title, small illustrations and body text.
/// Change the pages in [_pages] (and their texts in the .arb files).
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
  List<Widget> _pages(AppLocalizations l10n) => [
    // 1. Focus on a profile
    _PageLayout(
      title: l10n.tutorialFocusTitle,
      children: [
        _Body(l10n.tutorialFocusText),
        const SizedBox(height: 24),
        _ProfileChip(
          icon: Icons.center_focus_strong_outlined,
          label: l10n.tutorialFocusProfile1,
        ),
        const SizedBox(height: 14),
        _ProfileChip(
          icon: Icons.menu_book_outlined,
          label: l10n.tutorialFocusProfile2,
          showCursor: true,
        ),
        const SizedBox(height: 28),
        _Body(l10n.tutorialFocusText2),
        const SizedBox(height: 20),
        _ProfileChip(
          icon: Icons.school_outlined,
          label: l10n.tutorialFocusProfile3,
        ),
      ],
    ),
    // 2. Block distractions
    _PageLayout(
      title: l10n.tutorialBlockTitle,
      children: [
        _Body(l10n.tutorialBlockText),
        const SizedBox(height: 14),
        const _AssetImage(
          path: _blockImage,
          heightFactor: 0.25,
          fallback: _BlockedAppsCloud(),
        ),
        const SizedBox(height: 14),
        _Body(l10n.tutorialBlockText2),
      ],
    ),
    // 3. Always reachable
    _PageLayout(
      title: l10n.tutorialReachableTitle,
      children: [
        const SizedBox(height: 8),
        const _ReachableCluster(),
        const SizedBox(height: 40),
        _Body(l10n.tutorialReachableText),
        const SizedBox(height: 32),
        _Body(l10n.tutorialReachableText2),
      ],
    ),
    // 4. Take control of your time
    _PageLayout(
      title: l10n.tutorialTimeTitle,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _Body(l10n.tutorialTimeText)),
            const SizedBox(width: 16),
            const _AssetImage(
              path: _timerImage,
              maxWidthFactor: 0.63,
              heightFactor: 0.45,
              fallback: _TimerPhone(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Body(l10n.tutorialTimeText2),
        const SizedBox(height: 16),
        _Body(l10n.tutorialTimeText3),
      ],
    ),
    // 5. Follow a routine
    _PageLayout(
      title: l10n.tutorialRoutinesTitle,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _Body(l10n.tutorialRoutinesText)),
            const SizedBox(width: 8),
            _AssetImage(
              path: _routineImage,
              maxWidthFactor: 0.63,
              heightFactor: 0.45,
              fallback: _RoutineCards(
                morning: l10n.tutorialRoutinesMorning,
                evening: l10n.tutorialRoutinesEvening,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Body(l10n.tutorialRoutinesText2),
      ],
    ),
    // 6. Stay in control
    _PageLayout(
      title: l10n.tutorialControlTitle,
      children: [
        const SizedBox(height: 8),
        const _LockCircle(),
        const SizedBox(height: 32),
        _Body(l10n.tutorialControlText),
        const SizedBox(height: 16),
        _Body(l10n.tutorialControlText2),
      ],
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

  /// Back to the screen the tutorial was opened from: Profile (manual) or
  /// the questions screen (onboarding). Used by the top-left arrow, and by
  /// the Back button on the first page.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.asManual ? '/profile' : _questionsRoute);
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
                    _RoundBackButton(onTap: _leave, label: l10n.tutorialBack),
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
                    itemBuilder: (context, i) => pages[i],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AuthPrimaryButton(
                        label: l10n.tutorialBack,
                        onPressed: _back,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthPrimaryButton(
                        label: isLast ? lastLabel : l10n.tutorialNext,
                        onPressed: () => _next(isLast: isLast),
                      ),
                    ),
                  ],
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

// ---------------------------------------------------------------------------
// Page building blocks
// ---------------------------------------------------------------------------

/// Centred title, then the page content.
class _PageLayout extends StatelessWidget {
  const _PageLayout({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.cormorant(
              size: 28,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

/// Left-aligned body text.
class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      text,
      textAlign: TextAlign.start,
      style: AppFonts.manrope(size: 17, color: palette.text),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1: profile chips
// ---------------------------------------------------------------------------

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.icon,
    required this.label,
    this.showCursor = false,
  });

  final IconData icon;
  final String label;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: palette.accent),
              const SizedBox(width: 14),
              Text(
                label,
                style: AppFonts.manrope(size: 17, color: palette.text),
              ),
            ],
          ),
        ),
        if (showCursor)
          Positioned(
            right: 24,
            bottom: -18,
            child: Icon(Icons.touch_app, size: 40, color: palette.text),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2: blocked apps
// ---------------------------------------------------------------------------

class _BlockedAppsCloud extends StatelessWidget {
  const _BlockedAppsCloud();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 170,
      child: Stack(
        children: [
          Align(
            alignment: Alignment(-0.45, -0.7),
            child: _AppTile(Icons.close),
          ),
          Align(
            alignment: Alignment(0.25, -0.9),
            child: _AppTile(Icons.push_pin_outlined),
          ),
          Align(
            alignment: Alignment(0.7, 0.1),
            child: _AppTile(Icons.note_alt_outlined),
          ),
          Align(
            alignment: Alignment(-0.1, 0.8),
            child: _AppTile(Icons.music_note),
          ),
        ],
      ),
    );
  }
}

/// App icon tile with a small red "blocked" badge.
class _AppTile extends StatelessWidget {
  const _AppTile(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: palette.text),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFFD9695F),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3: always reachable
// ---------------------------------------------------------------------------

/// Three overlapping circles with a soft shadow: call in the middle,
/// chat and calendar either side below it.
class _ReachableCluster extends StatelessWidget {
  const _ReachableCluster();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 250,
        height: 156,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 58,
              child: _IconCircle(Icons.chat_outlined, size: 92),
            ),
            Positioned(
              right: 0,
              top: 58,
              child: _IconCircle(Icons.calendar_month_outlined, size: 92),
            ),
            // Last, so it sits on top of the two side circles.
            Positioned(
              left: 72,
              top: 0,
              child: _IconCircle(Icons.call_outlined, size: 106),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle(this.icon, {required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final iconSize = size * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: _BoldIcon(
          icon,
          size: iconSize,
          color: palette.accent,
          // A Material icon's line is about size / 12 thick. Add what is
          // missing to reach the thickness of the lock icon (56 / 12).
          thickness: (_lockIconSize - iconSize).clamp(0.0, 100.0) / 12,
        ),
      ),
    );
  }
}

/// An icon with a thicker line: the glyph is drawn twice, once filled and
/// once with an outline of the same colour. Raise [thickness] for bolder.
class _BoldIcon extends StatelessWidget {
  const _BoldIcon(
    this.icon, {
    required this.size,
    required this.color,
    this.thickness = 1.4,
  });

  final IconData icon;
  final double size;
  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final glyph = String.fromCharCode(icon.codePoint);
    final base = TextStyle(
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      fontSize: size,
      height: 1,
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              glyph,
              textScaler: TextScaler.noScaling,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = thickness
                  ..strokeJoin = StrokeJoin.round
                  ..color = color,
              ),
            ),
            Text(
              glyph,
              textScaler: TextScaler.noScaling,
              style: base.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4: timer phone
// ---------------------------------------------------------------------------

class _TimerPhone extends StatelessWidget {
  const _TimerPhone();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 120,
      height: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.text, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 0.6,
                    strokeWidth: 6,
                    backgroundColor: palette.surface,
                    color: palette.accent,
                  ),
                ),
                Text(
                  '14:58',
                  style: AppFonts.manrope(
                    size: 14,
                    weight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 56,
            height: 16,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 5: routine cards
// ---------------------------------------------------------------------------

class _RoutineCards extends StatelessWidget {
  const _RoutineCards({required this.morning, required this.evening});

  final String morning;
  final String evening;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 170,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.14,
            child: _RoutineCard(
              text: evening,
              background: palette.text,
              foreground: Colors.white,
            ),
          ),
          Transform.rotate(
            angle: -0.1,
            child: _RoutineCard(
              text: morning,
              background: palette.surface,
              foreground: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 120,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Text(text, style: AppFonts.manrope(size: 11, color: foreground)),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 6: lock
// ---------------------------------------------------------------------------

class _LockCircle extends StatelessWidget {
  const _LockCircle();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock_open_outlined,
          size: _lockIconSize,
          color: palette.accent,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header back arrow and asset pictures
// ---------------------------------------------------------------------------

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

/// A tutorial picture from the app's assets. If the file can't be loaded
/// (wrong path, or not listed in pubspec.yaml) the built-in drawing is
/// shown instead.
///
/// The height is a share of the screen height. Without [maxWidthFactor]
/// the picture is centred over the full width; with it, the width follows
/// the picture's proportions (up to that share of the screen width), so
/// the text next to it keeps as much room as possible.
class _AssetImage extends StatelessWidget {
  const _AssetImage({
    required this.path,
    required this.heightFactor,
    required this.fallback,
    this.maxWidthFactor,
  });

  final String path;
  final double heightFactor;
  final double? maxWidthFactor;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height * heightFactor;
    final maxFactor = maxWidthFactor;
    final image = Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          Align(widthFactor: 1, heightFactor: 1, child: fallback),
    );
    if (maxFactor == null) {
      return SizedBox(width: double.infinity, height: height, child: image);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: size.width * maxFactor),
      child: image,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../l10n/app_localizations.dart';
// import '../../models/onboarding/tutorial_page.dart';
// import '../../theme/app_fonts.dart';
// import '../../theme/app_palette.dart';
// import '../../widgets/auth/auth_widgets.dart';
// import '../../widgets/onboarding/onboarding_progress.dart';

// /// How the app works, as swipeable pages with a progress bar and one
// /// "Next" button (no skip).
// ///
// /// Two uses:
// /// - Onboarding step 3: the last button says "Start" and goes on to
// ///   cloud save.
// /// - Manual ([asManual]), opened from Profile: the last button says
// ///   "Done" and goes back to Profile. Login and settings are untouched.
// ///
// /// Placeholder content: change the pages in [_pages] (and their texts in
// /// the .arb files); the progress bar and buttons adapt.
// class TutorialScreen extends StatefulWidget {
//   const TutorialScreen({super.key, this.asManual = false});

//   /// True when opened from Profile instead of during onboarding.
//   final bool asManual;

//   @override
//   State<TutorialScreen> createState() => _TutorialScreenState();
// }

// class _TutorialScreenState extends State<TutorialScreen> {
//   final _pageController = PageController();
//   int _page = 0;

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   /// The pages, in the current language.
//   List<TutorialPage> _pages(AppLocalizations l10n) => [
//     TutorialPage(
//       icon: Icons.timer_outlined,
//       title: l10n.tutorialFocusTitle,
//       text: l10n.tutorialFocusText,
//     ),
//     TutorialPage(
//       icon: Icons.call_outlined,
//       title: l10n.tutorialReachableTitle,
//       text: l10n.tutorialReachableText,
//     ),
//     TutorialPage(
//       icon: Icons.wb_sunny_outlined,
//       title: l10n.tutorialRoutinesTitle,
//       text: l10n.tutorialRoutinesText,
//     ),
//     TutorialPage(
//       icon: Icons.lock_open_outlined,
//       title: l10n.tutorialControlTitle,
//       text: l10n.tutorialControlText,
//     ),
//   ];

//   void _goTo(int page) => _pageController.animateToPage(
//     page,
//     duration: const Duration(milliseconds: 300),
//     curve: Curves.easeOut,
//   );

//   void _next({required bool isLast}) {
//     if (!isLast) {
//       _goTo(_page + 1);
//     } else if (widget.asManual) {
//       _leave();
//     } else {
//       context.push('/onboarding/cloud');
//     }
//   }

//   /// Previous page; on the first page, leave the tutorial.
//   void _back() {
//     if (_page > 0) {
//       _goTo(_page - 1);
//     } else {
//       _leave();
//     }
//   }

//   /// Back to where the tutorial was opened from (Profile or Welcome).
//   void _leave() {
//     if (context.canPop()) {
//       context.pop();
//     } else {
//       context.go(widget.asManual ? '/profile' : '/welcome');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//     final pages = _pages(l10n);
//     final isLast = _page == pages.length - 1;
//     final lastLabel = widget.asManual ? l10n.tutorialDone : l10n.tutorialStart;

//     return PopScope(
//       // Android back gesture: previous page first, then leave the tutorial.
//       canPop: _page == 0,
//       onPopInvokedWithResult: (didPop, _) {
//         if (!didPop && _page > 0) _goTo(_page - 1);
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
//                     _RoundBackButton(onTap: _back, label: l10n.tutorialBack),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: OnboardingProgress(
//                         step: _page + 1,
//                         total: pages.length,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: PageView.builder(
//                     controller: _pageController,
//                     itemCount: pages.length,
//                     onPageChanged: (i) => setState(() => _page = i),
//                     itemBuilder: (context, i) =>
//                         _TutorialPageView(page: pages[i]),
//                   ),
//                 ),
//                 AuthPrimaryButton(
//                   label: isLast ? lastLabel : l10n.tutorialNext,
//                   onPressed: () => _next(isLast: isLast),
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

// /// One tutorial page: icon in a sand circle, title and text, centred.
// class _TutorialPageView extends StatelessWidget {
//   const _TutorialPageView({required this.page});

//   final TutorialPage page;

//   @override
//   Widget build(BuildContext context) {
//     final palette = context.palette;
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(vertical: 32),
//       child: Column(
//         children: [
//           const SizedBox(height: 24),
//           Container(
//             width: 132,
//             height: 132,
//             decoration: BoxDecoration(
//               color: palette.surface,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(page.icon, size: 56, color: palette.accent),
//           ),
//           const SizedBox(height: 40),
//           Text(
//             page.title,
//             textAlign: TextAlign.center,
//             style: AppFonts.cormorant(
//               size: 32,
//               weight: FontWeight.w600,
//               color: palette.text,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             page.text,
//             textAlign: TextAlign.center,
//             style: AppFonts.manrope(size: 15, color: palette.muted),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Looks like AuthBackButton, but goes to the previous tutorial page
// /// and has a translated screen-reader label.
// class _RoundBackButton extends StatelessWidget {
//   const _RoundBackButton({required this.onTap, required this.label});

//   final VoidCallback onTap;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     final palette = context.palette;
//     return Semantics(
//       button: true,
//       label: label,
//       child: InkWell(
//         customBorder: const CircleBorder(),
//         onTap: onTap,
//         child: Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: palette.border),
//           ),
//           child: Icon(Icons.arrow_back, size: 18, color: palette.text),
//         ),
//       ),
//     );
//   }
// }
