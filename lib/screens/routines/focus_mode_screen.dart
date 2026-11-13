import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../models/routines/routine_time.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Full-screen guide for one routine [step], with a countdown of its duration.
///
/// Closes with `true` when the user completes the step, `false` when they
/// close it. The timer is only a guide: the step can be completed any time.
class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({
    super.key,
    required this.period,
    required this.step,
    required this.nextStep,
    required this.palette,
  });

  final RoutinePeriod period;
  final RoutineStep step;

  /// Shown as "Next task"; null when this is the last open step.
  final RoutineStep? nextStep;
  final RoutinePalette palette;

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  Timer? _timer;
  late int _secondsRemaining;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    // 5 minutes when the duration text has no number.
    _secondsRemaining = (minutesInDuration(widget.step.duration) ?? 5) * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _toggleTimer() {
    setState(() => _isRunning = !_isRunning);
    if (_isRunning) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final morning = widget.period == RoutinePeriod.morning;
    final timerFinished = _secondsRemaining == 0;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close focus mode',
          onPressed: () => Navigator.pop(context, false),
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
                  color: palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  morning
                      ? Icons.self_improvement_rounded
                      : Icons.nightlight_round,
                  color: palette.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                morning ? 'FOCUS MODE' : 'SLEEP FLOW',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.step.title,
                textAlign: TextAlign.center,
                style: AppFonts.cormorant(
                  size: 32,
                  weight: FontWeight.w600,
                  color: palette.text,
                ).copyWith(height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Current task',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.nextStep == null
                    ? 'Next task: Routine complete'
                    : 'Next task: ${widget.nextStep!.title}',
                key: const Key('focus-next-task'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '$minutes:$seconds',
                key: const Key('focus-timer'),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 58,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              // Pause / Continue while counting, "Task finished" at zero.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: timerFinished
                    ? _buildFinishedBadge(palette)
                    : _buildPauseButton(palette),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  key: const Key('complete-focus-step-button'),
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    timerFinished ? 'Complete task' : 'Complete this step',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedBadge(RoutinePalette palette) {
    return Container(
      key: const Key('focus-timer-finished'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: palette.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            'Task finished',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(RoutinePalette palette) {
    return OutlinedButton.icon(
      key: const Key('pause-focus-button'),
      onPressed: _toggleTimer,
      icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
      label: Text(_isRunning ? 'Pause' : 'Continue'),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    );
  }
}
