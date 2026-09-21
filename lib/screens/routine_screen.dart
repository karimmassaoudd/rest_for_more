import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';
import '../widgets/active_routine_card.dart';
import '../widgets/bottom_action_dock.dart';
import '../widgets/greeting_header.dart';
import '../widgets/routine_item_card.dart';
import '../widgets/routine_switcher.dart';
import 'focus_mode_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  RoutinePeriod _period = RoutinePeriod.morning;

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

  void _selectPeriod(RoutinePeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
  }

  void _toggleStep(int index) {
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
    _scheduleEveningTransition();
  }

  void _scheduleEveningTransition() {
    if (_period != RoutinePeriod.morning ||
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
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {
      _morningSteps = _morningSteps
          .map((s) => s.copyWith(isCompleted: false))
          .toList();
      _eveningSteps = _eveningSteps
          .map((s) => s.copyWith(isCompleted: false))
          .toList();
    });
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
          palette: RoutinePalette.forPeriod(period),
        ),
      ),
    );
    if (completed == true && mounted) _completeStep(index, period);
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.forPeriod(_period);
    final activeIndex = _steps.indexWhere((step) => !step.isCompleted);
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Column(
                    key: ValueKey(_period),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GreetingHeader(period: _period, palette: palette),
                      const SizedBox(height: 24),
                      RoutineSwitcher(
                        selected: _period,
                        palette: palette,
                        onChanged: _selectPeriod,
                      ),
                      const SizedBox(height: 18),
                      ActiveRoutineCard(
                        period: _period,
                        palette: palette,
                        completed: _completed,
                        total: _steps.length,
                      ),
                      const SizedBox(height: 28),
                      _FlowHeading(remaining: _remaining, palette: palette),
                      const SizedBox(height: 12),
                      for (var index = 0; index < _steps.length; index++)
                        RoutineItemCard(
                          step: _steps[index],
                          index: index,
                          isActive: index == activeIndex,
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
                      const SizedBox(height: 14),
                      BottomActionDock(
                        period: _period,
                        palette: palette,
                        onEnterFocusMode: _enterFocusMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
          "TODAY'S FLOW",
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
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
