import 'dart:async';

import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../services/routine_progress_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/active_routine_card.dart';
import '../widgets/bottom_action_dock.dart';
import '../widgets/greeting_header.dart';
import '../widgets/routine_item_card.dart';
import '../widgets/routine_action_sheets.dart';
import '../widgets/routine_switcher.dart';
import 'focus_mode_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({
    super.key,
    this.progressStorage = const RoutineProgressStorage(),
  });

  final RoutineProgressStorage progressStorage;

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  RoutinePeriod _period = RoutinePeriod.morning;
  bool _autoAdvanceToEvening = true;

  List<RoutineStep> _morningSteps = const [
    RoutineStep(
      title: 'Cold Water & Electrolytes',
      time: '7:00 AM',
      duration: '5 min',
      isCompleted: true,
    ),
    RoutineStep(
      title: 'Box Breathing & Stretch',
      time: '7:05 AM',
      duration: '10 min',
      isCompleted: true,
    ),
    RoutineStep(
      title: 'Sensory Shower',
      time: '7:15 AM',
      duration: '15 min',
      isCompleted: true,
    ),
    RoutineStep(
      title: 'Matcha & Intention Journal',
      time: '7:30 AM',
      duration: '10 min',
    ),
    RoutineStep(
      title: 'Daily Priority Alignment',
      time: '7:40 AM',
      duration: '5 min',
    ),
  ];

  List<RoutineStep> _eveningSteps = const [
    RoutineStep(
      title: 'Screen Curfew & Phone Away',
      time: '9:40 PM',
      duration: '5 min',
    ),
    RoutineStep(
      title: 'Herbal Chamomile & Tincture',
      time: '9:45 PM',
      duration: '10 min',
    ),
    RoutineStep(
      title: 'Warm Shower & Skincare',
      time: '9:55 PM',
      duration: '15 min',
    ),
    RoutineStep(
      title: 'Gratitude & Unload Journal',
      time: '10:10 PM',
      duration: '10 min',
    ),
    RoutineStep(
      title: 'Dim Lamps & 4-7-8 Breathing',
      time: '10:20 PM',
      duration: '5 min',
    ),
  ];

  List<RoutineStep> get _steps =>
      _period == RoutinePeriod.morning ? _morningSteps : _eveningSteps;
  int get _completed => _steps.where((step) => step.isCompleted).length;
  int get _remaining => _steps.length - _completed;
  int get _totalMinutes => _steps.fold(0, (total, step) {
    final minutes = int.tryParse(
      RegExp(r'\d+').firstMatch(step.duration)?.group(0) ?? '',
    );
    return total + (minutes ?? 0);
  });

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
    final steps = period == RoutinePeriod.morning
        ? _morningSteps
        : _eveningSteps;
    try {
      await widget.progressStorage.saveCompletedTasks(period, steps);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save routine progress.')),
      );
    }
  }

  void _selectPeriod(RoutinePeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
  }

  void _toggleStep(int index) {
    final period = _period;
    final wasCompleted = _steps[index].isCompleted;
    setState(() {
      final source = _period == RoutinePeriod.morning
          ? _morningSteps
          : _eveningSteps;
      final updated = List<RoutineStep>.of(source);
      updated[index] = updated[index].copyWith(
        isCompleted: !updated[index].isCompleted,
      );
      if (_period == RoutinePeriod.morning) {
        _morningSteps = updated;
      } else {
        _eveningSteps = updated;
      }
    });

    unawaited(_saveProgress(period));

    if (!wasCompleted) _scheduleEveningTransition();
  }

  void _completeStep(int index, RoutinePeriod period) {
    if (_period != period) return;
    final source = period == RoutinePeriod.morning
        ? _morningSteps
        : _eveningSteps;
    if (source[index].isCompleted) return;

    setState(() {
      final updated = List<RoutineStep>.of(source);
      updated[index] = updated[index].copyWith(isCompleted: true);
      if (period == RoutinePeriod.morning) {
        _morningSteps = updated;
      } else {
        _eveningSteps = updated;
      }
    });
    unawaited(_saveProgress(period));
    _scheduleEveningTransition();
  }

  void _scheduleEveningTransition() {
    if (!_autoAdvanceToEvening ||
        _period != RoutinePeriod.morning ||
        _morningSteps.any((step) => !step.isCompleted)) {
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted ||
          _period != RoutinePeriod.morning ||
          _morningSteps.any((step) => !step.isCompleted)) {
        return;
      }
      setState(() => _period = RoutinePeriod.evening);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Morning complete — your Evening routine is ready.'),
        ),
      );
    });
  }

  Future<void> _refreshRoutine() async {
    await _loadProgress();
  }

  Future<void> _addStep() async {
    final period = _period;
    final palette = RoutinePalette.forPeriod(period);
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

    setState(() {
      if (period == RoutinePeriod.morning) {
        _morningSteps = [..._morningSteps, step];
      } else {
        _eveningSteps = [..._eveningSteps, step];
      }
    });
    unawaited(_saveProgress(period));
  }

  Future<void> _openSettings() async {
    final period = _period;
    final palette = RoutinePalette.forPeriod(period);
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
        final resetSteps = _steps
            .map((step) => step.copyWith(isCompleted: false))
            .toList();
        if (period == RoutinePeriod.morning) {
          _morningSteps = resetSteps;
        } else {
          _eveningSteps = resetSteps;
        }
      }
      if (result.switchToEvening) _period = RoutinePeriod.evening;
    });
    if (result.resetProgress) unawaited(_saveProgress(period));
  }

  Future<void> _enterFocusMode() async {
    final period = _period;
    final index = _steps.indexWhere((step) => !step.isCompleted);
    if (index == -1) {
      if (period == RoutinePeriod.morning) {
        setState(() => _period = RoutinePeriod.evening);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your evening routine is complete.')),
        );
      }
      return;
    }

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FocusModeScreen(
          period: period,
          step: _steps[index],
          nextStep: _nextIncompleteStep(index),
          palette: RoutinePalette.forPeriod(period),
        ),
      ),
    );
    if (completed == true && mounted) _completeStep(index, period);
  }

  RoutineStep? _nextIncompleteStep(int currentIndex) {
    for (var index = currentIndex + 1; index < _steps.length; index++) {
      if (!_steps[index].isCompleted) return _steps[index];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.forPeriod(_period);
    final activeIndex = _steps.indexWhere((step) => !step.isCompleted);
    final currentStep = activeIndex == -1 ? null : _steps[activeIndex];
    final nextStep = activeIndex == -1
        ? null
        : _nextIncompleteStep(activeIndex);
    final isComplete = _remaining == 0;

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
                          onBack: () {
                            if (_period == RoutinePeriod.evening) {
                              _selectPeriod(RoutinePeriod.morning);
                            } else {
                              Navigator.maybePop(context);
                            }
                          },
                          onAction: () {
                            if (_period == RoutinePeriod.morning) {
                              unawaited(_refreshRoutine());
                            } else {
                              unawaited(_openSettings());
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        RoutineSwitcher(
                          selected: _period,
                          palette: palette,
                          onChanged: _selectPeriod,
                        ),
                        const SizedBox(height: 14),
                        ActiveRoutineCard(
                          period: _period,
                          palette: palette,
                          completed: _completed,
                          total: _steps.length,
                          totalMinutes: _totalMinutes,
                        ),
                        const SizedBox(height: 12),
                        _TaskPreview(
                          currentStep: currentStep,
                          nextStep: nextStep,
                          palette: palette,
                        ),
                        const SizedBox(height: 22),
                        _FlowHeading(remaining: _remaining, palette: palette),
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
                          child: isComplete
                              ? _CompletionBanner(
                                  key: ValueKey('complete-${_period.name}'),
                                  period: _period,
                                  palette: palette,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
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
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        BottomActionDock(
                          period: _period,
                          palette: palette,
                          onEnterFocusMode: _enterFocusMode,
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
            ), // SingleChildScrollView
          ), // RefreshIndicator
        ), // SafeArea
      ), // AnimatedContainer
    );
  }
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({
    required this.currentStep,
    required this.nextStep,
    required this.palette,
  });

  final RoutineStep? currentStep;
  final RoutineStep? nextStep;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskPreviewRow(
            icon: Icons.play_circle_outline_rounded,
            label: 'Current task',
            value: currentStep?.title ?? 'Routine complete',
            palette: palette,
          ),
          const SizedBox(height: 8),
          _TaskPreviewRow(
            icon: Icons.arrow_forward_rounded,
            label: 'Next task',
            value: nextStep?.title ?? 'Routine complete',
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _TaskPreviewRow extends StatelessWidget {
  const _TaskPreviewRow({
    required this.label,
    required this.value,
    required this.palette,
    required this.icon,
  });

  final String label;
  final String value;
  final RoutinePalette palette;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: palette.accent, size: 15),
        const SizedBox(width: 9),
        SizedBox(
          width: 76,
          child: Text(
            '$label:',
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            key: Key(label.toLowerCase().replaceAll(' ', '-')),
            style: TextStyle(
              color: palette.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowHeading extends StatelessWidget {
  const _FlowHeading({required this.remaining, required this.palette});
  final int remaining;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'YOUR STEPS',
          style: TextStyle(
            color: palette.text,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.55,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            '$remaining ${remaining == 1 ? 'step' : 'steps'} remaining',
            key: ValueKey(remaining),
            style: TextStyle(
              color: palette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({
    super.key,
    required this.period,
    required this.palette,
  });
  final RoutinePeriod period;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final morning = period == RoutinePeriod.morning;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            morning ? Icons.check_circle_rounded : Icons.nightlight_round,
            color: palette.accent,
            size: 18,
          ),
          const SizedBox(width: 9),
          Text(
            morning ? 'Morning Routine Complete' : 'Sleep Mode Activated',
            style: TextStyle(
              color: palette.text,
              fontFamily: 'serif',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
