import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/routines/default_routine_steps.dart';
import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_progress_storage.dart';
import '../../services/routines/routine_session_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/common/rfm_app_bar.dart';
import '../../widgets/routines/active_routine_card.dart';
import '../../widgets/routines/blocked_until_note.dart';
import '../../widgets/routines/bottom_action_dock.dart';
import '../../widgets/routines/completion_banner.dart';
import '../../widgets/routines/routine_item_card.dart';
import '../../widgets/routines/steps_heading.dart';
import 'routine_flow_screen.dart';
import 'routine_history_debug_screen.dart';

/// The morning or evening routine (view only): progress, the list of
/// steps, and a button that opens the activity screen at the first open activity.
///
/// The period comes from the route (/routine?period=morning|evening).
/// Ticked-off steps are saved per period, so they survive a restart.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({
    super.key,
    required this.period,
    this.openActiveStep = false,
    this.progressStorage = const RoutineProgressStorage(),
  });

  final RoutinePeriod period;

  /// Opened from the routine notification: go straight to the running step.
  final bool openActiveStep;

  /// Replaceable in tests.
  final RoutineProgressStorage progressStorage;

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  // Both periods are loaded because saveToday() writes both into history.
  List<RoutineStep> _morningSteps = defaultMorningSteps;
  List<RoutineStep> _eveningSteps = defaultEveningSteps;

  bool get _isMorning => widget.period == RoutinePeriod.morning;
  List<RoutineStep> get _steps => _isMorning ? _morningSteps : _eveningSteps;
  int get _completed => _steps.where((step) => step.isCompleted).length;
  int get _remaining => _steps.length - _completed;

  void _setSteps(List<RoutineStep> steps) {
    if (_isMorning) {
      _morningSteps = steps;
    } else {
      _eveningSteps = steps;
    }
  }

  // ------------------------------------------------------------------
  // Loading and saving progress
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    unawaited(_loadProgress().then((_) => _maybeOpenActiveStep()));
  }

  /// From the notification: open the step whose timer is running.
  void _maybeOpenActiveStep() {
    if (!widget.openActiveStep || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final active = RoutineSessionController.instance.activeStep;
      final index = _steps.indexWhere((step) => step.title == active);
      unawaited(index == -1 ? _openFlow() : _openStep(index));
    });
  }

  /// Loads today's ticks. When a new routine day has started (from 04:00)
  /// the ticks start empty; the previous day is already in the history.
  /// Never while a routine is running, so nothing clears mid-routine.
  Future<void> _loadProgress() async {
    try {
      final storage = widget.progressStorage;
      final today = storage.progressDay(DateTime.now());
      if (await storage.savedDay() != today &&
          !RoutineSessionController.instance.isActive) {
        await storage.clearTicks();
      }
      final results = await Future.wait([
        storage.loadCompletedTasks(RoutinePeriod.morning),
        storage.loadCompletedTasks(RoutinePeriod.evening),
      ]);
      if (!mounted) return;
      setState(() {
        _morningSteps = _applySavedProgress(_morningSteps, results[0]);
        _eveningSteps = _applySavedProgress(_eveningSteps, results[1]);
      });
      RoutineSessionController.instance.reportStepsLeft(
        widget.period,
        _remaining,
      );
    } catch (_) {
      // Keep the in-memory defaults if local storage is unavailable.
    }
  }

  /// Ticks exactly the steps whose title was saved as completed.
  List<RoutineStep> _applySavedProgress(
    List<RoutineStep> steps,
    Set<String>? completedTitles,
  ) {
    if (completedTitles == null) return steps;
    return steps
        .map(
          (step) =>
              step.copyWith(isCompleted: completedTitles.contains(step.title)),
        )
        .toList();
  }

  /// Saves this period's ticks and today's history record.
  Future<void> _saveProgress() async {
    // Home shows "Morning routine done" when nothing is left.
    RoutineSessionController.instance.reportStepsLeft(
      widget.period,
      _remaining,
    );
    await widget.progressStorage.saveCompletedTasks(widget.period, _steps);
    await widget.progressStorage.saveToday(
      morningSteps: _morningSteps,
      eveningSteps: _eveningSteps,
    );
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  /// Swipe on a step: tick it, or untick it when it's already done.
  /// Ticking shows an "Undo" snackbar.
  void _toggleStep(int index, {bool offerUndo = true}) {
    final step = _steps[index];
    final nowCompleted = !step.isCompleted;
    final updated = List<RoutineStep>.of(_steps);
    updated[index] = step.copyWith(isCompleted: nowCompleted);
    setState(() => _setSteps(updated));
    unawaited(_saveWithFeedback());

    // Ticked the step whose timer runs: stop its timer (blocking continues).
    if (nowCompleted) {
      unawaited(RoutineSessionController.instance.completeStep(step.title));
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (nowCompleted && offerUndo) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${step.title} done'),
          // Has an action, so Flutter would keep it open until tapped.
          persist: false,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (mounted) _toggleStep(index, offerUndo: false);
            },
          ),
        ),
      );
    }
  }

  Future<void> _saveWithFeedback() async {
    try {
      await _saveProgress();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save routine progress.')),
      );
    }
  }

  /// Tap on a step: open that step's activity. Doesn't tick it.
  Future<void> _openStep(int index) => _openFlow(initialIndex: index);

  /// The button at the bottom: opens the first open step.
  Future<void> _startRoutineFlow() async {
    if (!_steps.any((step) => !step.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your ${routineName(widget.period).toLowerCase()} routine is complete.',
          ),
        ),
      );
      return;
    }
    await _openFlow();
  }

  Future<void> _openFlow({int? initialIndex}) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RoutineFlowScreen(
          period: widget.period,
          steps: _steps,
          initialIndex: initialIndex,
          onStepCompleted: (index) => _setCompletedAndSave(index, true),
          onStepReopened: (index) => _setCompletedAndSave(index, false),
        ),
      ),
    );
  }

  /// Called by the activity screen; it only moves on after this succeeds.
  Future<void> _setCompletedAndSave(int index, bool completed) async {
    final original = _steps;
    if (index < 0 ||
        index >= original.length ||
        original[index].isCompleted == completed) {
      return;
    }
    final updated = List<RoutineStep>.of(original);
    updated[index] = updated[index].copyWith(isCompleted: completed);
    _setSteps(updated);
    if (mounted) setState(() {});
    try {
      await _saveProgress();
    } catch (_) {
      _setSteps(original);
      if (mounted) setState(() {});
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.of(context);
    final activeIndex = _steps.indexWhere((step) => !step.isCompleted);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            RfmAppBar(title: _isMorning ? 'Morning' : 'Evening'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntro(palette),
                        const SizedBox(height: 20),
                        ActiveRoutineCard(
                          palette: palette,
                          completed: _completed,
                          total: _steps.length,
                        ),
                        const SizedBox(height: 12),
                        BlockedUntilNote(period: widget.period),
                        const SizedBox(height: 14),
                        StepsHeading(remaining: _remaining, palette: palette),
                        const SizedBox(height: 12),
                        for (var index = 0; index < _steps.length; index++)
                          RoutineItemCard(
                            step: _steps[index],
                            index: index,
                            isActive: index == activeIndex,
                            period: widget.period,
                            palette: palette,
                            onOpen: () => _openStep(index),
                            onToggle: () => _toggleStep(index),
                          ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _remaining == 0
                              ? CompletionBanner(
                                  key: ValueKey(
                                    'complete-${widget.period.name}',
                                  ),
                                  period: widget.period,
                                  palette: palette,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 10),
                        if (_remaining > 0)
                          ListenableBuilder(
                            listenable: RoutineSessionController.instance,
                            builder: (context, _) => BottomActionDock(
                              period: widget.period,
                              palette: palette,
                              isRunning: RoutineSessionController.instance
                                  .isRunningFor(widget.period),
                              onStartRoutine: _startRoutineFlow,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Title + one line, in the same fonts as the focus timer intro.
  Widget _buildIntro(RoutinePalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debug builds only: long-press opens the saved history as text.
          GestureDetector(
            onLongPress: kDebugMode ? _openDebugHistory : null,
            child: Text(
              _isMorning ? 'Your morning' : 'Your evening',
              style: AppFonts.cormorant(
                size: 26,
                weight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isMorning
                ? 'Set everything ready for the day ahead. Put your phone away and start slowly.'
                : 'Slow down, put your phone away and get ready for a good night’s sleep.',
            style: AppFonts.cormorant(size: 15, color: palette.muted),
          ),
        ],
      ),
    );
  }

  void _openDebugHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoutineHistoryDebugScreen()),
    );
  }
}
