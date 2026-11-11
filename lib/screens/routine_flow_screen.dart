import 'dart:async';

import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_timer.dart';

/// Keeps a user in one uninterrupted routine while individual steps are done.
class RoutineFlowScreen extends StatefulWidget {
  const RoutineFlowScreen({
    super.key,
    required this.period,
    required this.steps,
    required this.palette,
    required this.onStepCompleted,
  });

  final RoutinePeriod period;
  final List<RoutineStep> steps;
  final RoutinePalette palette;
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
  bool _isTimerRunning = true;
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

  int _durationInSeconds(String duration) {
    final minutes =
        int.tryParse(RegExp(r'\d+').firstMatch(duration)?.group(0) ?? '') ?? 5;
    return minutes * 60;
  }

  void _resetTimer() {
    _timer?.cancel();
    _totalSeconds = _durationInSeconds(widget.steps[_currentIndex].duration);
    _secondsRemaining = _totalSeconds;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
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
    } else {
      _timer?.cancel();
    }
  }

  int _nextIncompleteIndex(int start) {
    for (var index = start; index < widget.steps.length; index++) {
      if (!_completed.contains(index)) return index;
    }
    return -1;
  }

  Future<void> _completeCurrentStep() async {
    if (_isCompleting || _currentIndex == -1) return;
    final index = _currentIndex;
    setState(() => _isCompleting = true);
    try {
      await widget.onStepCompleted(index);
      if (!mounted) return;
      setState(() {
        _completed.add(index);
        _currentIndex = _nextIncompleteIndex(index + 1);
        if (_currentIndex == -1 && _completed.length < widget.steps.length) {
          _currentIndex = _nextIncompleteIndex(0);
        }
        _isCompleting = false;
        if (_currentIndex != -1) _resetTimer();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save routine progress.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _currentIndex == -1;
    final morning = widget.period == RoutinePeriod.morning;
    final step = isComplete ? null : widget.steps[_currentIndex];
    final nextIndex = isComplete ? -1 : _nextIncompleteIndex(_currentIndex + 1);
    final nextStep = nextIndex == -1 ? null : widget.steps[nextIndex];
    return Scaffold(
      backgroundColor: widget.palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: widget.palette.text,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Return to routine overview',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: widget.palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete
                      ? Icons.check_circle_rounded
                      : (morning
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_round),
                  color: widget.palette.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                isComplete
                    ? '${morning ? 'Morning' : 'Evening'} Routine Completed!'
                    : (morning ? 'MORNING ROUTINE' : 'EVENING ROUTINE'),
                key: const Key('routine-flow-heading'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.palette.accent,
                  fontSize: isComplete ? 25 : 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isComplete ? 0 : 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isComplete
                    ? 'Great work. Your routine is all done.'
                    : step!.title,
                key: const Key('routine-flow-step-title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.palette.text,
                  fontFamily: 'serif',
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              if (!isComplete) ...[
                Text(
                  'Step ${_currentIndex + 1} of ${widget.steps.length}',
                  style: TextStyle(
                    color: widget.palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nextStep == null
                      ? 'This is your final activity.'
                      : 'Next: ${nextStep.title}',
                  key: const Key('routine-flow-next-step'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                ActivityTimer(
                  key: const Key('routine-flow-timer'),
                  secondsRemaining: _secondsRemaining,
                  totalSeconds: _totalSeconds,
                  // Leaves enough room for the action buttons on compact
                  // screens, avoiding a bottom RenderFlex overflow.
                  size: 240,
                  palette: ActivityTimerPalette(
                    active: widget.palette.accent,
                    inactive: widget.palette.border,
                    text: widget.palette.text,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('routine-flow-pause-button'),
                  onPressed: _toggleTimer,
                  icon: Icon(
                    _isTimerRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _isTimerRunning ? 'Pause timer' : 'Continue timer',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.palette.text,
                    side: BorderSide(color: widget.palette.border),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  key: Key(
                    isComplete
                        ? 'return-to-overview-button'
                        : 'complete-routine-step-button',
                  ),
                  onPressed: _isCompleting
                      ? null
                      : (isComplete
                            ? () => Navigator.pop(context)
                            : _completeCurrentStep),
                  icon: _isCompleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isComplete
                              ? Icons.arrow_back_rounded
                              : Icons.check_rounded,
                        ),
                  label: Text(
                    isComplete
                        ? 'Return to overview'
                        : (_isCompleting ? 'Saving...' : 'Complete'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.palette.button,
                    foregroundColor: widget.palette.buttonText,
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
