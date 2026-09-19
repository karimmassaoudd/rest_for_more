import 'dart:async';

import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({
    super.key,
    required this.period,
    required this.step,
    required this.palette,
  });

  final RoutinePeriod period;
  final RoutineStep step;
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
    _secondsRemaining = _durationInSeconds(widget.step.duration);
    _startTimer();
  }

  int _durationInSeconds(String duration) {
    final minutes = int.tryParse(
          RegExp(r'\d+').firstMatch(duration)?.group(0) ?? '',
        ) ??
        5;
    return minutes * 60;
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final morning = widget.period == RoutinePeriod.morning;

    return Scaffold(
      backgroundColor: widget.palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: widget.palette.text,
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
                  color: widget.palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  morning
                      ? Icons.self_improvement_rounded
                      : Icons.nightlight_round,
                  color: widget.palette.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                morning ? 'FOCUS MODE' : 'SLEEP FLOW',
                style: TextStyle(
                  color: widget.palette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.step.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.palette.text,
                  fontFamily: 'serif',
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                '$minutes:$seconds',
                key: const Key('focus-timer'),
                style: TextStyle(
                  color: widget.palette.text,
                  fontSize: 58,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const Key('pause-focus-button'),
                onPressed: _toggleTimer,
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(_isRunning ? 'Pause' : 'Continue'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.palette.text,
                  side: BorderSide(color: widget.palette.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  key: const Key('complete-focus-step-button'),
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Complete this step'),
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
