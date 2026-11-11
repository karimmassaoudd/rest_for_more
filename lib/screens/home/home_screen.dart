import 'package:app_blocker/app_blocker.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/focus/focus_profile_meta.dart';
import '../../models/home/home_card.dart';
import '../../services/auth/auth_service.dart';
import '../../services/focus/blocking_service.dart';
import '../../services/focus/profile_events.dart';
import '../../services/focus/session_store.dart';
import '../../services/focus/timer_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/common/rfm_logo.dart';
import '../../widgets/focus/permission_banner.dart';
import '../../widgets/home/home_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final blocker = AppBlocker.instance;
  List<BlockProfile> profiles = [];

  /// Profiles shown in the list. Morning and evening are already in the carousel.
  List<BlockProfile> get _listedProfiles =>
      profiles.where((p) => p.id != 'morning' && p.id != 'evening').toList();

  final _session = SessionStore();
  bool _timerOpen = false;
  bool _permissionMissing = false;

  /// First name from the Clerk account; null for guests, offline, or no name set.
  String? _firstName;
  ClerkAuthState? _auth;

  /// Used by the "Start a rest" card to scroll down to the profiles.
  final _profilesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    profilesChanged.addListener(_loadProfiles);
    _startup();
    _loadName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profilesChanged.removeListener(_loadProfiles);
    _auth?.removeListener(_updateName);
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Name in the header (never blocks the screen; works offline)
  // ------------------------------------------------------------------

  Future<void> _loadName() async {
    try {
      final auth = await AuthService.instance.state.timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      _auth = auth
        ..addListener(_updateName); // also updates on log in / log out
      _updateName();
    } catch (_) {
      // Offline or Clerk not started: the header just shows the greeting.
    }
  }

  void _updateName() {
    if (!mounted) return;
    final name = _auth?.user?.firstName?.trim();
    setState(() => _firstName = (name == null || name.isEmpty) ? null : name);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  // ------------------------------------------------------------------
  // Carousel
  // ------------------------------------------------------------------

  void _scrollToProfiles() {
    final target = _profilesKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  /// Morning card in the morning, evening card in the evening, otherwise the first.
  int _cardForNow() {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour < 9) return 1; // 07:00–08:59 → Morning
    if (hour >= 20 && hour < 21) return 2; // 20:00–20:59 → Evening
    return 0; // rest of the day → "Start a rest"
  }

  List<HomeCard> _carouselCards() => [
    HomeCard(
      icon: Icons.self_improvement_rounded,
      iconColor: AppColors.yellowhighlight,
      eyebrow: 'Ready for a quiet moment?',
      title: 'Put your phone down and focus on whats important.',
      buttonLabel: 'Start focusing',
      onPressed: _scrollToProfiles,
    ),
    HomeCard(
      icon: Icons.wb_twilight_rounded,
      iconColor: AppColors.yellowhighlight,
      eyebrow: 'Ready to start the day?',
      title: 'Good morning, start the day by being productive.',
      buttonLabel: 'Start Morning Routine',
      buttonColor: AppColors.yellowhighlight,
      buttonTextColor: AppColors.darkbrown,
      onPressed: () => context.push('/routine/morning'),
    ),
    HomeCard(
      icon: Icons.nights_stay_rounded,
      iconColor: AppColors.background,
      eyebrow: 'Ready to end the day?',
      title: 'Good evening, end the day on a good note.',
      buttonLabel: 'Start Evening Routine',
      background: AppColors.darkbrown,
      textColor: AppColors.background,
      buttonColor: AppColors.background,
      buttonTextColor: AppColors.mediumbrown,
      buttonBorder: AppColors.lightbrown,
      onPressed: () => context.push('/routine/evening'),
    ),
    HomeCard(
      icon: Icons.today_rounded,
      iconColor: AppColors.background,
      eyebrow: 'Don’t have a routine yet?',
      title: 'Start your 14-day plan, made to fit your day.',
      buttonLabel: 'Answer a few questions',
      background: AppColors.lightbrown,
      textColor: AppColors.background,
      buttonColor: AppColors.background,
      buttonTextColor: AppColors.mediumbrown,
      buttonBorder: AppColors.lightbrown,
      onPressed: () => context.push('/programme/intake'),
    ),
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openRunningSession();
      _refreshPermission();
    }
  }

  /// The profile of the running session, or null if none is running.
  Future<BlockProfile?> _runningProfile() async {
    if (!await _session.isActive()) return null;
    final id = await _session.profileId();
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// One place that opens the timer, so it can never open twice.
  /// If a session is already running, that session's timer opens instead.
  Future<void> _openTimer(BlockProfile profile) async {
    if (_timerOpen) return;
    _timerOpen = true;
    final running = await _runningProfile();
    if (running != null && running.id != profile.id && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${running.name} is already running. End it to start another.',
            ),
          ),
        );
    }
    final target = running ?? profile;

    if (!mounted) {
      _timerOpen = false;
      return;
    }
    await context.push('/countdown', extra: target);
    _timerOpen = false;
  }

  /// If a session is running, go straight to its timer.
  Future<bool> _openRunningSession() async {
    final running = await _runningProfile();
    if (running == null || !mounted) return false;
    _openTimer(running);
    return true;
  }

  Future<void> _startup() async {
    await _loadProfiles();
    if (!mounted) return;
    if (await _openRunningSession()) return;
    await _checkPermissions();
    _refreshPermission();
  }

  /// Asks for missing permissions when the app opens.
  Future<void> _checkPermissions() async {
    final alerts = TimerNotificationService.instance;
    if (!await alerts.hasPermission()) {
      await alerts.requestPermission();
    }
    if (!mounted) return;
    await BlockingService().ensurePermission(context);
  }

  Future<void> _loadProfiles() async {
    try {
      final fetched = await blocker.getProfiles();
      if (!mounted) return;
      setState(() => profiles = fetched);
    } catch (error) {
      debugPrint('Loading profiles failed: $error');
    }
  }

  Future<void> _refreshPermission() async {
    try {
      final status = await blocker.checkPermission();
      if (!mounted) return;
      setState(
        () => _permissionMissing = status != BlockerPermissionStatus.granted,
      );
    } catch (error) {
      debugPrint('Checking permission failed: $error');
    }
  }

  Future<void> _fixPermission() async {
    await BlockingService().ensurePermission(context);
    await _refreshPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // child: ListView(
        //   padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_permissionMissing) PermissionBanner(onTap: _fixPermission),
            HomeCarousel(cards: _carouselCards(), initialIndex: _cardForNow()),
            const SizedBox(height: 28),
            Text(
              'What do you want to focus on?',
              key: _profilesKey,
              style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            for (final profile in _listedProfiles) _buildProfileCard(profile),
            //_buildProfileGrid(),
          ],
        ),
      ),
    );
  }

  /// "GOOD MORNING" + name on the left, RFM logo on the right.
  /// Without a name, the greeting itself is the big title.
  Widget _buildHeader() {
    final greeting = _greeting();
    final name = _firstName;
    final titleStyle = AppFonts.cormorant(size: 34, weight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null) ...[
                Text(
                  greeting.toUpperCase(),
                  style: AppFonts.montserrat(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.mediumbrown,
                  ).copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(name, style: titleStyle),
              ] else
                Text(greeting, style: titleStyle),
            ],
          ),
        ),
        const RfmLogo(textColor: AppColors.lightbrown),
      ],
    );
  }

  void _onProfileTap(BlockProfile profile) {
    switch (profile.id) {
      case 'morning':
        context.push('/routine/morning');
      case 'evening':
        context.push('/routine/evening');
      default:
        _openTimer(profile);
    }
  }

  String _subtitleFor(BlockProfile profile) => switch (profile.id) {
    'morning' => 'Morning routine',
    'evening' => 'Evening routine',
    _ => '${profile.appIdentifiers.length} apps blocked',
  };

  Widget _buildProfileCard(BlockProfile profile) {
    final meta = metaFor(profile.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onProfileTap(profile),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(meta.icon, size: 32, color: AppColors.mediumbrown),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: AppFonts.manrope(
                          size: 18,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _subtitleFor(profile),
                        style: AppFonts.manrope(
                          size: 13,
                          color: AppColors.lightbrown,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mediumbrown),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Profiles as a 2-column grid. It doesn't scroll by itself: the page does.
  // Widget _buildProfileGrid() {
  //   final shown = _listedProfiles; // or `profiles` if you didn't add the filter
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     padding: EdgeInsets.zero,
  //     itemCount: shown.length,
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 12,
  //       mainAxisSpacing: 12,
  //       mainAxisExtent: 100, // height of each card
  //     ),
  //     itemBuilder: (context, i) => _buildProfileCard(shown[i]),
  //   );
  // }

  // Widget _buildProfileCard(BlockProfile profile) {
  //   final meta = metaFor(profile.id);

  //   return Material(
  //     color: AppColors.surface,
  //     borderRadius: BorderRadius.circular(16),
  //     elevation: 1,
  //     shadowColor: AppColors.darkbrown.withValues(alpha: 0.25),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(16),
  //       onTap: () => _onProfileTap(profile),
  //       child: Padding(
  //         padding: const EdgeInsets.all(20),
  //         child: Center(
  //           child: IntrinsicWidth(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.start,
  //                   children: [
  //                     Icon(meta.icon, size: 24, color: AppColors.mediumbrown),
  //                     const SizedBox(width: 10),
  //                     Flexible(
  //                       child: Text(
  //                         profile.name,
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                         style: AppFonts.manrope(
  //                           size: 18,
  //                           weight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   _subtitleFor(profile),
  //                   textAlign: TextAlign.center,
  //                   style: AppFonts.manrope(
  //                     size: 13,
  //                     color: AppColors.lightbrown,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

// import 'package:app_blocker/app_blocker.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../models/focus/focus_profile_meta.dart';
// import '../../services/focus/profile_events.dart';
// import '../../theme/app_colors.dart';
// import '../../theme/app_fonts.dart';
// import '../../services/focus/blocking_service.dart';
// import '../../services/focus/session_store.dart';
// import '../../services/focus/timer_notification_service.dart';
// import '../../widgets/focus/permission_banner.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
//   final blocker = AppBlocker.instance;
//   List<BlockProfile> profiles = [];
//   final _session = SessionStore();
//   bool _timerOpen = false;
//   bool _permissionMissing = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     profilesChanged.addListener(_loadProfiles);
//     _startup();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     profilesChanged.removeListener(_loadProfiles);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _openRunningSession();
//       _refreshPermission();
//     }
//   }

//   /// The profile of the running session, or null if none is running.
//   Future<BlockProfile?> _runningProfile() async {
//     if (!await _session.isActive()) return null;
//     final id = await _session.profileId();
//     for (final p in profiles) {
//       if (p.id == id) return p;
//     }
//     return null;
//   }

//   /// One place that opens the timer, so it can never open twice.
//   /// If a session is already running, that session's timer opens instead.
//   Future<void> _openTimer(BlockProfile profile) async {
//     if (_timerOpen) return;
//     _timerOpen = true;
//     final running = await _runningProfile();
//     if (running != null && running.id != profile.id && mounted) {
//       ScaffoldMessenger.of(context)
//         ..hideCurrentSnackBar()
//         ..showSnackBar(
//           SnackBar(
//             content: Text(
//               '${running.name} is already running. End it to start another.',
//             ),
//           ),
//         );
//     }
//     final target = running ?? profile;

//     if (!mounted) {
//       _timerOpen = false;
//       return;
//     }
//     await context.push('/countdown', extra: target);
//     _timerOpen = false;
//   }

//   /// If a session is running, go straight to its timer.
//   Future<bool> _openRunningSession() async {
//     final running = await _runningProfile();
//     if (running == null || !mounted) return false;
//     _openTimer(running);
//     return true;
//   }

//   Future<void> _startup() async {
//     await _loadProfiles();
//     if (!mounted) return;
//     if (await _openRunningSession()) return;
//     await _checkPermissions();
//     _refreshPermission();
//   }

//   /// Asks for missing permissions when the app opens.
//   Future<void> _checkPermissions() async {
//     final alerts = TimerNotificationService.instance;
//     if (!await alerts.hasPermission()) {
//       await alerts.requestPermission();
//     }
//     if (!mounted) return;
//     await BlockingService().ensurePermission(context);
//   }

//   Future<void> _loadProfiles() async {
//     try {
//       final fetched = await blocker.getProfiles();
//       if (!mounted) return;
//       setState(() => profiles = fetched);
//     } catch (error) {
//       debugPrint('Loading profiles failed: $error');
//     }
//   }

//   Future<void> _refreshPermission() async {
//     try {
//       final status = await blocker.checkPermission();
//       if (!mounted) return;
//       setState(
//         () => _permissionMissing = status != BlockerPermissionStatus.granted,
//       );
//     } catch (error) {
//       debugPrint('Checking permission failed: $error');
//     }
//   }

//   Future<void> _fixPermission() async {
//     await BlockingService().ensurePermission(context);
//     await _refreshPermission();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
//           children: [
//             if (_permissionMissing) PermissionBanner(onTap: _fixPermission),
//             Text(
//               'What do you want to focus on?',
//               style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Choose a focus profile to start your session',
//               style: AppFonts.cormorant(size: 15, color: AppColors.lightbrown),
//             ),
//             const SizedBox(height: 24),

//             for (final profile in profiles) _buildProfileCard(profile),
//           ],
//         ),
//       ),
//     );
//   }

//   void _onProfileTap(BlockProfile profile) {
//     switch (profile.id) {
//       case 'morning':
//         context.push('/routine/morning');
//       case 'evening':
//         context.push('/routine/evening');
//       default:
//         _openTimer(profile);
//     }
//   }

//   String _subtitleFor(BlockProfile profile) => switch (profile.id) {
//     'morning' => 'Morning routine',
//     'evening' => 'Evening routine',
//     _ => '${profile.appIdentifiers.length} apps blocked',
//   };

//   Widget _buildProfileCard(BlockProfile profile) {
//     final meta = metaFor(profile.id);

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () => _onProfileTap(profile),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Icon(meta.icon, size: 32, color: AppColors.mediumbrown),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         profile.name,
//                         style: AppFonts.manrope(
//                           size: 18,
//                           weight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         _subtitleFor(profile),
//                         style: AppFonts.manrope(
//                           size: 13,
//                           color: AppColors.lightbrown,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.chevron_right, color: AppColors.mediumbrown),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
