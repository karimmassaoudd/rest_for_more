import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/routines/default_routine_steps.dart';
import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_progress_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/common/rfm_app_bar.dart';
import '../../widgets/routines/active_routine_card.dart';
import '../../widgets/routines/bottom_action_dock.dart';
import '../../widgets/routines/completion_banner.dart';
import '../../widgets/routines/routine_item_card.dart';
import '../../widgets/routines/steps_heading.dart';
import 'routine_flow_screen.dart';

/// The morning or evening routine (view only): progress, the list of
/// steps, and a button that opens the guided flow through the open steps.
///
/// The period comes from the route (/routine?period=morning|evening).
/// Ticked-off steps are saved per period, so they survive a restart.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({
    super.key,
    required this.period,
    this.progressStorage = const RoutineProgressStorage(),
  });

  final RoutinePeriod period;

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
    unawaited(_loadProgress());
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

  /// Saves this period's ticks and today's history record.
  Future<void> _saveProgress() async {
    await widget.progressStorage.saveCompletedTasks(widget.period, _steps);
    await widget.progressStorage.saveToday(
      morningSteps: _morningSteps,
      eveningSteps: _eveningSteps,
    );
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  void _toggleStep(int index) {
    final updated = List<RoutineStep>.of(_steps);
    updated[index] = updated[index].copyWith(
      isCompleted: !updated[index].isCompleted,
    );
    setState(() => _setSteps(updated));
    unawaited(_saveWithFeedback());
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

  /// Opens the remaining activities as one continuous routine.
  Future<void> _startRoutineFlow() async {
    final hasOpenStep = _steps.any((step) => !step.isCompleted);
    if (!hasOpenStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMorning
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
          period: widget.period,
          steps: _steps,
          onStepCompleted: _completeStepAndSave,
        ),
      ),
    );
  }

  /// Called by the flow; it only moves on after this succeeds.
  Future<void> _completeStepAndSave(int index) async {
    final original = _steps;
    if (index < 0 || index >= original.length || original[index].isCompleted) {
      return;
    }
    final updated = List<RoutineStep>.of(original);
    updated[index] = updated[index].copyWith(isCompleted: true);
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
                        const SizedBox(height: 26),
                        StepsHeading(remaining: _remaining, palette: palette),
                        const SizedBox(height: 12),
                        for (var index = 0; index < _steps.length; index++)
                          RoutineItemCard(
                            step: _steps[index],
                            index: index,
                            isActive: index == activeIndex,
                            period: widget.period,
                            palette: palette,
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
                        BottomActionDock(
                          period: widget.period,
                          palette: palette,
                          onStartRoutine: _startRoutineFlow,
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
          Text(
            _isMorning ? 'Your morning' : 'Your evening',
            style: AppFonts.cormorant(
              size: 26,
              weight: FontWeight.w600,
              color: palette.text,
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
}
