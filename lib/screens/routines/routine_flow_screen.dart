import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../models/routines/routine_time.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/rfm_app_bar.dart';
import '../../widgets/focus/timer_dial.dart';
import '../../widgets/focus/timer_primary_button.dart';

/// One routine activity at a time, in the same layout as the focus timer:
/// title, "Activity 4 of 5", the sunburst dial, and the buttons below.
///
/// Opens at [initialIndex] (or the first open step). "Complete activity"
/// moves on to the next open step. A step that is already done shows
/// "Done" with a "Mark as not done" button.
///
/// The timer only runs while this screen is open for now; running in the
/// background (with app blocking) comes with RoutineSessionController.
class RoutineFlowScreen extends StatefulWidget {
  const RoutineFlowScreen({
    super.key,
    required this.period,
    required this.steps,
    required this.onStepCompleted,
    this.onStepReopened,
    this.initialIndex,
  });

  final RoutinePeriod period;
  final List<RoutineStep> steps;

  /// Persists [index]. The flow advances only after this future succeeds.
  final Future<void> Function(int index) onStepCompleted;

  /// Persists un-ticking [index] ("Mark as not done").
  final Future<void> Function(int index)? onStepReopened;

  /// The step to open. Null: the first step that isn't done.
  final int? initialIndex;

  @override
  State<RoutineFlowScreen> createState() => _RoutineFlowScreenState();
}

class _RoutineFlowScreenState extends State<RoutineFlowScreen> {
  late final Set<int> _completed;
  late int _currentIndex;
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  bool _isTimerRunning = false;
  bool _isCompleting = false;

  // ------------------------------------------------------------------
  // State
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _completed = {
      for (var index = 0; index < widget.steps.length; index++)
        if (widget.steps[index].isCompleted) index,
    };
    final start = widget.initialIndex;
    _currentIndex = start != null && start >= 0 && start < widget.steps.length
        ? start
        : _nextIncompleteIndex(0);
    if (_currentIndex != -1 && !_isCurrentDone) _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// True when every step is done (or there are no steps).
  bool get _isComplete => _currentIndex == -1;

  /// True when the step on screen is already ticked off.
  bool get _isCurrentDone =>
      _currentIndex != -1 && _completed.contains(_currentIndex);

  /// How full the dial is: 1.0 at the start, 0.0 when time is up.
  double get _progress =>
      _totalSeconds == 0 ? 0.0 : (_secondsRemaining / _totalSeconds);

  int _nextIncompleteIndex(int start) {
    for (var index = start; index < widget.steps.length; index++) {
      if (!_completed.contains(index)) return index;
    }
    return -1;
  }

  // ------------------------------------------------------------------
  // Timer (on screen only for now)
  // ------------------------------------------------------------------

  void _resetTimer() {
    _timer?.cancel();
    _totalSeconds =
        (minutesInDuration(widget.steps[_currentIndex].duration) ?? 5) * 60;
    _secondsRemaining = _totalSeconds;
    _isTimerRunning = true;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isTimerRunning) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isTimerRunning = false;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _toggleTimer() {
    if (_isCompleting || _isComplete || _secondsRemaining == 0) return;
    setState(() => _isTimerRunning = !_isTimerRunning);
    if (_isTimerRunning) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _completeCurrentStep() async {
    if (_isCompleting || _isComplete) return;
    final completedIndex = _currentIndex;
    setState(() => _isCompleting = true);
    try {
      await widget.onStepCompleted(completedIndex);
      if (!mounted) return;
      setState(() {
        _completed.add(completedIndex);
        // Next open step after this one; otherwise wrap to an earlier one.
        final after = _nextIncompleteIndex(completedIndex + 1);
        _currentIndex = after != -1 ? after : _nextIncompleteIndex(0);
        _isCompleting = false;
        if (_currentIndex != -1) {
          _resetTimer();
        } else {
          _timer?.cancel();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      _showSaveError();
    }
  }

  /// "Mark as not done" on a step that was already done.
  Future<void> _reopenCurrentStep() async {
    final reopen = widget.onStepReopened;
    if (reopen == null || _isCompleting || !_isCurrentDone) return;
    final index = _currentIndex;
    setState(() => _isCompleting = true);
    try {
      await reopen(index);
      if (!mounted) return;
      setState(() {
        _completed.remove(index);
        _isCompleting = false;
        _resetTimer();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      _showSaveError();
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save routine progress. Please try again.'),
      ),
    );
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final routineName = widget.period == RoutinePeriod.morning
        ? 'Morning'
        : 'Evening';

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RfmAppBar(title: routineName),
            const SizedBox(height: 28),
            _buildIntro(palette),
            Expanded(child: Center(child: _buildCenter(palette))),
            _buildButtons(palette),
          ],
        ),
      ),
    );
  }

  /// Step title + "Activity 4 of 5", in the focus timer's intro fonts.
  Widget _buildIntro(AppPalette palette) {
    final isEmpty = widget.steps.isEmpty;
    final String title;
    final String subtitle;
    if (_isComplete) {
      title = isEmpty ? 'No activities yet' : 'Beautifully done.';
      subtitle = isEmpty
          ? 'This routine has no activities yet.'
          : 'Every activity is saved.';
    } else {
      title = widget.steps[_currentIndex].title;
      subtitle = 'Activity ${_currentIndex + 1} of ${widget.steps.length}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            key: const Key('routine-flow-step-title'),
            style: AppFonts.cormorant(
              size: 26,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            key: const Key('routine-flow-progress'),
            style: AppFonts.cormorant(size: 15, color: palette.muted),
          ),
        ],
      ),
    );
  }

  /// The dial while a step runs; a check when it's done.
  Widget _buildCenter(AppPalette palette) {
    if (_isComplete || _isCurrentDone) {
      return Column(
        key: const Key('routine-flow-done'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: palette.highlight, size: 72),
          const SizedBox(height: 12),
          Text(
            _isComplete ? 'All done' : 'Done',
            style: AppFonts.cormorant(
              size: 30,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ],
      );
    }
    return TimerDial(progress: _progress, millisLeft: _secondsRemaining * 1000);
  }

  /// Like the focus timer: one big button, and a text button under it.
  Widget _buildButtons(AppPalette palette) {
    final Widget primary;
    Widget? secondary;

    if (_isComplete) {
      primary = TimerPrimaryButton(
        key: const Key('return-to-overview-button'),
        label: 'Return to overview',
        onPressed: () => Navigator.maybePop(context),
      );
    } else if (_isCurrentDone) {
      primary = TimerPrimaryButton(
        key: const Key('reopen-routine-step-button'),
        label: _isCompleting ? 'Saving...' : 'Mark as not done',
        onPressed: _isCompleting ? null : _reopenCurrentStep,
      );
    } else {
      primary = TimerPrimaryButton(
        key: const Key('complete-routine-step-button'),
        label: _isCompleting ? 'Saving...' : 'Complete activity',
        onPressed: _isCompleting ? null : _completeCurrentStep,
      );
      // No pause once the time is up.
      if (_secondsRemaining > 0) {
        secondary = _textButton(
          key: const Key('routine-flow-pause-button'),
          label: _isTimerRunning ? 'Pause' : 'Resume',
          onPressed: _toggleTimer,
          palette: palette,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primary,
          const SizedBox(height: 8),
          // Same height with or without the second button, so nothing jumps.
          SizedBox(height: 48, child: secondary),
        ],
      ),
    );
  }

  Widget _textButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
    required AppPalette palette,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        key: key,
        onPressed: onPressed,
        child: Text(
          label,
          style: AppFonts.manrope(
            size: 16,
            weight: FontWeight.w600,
            color: palette.accent,
          ),
        ),
      ),
    );
  }
}
