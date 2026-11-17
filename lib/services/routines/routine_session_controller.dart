import 'dart:async';
import 'dart:convert';

import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/routines/routine_step.dart';
import '../focus/blocking_service.dart';
import '../focus/session_store.dart';
import '../focus/timer_notification_service.dart';

/// Why [RoutineSessionController.startStep] did or didn't start.
enum RoutineStartResult { started, focusRunning, otherRoutineRunning }

/// "Morning" / "Evening".
String routineName(RoutinePeriod period) =>
    period == RoutinePeriod.morning ? 'Morning' : 'Evening';

/// The running morning or evening routine. App-wide, not owned by a screen,
/// so leaving the activity screen doesn't stop the timer or the blocking.
///
/// - Each step's timer is a saved end time (like the focus timer), so it
///   stays right when the app is closed.
/// - The period's apps (the 'morning' / 'evening' focus profile) are blocked
///   from the first started step until [blockedUntil]. Ticking every step
///   does NOT unblock early: the time after the routine is meant to be
///   phone-free. The plugin's Emergency Unlock is the way out.
/// - [blockedUntil] = now + minutes of the open steps + [graceMinutes].
///   It's recalculated on every started step and only ever moves later.
///
/// Saved under its own key, never in the focus [SessionStore].
class RoutineSessionController extends ChangeNotifier {
  RoutineSessionController._();
  static final instance = RoutineSessionController._();

  /// Extra phone-free time after the routine.
  static const graceMinutes = 30;
  static const _storeKey = 'routineSession';

  final _blocking = BlockingService();
  final _alerts = TimerNotificationService.instance;

  // ---------- saved state ----------
  RoutinePeriod? _period;
  int _blockedUntil = 0;
  bool _isBlocking = false;
  String? _activeStep;
  int _stepTotal = 0;
  int _stepEndAt = 0;
  int? _pausedLeft;

  // ---------- in memory only ----------
  bool _triedBlocking = false;
  bool _timeUpHandled = false;
  bool _finishing = false;
  Timer? _endTimer;
  AppLifecycleListener? _lifecycle;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ------------------------------------------------------------------
  // What screens read
  // ------------------------------------------------------------------

  /// True from the first started step until [blockedUntil].
  bool get isActive => _period != null && _blockedUntil > _now;

  RoutinePeriod? get period => isActive ? _period : null;
  bool isRunningFor(RoutinePeriod period) => isActive && _period == period;

  /// True when the period's apps are actually blocked (permission given).
  bool get isBlockingApps => isActive && _isBlocking;

  DateTime? get blockedUntil =>
      isActive ? DateTime.fromMillisecondsSinceEpoch(_blockedUntil) : null;

  /// Title of the step whose timer runs (or is paused), if any.
  String? get activeStep => isActive ? _activeStep : null;

  bool get isPaused => _pausedLeft != null;
  int get stepTotalMillis => _stepTotal;

  int get stepRemainingMillis {
    if (_activeStep == null) return 0;
    final left = _pausedLeft ?? (_stepEndAt - _now);
    return left.clamp(0, _stepTotal).toInt();
  }

  // ------------------------------------------------------------------
  // Start-up
  // ------------------------------------------------------------------

  /// Call once in main(). Loads the saved routine and cleans up if its
  /// time is over. Runs again by itself whenever the app comes back.
  Future<void> restore() async {
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(restore()));
    await _load();
    if (_period != null && _blockedUntil <= _now) {
      await _finish();
      return;
    }
    _scheduleEnd();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  /// Starts (or continues) [step]. The first step of a routine also starts
  /// blocking the period's apps; asks for permission if needed.
  /// Opening the step that's already running keeps its timer as it is.
  Future<RoutineStartResult> startStep(
    BuildContext context, {
    required RoutinePeriod period,
    required String step,
    required int stepMinutes,
    required int openMinutes,
  }) async {
    if (isActive && _period != period) {
      return RoutineStartResult.otherRoutineRunning;
    }
    if (!isActive && await _focusRunning()) {
      return RoutineStartResult.focusRunning;
    }

    final wasActive = isActive;
    if (!wasActive) {
      _clearState();
      _period = period;
    }

    // Only ever later: a slow routine never gets cut off mid-step.
    final until = _now + (openMinutes + graceMinutes) * 60000;
    if (until > _blockedUntil) _blockedUntil = until;

    if (_activeStep != step) {
      _activeStep = step;
      _stepTotal = stepMinutes * 60000;
      _stepEndAt = _now + _stepTotal;
      _pausedLeft = null;
      _timeUpHandled = false;
    }

    if (!_isBlocking && !_triedBlocking) {
      _triedBlocking = true;
      if (context.mounted) _isBlocking = await _startBlocking(context, period);
    } else if (_isBlocking) {
      await _updateBlockScreen(); // the "until" time may have moved
    }

    await _save();
    _scheduleEnd();
    await _updateAlerts();
    notifyListeners();
    return RoutineStartResult.started;
  }

  Future<void> pauseStep() async {
    if (_activeStep == null || isPaused) return;
    _pausedLeft = stepRemainingMillis;
    await _save();
    await _updateAlerts();
    notifyListeners();
  }

  Future<void> resumeStep() async {
    final left = _pausedLeft;
    if (_activeStep == null || left == null) return;
    _stepEndAt = _now + left;
    _pausedLeft = null;
    _timeUpHandled = false;
    // A long pause can't let the blocking end before this step does.
    final minUntil = _stepEndAt + graceMinutes * 60000;
    if (minUntil > _blockedUntil) {
      _blockedUntil = minUntil;
      if (_isBlocking) await _updateBlockScreen();
      _scheduleEnd();
    }
    await _save();
    await _updateAlerts();
    notifyListeners();
  }

  /// The step was ticked off. Blocking keeps going until [blockedUntil].
  Future<void> completeStep(String step) async {
    if (_activeStep != step) return;
    _activeStep = null;
    _stepTotal = 0;
    _stepEndAt = 0;
    _pausedLeft = null;
    await _save();
    await _updateAlerts();
    notifyListeners();
  }

  /// Called by open screens a few times per second: notices "time's up"
  /// and the end of the routine.
  void tick() {
    if (_period == null) return;
    if (_blockedUntil <= _now) {
      unawaited(_finish());
      return;
    }
    if (_activeStep != null &&
        !isPaused &&
        _stepEndAt <= _now &&
        !_timeUpHandled) {
      _timeUpHandled = true;
      unawaited(_updateAlerts());
      notifyListeners();
    }
  }

  @visibleForTesting
  void resetForTest() {
    _endTimer?.cancel();
    _clearState();
  }

  // ------------------------------------------------------------------
  // Blocking
  // ------------------------------------------------------------------

  Future<bool> _startBlocking(
    BuildContext context,
    RoutinePeriod period,
  ) async {
    try {
      if (!await _blocking.ensurePermission(context)) return false;

      // An old, finished focus session would otherwise unblock us later.
      final focus = SessionStore();
      if (await focus.hasExpired()) await focus.clear();

      BlockProfile? profile;
      for (final p in await AppBlocker.instance.getProfiles()) {
        if (p.id == period.name) profile = p;
      }
      if (profile == null) return false;

      await _blocking.startBlocking(
        profile,
        subtitle: _blockScreenText(period),
        timerLabel: '',
      );
      return true;
    } catch (error) {
      debugPrint('Starting routine blocking failed: $error');
      return false;
    }
  }

  Future<void> _updateBlockScreen() async {
    final period = _period;
    if (period == null) return;
    try {
      await _blocking.updateBlockScreen(
        subtitle: _blockScreenText(period),
        timerLabel: '',
      );
    } catch (error) {
      debugPrint('Updating the block screen failed: $error');
    }
  }

  /// Unblocks at [blockedUntil] while the app is running.
  /// (When it isn't, restore() does it the next time the app opens.)
  void _scheduleEnd() {
    _endTimer?.cancel();
    if (!_isBlocking || _period == null) return;
    final wait = _blockedUntil - _now;
    if (wait <= 0) return;
    _endTimer = Timer(Duration(milliseconds: wait), () => unawaited(_finish()));
  }

  /// The routine's time is over: unblock, remove the notification, forget it.
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    try {
      _endTimer?.cancel();
      // Never unblock a focus session's apps (shouldn't overlap, but be safe).
      if (_isBlocking && !await _focusRunning()) {
        try {
          await _blocking.unblockApps();
        } catch (error) {
          debugPrint('Unblocking after the routine failed: $error');
        }
      }
      await _alerts.cancelRoutine();
      _clearState();
      await _save();
      notifyListeners();
    } finally {
      _finishing = false;
    }
  }

  // ------------------------------------------------------------------
  // Notification
  // ------------------------------------------------------------------

  /// Step running: count down the step. Otherwise: count down to the end
  /// of the blocking, with what's going on as the subtitle.
  Future<void> _updateAlerts() async {
    final period = _period;
    if (period == null || !isActive) {
      await _alerts.cancelRoutine();
      return;
    }
    final title = '${routineName(period)} routine';
    final step = _activeStep;
    final stepRunning = step != null && !isPaused && _stepEndAt > _now;

    if (stepRunning) {
      final end = DateTime.fromMillisecondsSinceEpoch(_stepEndAt);
      await _alerts.showRoutine(until: end, title: title, subtitle: step);
      await _alerts.scheduleRoutineStepEnd(end, step);
    } else {
      await _alerts.cancelRoutineStepEnd();
      final parts = <String>[
        if (step != null && isPaused) '$step paused',
        if (step != null && !isPaused) "$step: time's up",
        if (_isBlocking) 'apps blocked until ${_clock(_blockedUntil)}',
      ];
      final subtitle = parts.isEmpty ? 'In progress' : parts.join(' · ');
      await _alerts.showRoutine(
        until: DateTime.fromMillisecondsSinceEpoch(_blockedUntil),
        title: title,
        subtitle: subtitle[0].toUpperCase() + subtitle.substring(1),
        showTimer: false,
      );
    }

    if (_isBlocking) {
      await _alerts.scheduleRoutineUnblock(
        DateTime.fromMillisecondsSinceEpoch(_blockedUntil),
        title,
      );
    }
  }

  // ------------------------------------------------------------------
  // Helpers and saving
  // ------------------------------------------------------------------

  Future<bool> _focusRunning() async {
    try {
      return await SessionStore().isActive();
    } catch (_) {
      return false;
    }
  }

  /// "08:15".
  /// "7:13 PM" or "19:13", following the phone's 12/24-hour setting.
  String _clock(int millis) {
    final time = DateTime.fromMillisecondsSinceEpoch(millis);
    final m = time.minute.toString().padLeft(2, '0');
    if (WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:$m';
    }
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$h:$m ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Block screen subtitle; the plugin's own timer line stays empty
  /// because it only knows focus sessions.
  String _blockScreenText(RoutinePeriod period) =>
      '${routineName(period)} routine · apps blocked until '
      '${_clock(_blockedUntil)}';

  void _clearState() {
    _period = null;
    _blockedUntil = 0;
    _isBlocking = false;
    _activeStep = null;
    _stepTotal = 0;
    _stepEndAt = 0;
    _pausedLeft = null;
    _triedBlocking = false;
    _timeUpHandled = false;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_period == null) {
        await prefs.remove(_storeKey);
        return;
      }
      await prefs.setString(
        _storeKey,
        jsonEncode({
          'period': _period!.name,
          'blockedUntil': _blockedUntil,
          'blocking': _isBlocking,
          'step': _activeStep,
          'stepTotal': _stepTotal,
          'stepEndAt': _stepEndAt,
          'pausedLeft': _pausedLeft,
        }),
      );
    } catch (error) {
      debugPrint('Saving the routine failed: $error');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_storeKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _period = null;
      for (final p in RoutinePeriod.values) {
        if (p.name == json['period']) _period = p;
      }
      _blockedUntil = json['blockedUntil'] as int? ?? 0;
      _isBlocking = json['blocking'] as bool? ?? false;
      _activeStep = json['step'] as String?;
      _stepTotal = json['stepTotal'] as int? ?? 0;
      _stepEndAt = json['stepEndAt'] as int? ?? 0;
      _pausedLeft = json['pausedLeft'] as int?;
      _triedBlocking = true; // don't ask for permission again mid-routine
    } catch (error) {
      debugPrint('Loading the routine failed: $error');
    }
  }
}
