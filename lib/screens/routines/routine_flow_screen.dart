import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../models/routines/routine_time.dart';
import '../../services/routines/routine_session_controller.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/rfm_app_bar.dart';
import '../../widgets/focus/timer_dial.dart';
import '../../widgets/focus/timer_primary_button.dart';
import '../../widgets/routines/blocked_until_note.dart';

/// One routine activity at a time, in the same layout as the focus timer.
///
/// Opening a step starts its timer in [RoutineSessionController], so it
/// keeps running after going back. The first started step of a routine
/// also starts blocking the period's apps.
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
  final _session = RoutineSessionController.instance;
  late final Set<int> _completed;
  late int _currentIndex;
  Timer? _ticker;
  int _shownSecond = -1;
  bool _isCompleting = false;

  // ------------------------------------------------------------------
  // Lifecycle
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

    _session.addListener(_onSessionChanged);
    // Redraws only when the visible second changes.
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _session.tick();
      final second = (_millisLeft / 1000).ceil();
      if (second != _shownSecond && mounted) {
        setState(() => _shownSecond = second);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _startCurrentStep());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------------
  // Values
  // ------------------------------------------------------------------

  bool get _isComplete => _currentIndex == -1;

  bool get _isCurrentDone =>
      _currentIndex != -1 && _completed.contains(_currentIndex);

  String get _currentTitle => widget.steps[_currentIndex].title;

  int _minutesOf(int index) =>
      minutesInDuration(widget.steps[index].duration) ?? 5;

  /// Minutes of every step that isn't done yet (for the blocking end time).
  int get _openMinutes {
    var total = 0;
    for (var i = 0; i < widget.steps.length; i++) {
      if (!_completed.contains(i)) total += _minutesOf(i);
    }
    return total;
  }

  /// True when the session's running step is the one on screen.
  bool get _isMine =>
      !_isComplete &&
      _session.isRunningFor(widget.period) &&
      _session.activeStep == _currentTitle;

  int get _totalMillis =>
      _isMine ? _session.stepTotalMillis : _minutesOf(_currentIndex) * 60000;

  int get _millisLeft {
    if (_isComplete || _isCurrentDone) return 0;
    return _isMine ? _session.stepRemainingMillis : _totalMillis;
  }

  double get _progress =>
      _totalMillis == 0 ? 0.0 : (_millisLeft / _totalMillis).clamp(0.0, 1.0);

  bool get _isTimeUp => _isMine && _millisLeft == 0;

  int _nextIncompleteIndex(int start) {
    for (var index = start; index < widget.steps.length; index++) {
      if (!_completed.contains(index)) return index;
    }
    return -1;
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  /// Starts (or continues) the step on screen, and blocking with it.
  Future<void> _startCurrentStep() async {
    if (!mounted || _isComplete || _isCurrentDone) return;
    final result = await _session.startStep(
      context,
      period: widget.period,
      step: _currentTitle,
      stepMinutes: _minutesOf(_currentIndex),
      openMinutes: _openMinutes,
    );
    if (!mounted) return;
    switch (result) {
      case RoutineStartResult.started:
        break;
      case RoutineStartResult.focusRunning:
        _leaveWith(
          'A focus session is running. End it before starting your routine.',
        );
      case RoutineStartResult.otherRoutineRunning:
        _leaveWith('Your other routine is still running.');
    }
  }

  void _leaveWith(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    Navigator.maybePop(context);
  }

  void _togglePause() {
    if (_isCompleting || _isComplete) return;
    if (!_isMine) {
      unawaited(_startCurrentStep());
    } else if (_session.isPaused) {
      unawaited(_session.resumeStep());
    } else {
      unawaited(_session.pauseStep());
    }
  }

  Future<void> _completeCurrentStep() async {
    if (_isCompleting || _isComplete) return;
    final completedIndex = _currentIndex;
    final title = _currentTitle;
    setState(() => _isCompleting = true);
    try {
      await widget.onStepCompleted(completedIndex);
      await _session.completeStep(title);
      if (!mounted) return;
      setState(() {
        _completed.add(completedIndex);
        // Next open step after this one; otherwise wrap to an earlier one.
        final after = _nextIncompleteIndex(completedIndex + 1);
        _currentIndex = after != -1 ? after : _nextIncompleteIndex(0);
        _isCompleting = false;
      });
      await _startCurrentStep();
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
      });
      await _startCurrentStep();
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

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RfmAppBar(title: routineName(widget.period)),
            const SizedBox(height: 28),
            _buildIntro(palette),
            Expanded(child: Center(child: _buildCenter(palette))),
            _buildButtons(palette),
          ],
        ),
      ),
    );
  }

  /// Step title + "Activity 4 of 5", and the blocked-until note.
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
      title = _currentTitle;
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
          if (_isTimeUp) ...[
            const SizedBox(height: 2),
            Text(
              "Time's up. Complete it when you're ready.",
              style: AppFonts.cormorant(size: 15, color: palette.accent),
            ),
          ],
          const SizedBox(height: 14),
          BlockedUntilNote(period: widget.period),
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
    return TimerDial(progress: _progress, millisLeft: _millisLeft);
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
      if (!_isTimeUp) {
        final running = _isMine && !_session.isPaused;
        secondary = _textButton(
          key: const Key('routine-flow-pause-button'),
          label: running ? 'Pause' : 'Resume',
          onPressed: _togglePause,
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
