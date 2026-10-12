import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/focus_profile_meta.dart';
import '../services/profile_events.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../services/blocking_service.dart';
import '../services/session_store.dart';
import '../services/timer_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final blocker = AppBlocker.instance;
  List<BlockProfile> profiles = [];
  final _session = SessionStore();
  bool _timerOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    profilesChanged.addListener(_loadProfiles);
    _startup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profilesChanged.removeListener(_loadProfiles);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _openRunningSession();
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
    final target = await _runningProfile() ?? profile;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Text(
              'What do you want to focus on?',
              style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a focus profile to start your session',
              style: AppFonts.cormorant(size: 15, color: AppColors.lightbrown),
            ),
            const SizedBox(height: 24),
            for (final profile in profiles) _buildProfileCard(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BlockProfile profile) {
    final meta = metaFor(profile.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openTimer(profile),
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
                        '${profile.appIdentifiers.length} apps blocked',
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
}
