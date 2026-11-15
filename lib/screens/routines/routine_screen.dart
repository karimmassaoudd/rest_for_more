import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/routines/default_routine_steps.dart';
import '../../models/routines/routine_step.dart';
import '../../models/routines/routine_time.dart';
import '../../services/routines/routine_progress_storage.dart';
import '../../services/routines/routine_reminder_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/routines/active_routine_card.dart';
import '../../widgets/routines/bottom_action_dock.dart';
import '../../widgets/routines/completion_banner.dart';
import '../../widgets/routines/greeting_header.dart';
import '../../widgets/routines/routine_action_sheets.dart';
import '../../widgets/routines/routine_item_card.dart';
import '../../widgets/routines/routine_period_switcher.dart';
import '../../widgets/routines/steps_heading.dart';
import '../../widgets/routines/task_preview.dart';
import 'routine_flow_screen.dart';
import 'routine_history_screen.dart';
import 'reminder_settings_screen.dart';

/// The morning or evening routine: progress, the list of steps to tick off,
/// adding steps, and a guided flow through the remaining activities.
///
/// Morning uses the light [RoutinePalette], evening the dark one.
/// Ticked-off steps are saved per period, so they survive a restart.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({
    super.key,
    this.initialPeriod = RoutinePeriod.morning,
    this.autoStartFlow = false,
    this.progressStorage = const RoutineProgressStorage(),
  });

  final RoutinePeriod initialPeriod;
  final bool autoStartFlow;

  /// Replaceable in tests.
  final RoutineProgressStorage progressStorage;

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late RoutinePeriod _period;
  bool _autoAdvanceToEvening = true;

  List<RoutineStep> _morningSteps = defaultMorningSteps;
  List<RoutineStep> _eveningSteps = defaultEveningSteps;

  // ------------------------------------------------------------------
  // Steps of the period on screen
  // ------------------------------------------------------------------

  List<RoutineStep> _stepsFor(RoutinePeriod period) =>
      period == RoutinePeriod.morning ? _morningSteps : _eveningSteps;

  /// Call inside setState.
  void _setSteps(RoutinePeriod period, List<RoutineStep> steps) {
    if (period == RoutinePeriod.morning) {
      _morningSteps = steps;
    } else {
      _eveningSteps = steps;
    }
  }

  List<RoutineStep> get _steps => _stepsFor(_period);
  int get _completed => _steps.where((step) => step.isCompleted).length;
  int get _remaining => _steps.length - _completed;
  int get _totalMinutes => _steps.fold(
    0,
    (total, step) => total + (minutesInDuration(step.duration) ?? 0),
  );

  /// The first step after [currentIndex] that isn't done yet.
  RoutineStep? _nextIncompleteStep(int currentIndex) {
    for (var index = currentIndex + 1; index < _steps.length; index++) {
      if (!_steps[index].isCompleted) return _steps[index];
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Loading and saving progress
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    unawaited(_loadInitialRoutine());
  }

  Future<void> _loadInitialRoutine() async {
    await _loadProgress();
    if (!widget.autoStartFlow || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startRoutineFlow());
    });
  }

  Future<void> _loadProgress() async {
    try {
      final results = await Future.wait([
        widget.progressStorage.loadCompletedTasks(RoutinePeriod.morning),
        widget.progressStorage.loadCompletedTasks(RoutinePeriod.evening),
      ]);
      if (!mounted) return;
      setState(() {
        _morningSteps = _applySavedProgress(_morningSteps, results[0]);
        _eveningSteps = _applySavedProgress(_eveningSteps, results[1]);
      });
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

  Future<void> _saveProgress(RoutinePeriod period) async {
    try {
      await widget.progressStorage.saveCompletedTasks(
        period,
        _stepsFor(period),
      );
      await widget.progressStorage.saveToday(
        morningSteps: _morningSteps,
        eveningSteps: _eveningSteps,
      );
      unawaited(RoutineReminderService().refreshIfEnabled());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save routine progress.')),
      );
    }
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  void _toggleStep(int index) {
    final period = _period;
    setState(() {
      final updated = List<RoutineStep>.of(_stepsFor(period));
      updated[index] = updated[index].copyWith(
        isCompleted: !updated[index].isCompleted,
      );
      _setSteps(period, updated);
    });
    unawaited(_saveProgress(period));
  }

  /// Starts a fresh routine day by clearing both periods' saved completion.
  Future<void> _refreshRoutine() async {
    final previousMorning = _morningSteps;
    final previousEvening = _eveningSteps;
    final freshMorning = previousMorning
        .map((step) => step.copyWith(isCompleted: false))
        .toList();
    final freshEvening = previousEvening
        .map((step) => step.copyWith(isCompleted: false))
        .toList();

    setState(() {
      _period = RoutinePeriod.morning;
      _morningSteps = freshMorning;
      _eveningSteps = freshEvening;
    });
    try {
      await Future.wait([
        widget.progressStorage.saveCompletedTasks(
          RoutinePeriod.morning,
          freshMorning,
        ),
        widget.progressStorage.saveCompletedTasks(
          RoutinePeriod.evening,
          freshEvening,
        ),
      ]);
      await widget.progressStorage.saveToday(
        morningSteps: freshMorning,
        eveningSteps: freshEvening,
      );
      unawaited(RoutineReminderService().refreshIfEnabled());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your routines are ready for a fresh start.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _morningSteps = previousMorning;
        _eveningSteps = previousEvening;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restart your routines.')),
      );
    }
  }

  Future<void> _addStep() async {
    final period = _period;
    final palette = RoutinePalette.of(context);
    final step = await showModalBottomSheet<RoutineStep>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddRoutineSheet(period: period, palette: palette),
    );
    if (step == null || !mounted) return;

    setState(() => _setSteps(period, [..._stepsFor(period), step]));
    unawaited(_saveProgress(period));
  }

  Future<void> _openSettings() async {
    final period = _period;
    final palette = RoutinePalette.of(context);
    final result = await showModalBottomSheet<RoutineSettingsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RoutineSettingsSheet(
        period: period,
        palette: palette,
        autoAdvanceToEvening: _autoAdvanceToEvening,
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _autoAdvanceToEvening = result.autoAdvanceToEvening;
      if (result.resetProgress) {
        _setSteps(
          period,
          _steps.map((step) => step.copyWith(isCompleted: false)).toList(),
        );
      }
    });
    if (result.resetProgress) unawaited(_saveProgress(period));
  }

  /// Opens the remaining activities as one continuous routine.
  Future<void> _startRoutineFlow() async {
    final period = _period;
    final index = _steps.indexWhere((step) => !step.isCompleted);
    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            period == RoutinePeriod.morning
                ? 'Your morning routine is complete.'
                : 'Your evening routine is complete.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RoutineFlowScreen(
          period: period,
          steps: _steps,
          onStepCompleted: (stepIndex) =>
              _completeStepAndSave(stepIndex, period),
        ),
      ),
    );
  }

  Future<void> _completeStepAndSave(int index, RoutinePeriod period) async {
    final source = _stepsFor(period);
    if (index < 0 || index >= source.length || source[index].isCompleted) {
      return;
    }
    final original = source;
    final updated = List<RoutineStep>.of(source);
    updated[index] = updated[index].copyWith(isCompleted: true);
    if (mounted) setState(() => _setSteps(period, updated));
    try {
      await widget.progressStorage.saveCompletedTasks(period, updated);
      await widget.progressStorage.saveToday(
        morningSteps: period == RoutinePeriod.morning ? updated : _morningSteps,
        eveningSteps: period == RoutinePeriod.evening ? updated : _eveningSteps,
      );
      unawaited(RoutineReminderService().refreshIfEnabled());
    } catch (_) {
      if (mounted) setState(() => _setSteps(period, original));
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
    final currentStep = activeIndex == -1 ? null : _steps[activeIndex];
    final nextStep = activeIndex == -1
        ? null
        : _nextIncompleteStep(activeIndex);

    return Scaffold(
      backgroundColor: palette.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        color: palette.background,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshRoutine,
            color: palette.accent,
            backgroundColor: palette.background,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      key: ValueKey(_period),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GreetingHeader(
                          period: _period,
                          palette: palette,
                          onBack: () => Navigator.maybePop(context),
                          // Morning: refresh. Evening: routine settings.
                          onAction: () {
                            if (_period == RoutinePeriod.morning) {
                              unawaited(_refreshRoutine());
                            } else {
                              unawaited(_openSettings());
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ActiveRoutineCard(
                          period: _period,
                          palette: palette,
                          completed: _completed,
                          total: _steps.length,
                          totalMinutes: _totalMinutes,
                        ),
                        const SizedBox(height: 12),
                        RoutinePeriodSwitcher(
                          period: _period,
                          palette: palette,
                          onChanged: (period) =>
                              setState(() => _period = period),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: Wrap(
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RoutineHistoryScreen(
                                      storage: widget.progressStorage,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                ),
                                label: const Text('View history'),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ReminderSettingsScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  size: 16,
                                ),
                                label: const Text('Reminders'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TaskPreview(
                          currentStep: currentStep,
                          nextStep: nextStep,
                          palette: palette,
                        ),
                        const SizedBox(height: 22),
                        StepsHeading(remaining: _remaining, palette: palette),
                        const SizedBox(height: 12),
                        for (var index = 0; index < _steps.length; index++)
                          RoutineItemCard(
                            step: _steps[index],
                            index: index,
                            isActive: index == activeIndex,
                            period: _period,
                            palette: palette,
                            onToggle: () => _toggleStep(index),
                          ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _remaining == 0
                              ? CompletionBanner(
                                  key: ValueKey('complete-${_period.name}'),
                                  period: _period,
                                  palette: palette,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 5),
                        _buildAddStepButton(palette),
                        const SizedBox(height: 10),
                        BottomActionDock(
                          period: _period,
                          palette: palette,
                          onStartRoutine: _startRoutineFlow,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _period == RoutinePeriod.morning
                              ? 'Your times follow your wake-up time. Adjust a step whenever your morning changes.'
                              : 'Times count back from your bedtime. Move your bedtime and your evening moves with it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 9.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddStepButton(RoutinePalette palette) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        key: const Key('add-step-button'),
        onPressed: _addStep,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add step'),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accent,
          backgroundColor: palette.background,
          side: BorderSide(color: palette.border),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
