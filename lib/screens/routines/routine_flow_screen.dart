import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../models/routines/routine_time.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Guides a complete morning or evening routine without returning to its
/// overview between activities.
class RoutineFlowScreen extends StatefulWidget {
  const RoutineFlowScreen({
    super.key,
    required this.period,
    required this.steps,
    required this.onStepCompleted,
  });

  final RoutinePeriod period;
  final List<RoutineStep> steps;

  /// Persists [index]. The flow advances only after this future succeeds.
  final Future<void> Function(int index) onStepCompleted;

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

  @override
  void initState() {
    super.initState();
    _completed = {
      for (var index = 0; index < widget.steps.length; index++)
        if (widget.steps[index].isCompleted) index,
    };
    _currentIndex = _nextIncompleteIndex(0);
    if (_currentIndex != -1) _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _nextIncompleteIndex(int start) {
    for (var index = start; index < widget.steps.length; index++) {
      if (!_completed.contains(index)) return index;
    }
    return -1;
  }

  void _resetTimer() {
    _timer?.cancel();
    _totalSeconds = (minutesInDuration(widget.steps[_currentIndex].duration) ?? 5) * 60;
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
    if (_isCompleting || _currentIndex == -1) return;
    setState(() => _isTimerRunning = !_isTimerRunning);
    if (_isTimerRunning) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _completeCurrentStep() async {
    if (_isCompleting || _currentIndex == -1) return;
    final completedIndex = _currentIndex;
    setState(() => _isCompleting = true);
    try {
      await widget.onStepCompleted(completedIndex);
      if (!mounted) return;
      setState(() {
        _completed.add(completedIndex);
        _currentIndex = _nextIncompleteIndex(completedIndex + 1);
        _isCompleting = false;
        if (_currentIndex != -1) _resetTimer();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save routine progress. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.of(context);
    final isComplete = _currentIndex == -1;
    final isEmpty = widget.steps.isEmpty;
    final step = isComplete ? null : widget.steps[_currentIndex];
    final nextIndex = isComplete ? -1 : _nextIncompleteIndex(_currentIndex + 1);
    final nextStep = nextIndex == -1 ? null : widget.steps[nextIndex];
    final routineName = widget.period == RoutinePeriod.morning ? 'Morning' : 'Evening';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Return to routine overview',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              _StatusIcon(isComplete: isComplete, palette: palette),
              const SizedBox(height: 22),
              Text(
                isComplete ? '$routineName routine complete' : '$routineName routine',
                key: const Key('routine-flow-heading'),
                style: AppFonts.montserrat(
                  size: 11,
                  weight: FontWeight.w800,
                  color: palette.accent,
                ).copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                isComplete
                    ? (isEmpty ? 'No activities yet' : 'Beautifully done.')
                    : step!.title,
                key: const Key('routine-flow-step-title'),
                textAlign: TextAlign.center,
                style: AppFonts.cormorant(
                  size: 34,
                  weight: FontWeight.w600,
                  color: palette.text,
                ).copyWith(height: 1.05),
              ),
              const SizedBox(height: 10),
              if (isComplete)
                Text(
                  isEmpty ? 'Add activities from the routine overview to begin.' : 'Every activity is saved.',
                  textAlign: TextAlign.center,
                  style: AppFonts.manrope(size: 13, color: palette.muted),
                )
              else ...[
                Text(
                  'Activity ${_currentIndex + 1} of ${widget.steps.length}',
                  key: const Key('routine-flow-progress'),
                  style: AppFonts.montserrat(size: 11, weight: FontWeight.w600, color: palette.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  nextStep == null ? 'This is your final activity.' : 'Next: ${nextStep.title}',
                  key: const Key('routine-flow-next-step'),
                  textAlign: TextAlign.center,
                  style: AppFonts.manrope(size: 13, weight: FontWeight.w600, color: palette.muted),
                ),
                const SizedBox(height: 22),
                Expanded(child: Center(child: _TimerDisplay(seconds: _secondsRemaining, total: _totalSeconds, palette: palette))),
                OutlinedButton.icon(
                  key: const Key('routine-flow-pause-button'),
                  onPressed: _toggleTimer,
                  icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_isTimerRunning ? 'Pause timer' : 'Resume timer'),
                  style: OutlinedButton.styleFrom(foregroundColor: palette.text, side: BorderSide(color: palette.border)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  key: Key(isComplete ? 'return-to-overview-button' : 'complete-routine-step-button'),
                  onPressed: _isCompleting ? null : (isComplete ? () => Navigator.maybePop(context) : _completeCurrentStep),
                  icon: _isCompleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(isComplete ? Icons.arrow_back_rounded : Icons.check_rounded),
                  label: Text(isComplete ? 'Return to overview' : (_isCompleting ? 'Saving...' : 'Complete activity')),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.button,
                    foregroundColor: palette.buttonText,
                    textStyle: AppFonts.manrope(size: 14, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.isComplete, required this.palette});
  final bool isComplete;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
    child: Icon(isComplete ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded, color: palette.accent, size: 32),
  );
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.seconds, required this.total, required this.palette});
  final int seconds;
  final int total;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    final progress = total == 0 ? 0.0 : 1 - seconds / total;
    return SizedBox(
      width: math.min(MediaQuery.sizeOf(context).width - 48, 230),
      height: math.min(MediaQuery.sizeOf(context).width - 48, 230),
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 7, color: palette.accent, backgroundColor: palette.border.withValues(alpha: 0.35))),
        Text('$minutes:$remainingSeconds', key: const Key('routine-flow-timer'), style: AppFonts.cormorant(size: 52, weight: FontWeight.w600, color: palette.text)),
      ]),
    );
  }
}
