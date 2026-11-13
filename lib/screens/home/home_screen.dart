import 'package:app_blocker/app_blocker.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth/auth_service.dart';
import '../../services/focus/blocking_service.dart';
import '../../services/focus/profile_events.dart';
import '../../services/focus/session_store.dart';
import '../../services/focus/timer_notification_service.dart';
import '../../theme/app_fonts.dart';

import '../../widgets/focus/permission_banner.dart';
import '../../widgets/home/focus_profile_tile.dart';
import '../../widgets/home/home_carousel.dart';
import '../../widgets/home/home_carousel_cards.dart';
import '../../widgets/home/home_header.dart';

/// The "Today" tab: greeting, routine carousel and the list of focus profiles.
///
/// On open (and whenever the app comes back to the foreground) it:
/// - jumps straight to the timer if a focus session is still running;
/// - otherwise asks for missing notification / app-blocking permissions
///   and shows a banner while app blocking is still off.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final blocker = AppBlocker.instance;
  final _blocking = BlockingService();
  final _session = SessionStore();

  List<BlockProfile> profiles = [];

  /// Guards [_openTimer] so the countdown screen can never be pushed twice.
  bool _timerOpen = false;

  /// True after the app really went to the background (not just the
  /// notification shade), so coming back can reopen the running timer.
  bool _wasInBackground = false;

  bool _permissionMissing = false;

  /// First name from the Clerk account; null for guests, offline, or no name set.
  String? _firstName;
  ClerkAuthState? _auth;

  /// Lets the "Start focusing" card scroll down to the profile list.
  final _profilesKey = GlobalKey();

  /// Profiles shown in the list. Morning and evening live in the carousel instead.
  List<BlockProfile> get _listedProfiles =>
      profiles.where((p) => p.id != 'morning' && p.id != 'evening').toList();

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    _refreshPermission();
    // Only jump to the timer after a real trip out of the app, and only
    // when Home is what the user is looking at.
    if (_wasInBackground && _isOnHome()) _openRunningSession();
    _wasInBackground = false;
  }

  /// True when the visible page is the Home tab itself.
  bool _isOnHome() =>
      GoRouter.of(context).routerDelegate.currentConfiguration.uri.path == '/';

  /// First load: profiles → running session → permissions.
  Future<void> _startup() async {
    await _loadProfiles();
    if (!mounted) return;
    if (await _openRunningSession()) return;
    await _checkPermissions();
    _refreshPermission();
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

  // ------------------------------------------------------------------
  // Name in the header (never blocks the screen; works offline)
  // ------------------------------------------------------------------

  Future<void> _loadName() async {
    try {
      final auth = await AuthService.instance.state.timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      // Listen so the name also updates on log in / log out.
      _auth = auth..addListener(_updateName);
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

  // ------------------------------------------------------------------
  // Focus sessions
  // ------------------------------------------------------------------

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

    if (!mounted) {
      _timerOpen = false;
      return;
    }
    await context.push('/countdown', extra: running ?? profile);
    _timerOpen = false;
  }

  /// If a session is running, go straight to its timer.
  /// Returns true when the timer was opened.
  Future<bool> _openRunningSession() async {
    final running = await _runningProfile();
    if (running == null || !mounted) return false;
    _openTimer(running);
    return true;
  }

  void _scrollToProfiles() {
    final target = _profilesKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  // ------------------------------------------------------------------
  // Permissions
  // ------------------------------------------------------------------

  /// Asks for missing notification and app-blocking permissions on start-up.
  Future<void> _checkPermissions() async {
    final alerts = TimerNotificationService.instance;
    if (!await alerts.hasPermission()) {
      await alerts.requestPermission();
    }
    if (!mounted) return;
    await _blocking.ensurePermission(context);
  }

  /// Shows or hides the "App blocking is off" banner.
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

  /// Called from the banner to fix missing app-blocking permission.
  Future<void> _fixPermission() async {
    await _blocking.ensurePermission(context);
    await _refreshPermission();
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            HomeHeader(firstName: _firstName),
            const SizedBox(height: 24),
            if (_permissionMissing) PermissionBanner(onTap: _fixPermission),

            HomeCarousel(
              cards: buildHomeCarouselCards(
                context: context,
                onStartFocus: _scrollToProfiles,
                onMorningRoutine: () => context.push('/routine/morning'),
                onEveningRoutine: () => context.push('/routine/evening'),
                onStartPlan: () => context.push('/programme/intake'),
              ),
              initialIndex: homeCarouselIndexFor(now),
            ),

            const SizedBox(height: 28),
            Text(
              'What do you want to focus on?',
              key: _profilesKey,
              style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            for (final profile in _listedProfiles)
              FocusProfileTile(
                profile: profile,
                onTap: () => _openTimer(profile),
              ),
          ],
        ),
      ),
    );
  }
}
