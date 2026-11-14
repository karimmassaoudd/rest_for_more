import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/focus/pause_rules.dart';
import '../../services/focus/blocking_service.dart';
import '../../services/focus/session_controller.dart';
import '../../services/focus/timer_notification_service.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/rfm_logo.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/focus/duration_presets.dart';
import '../../widgets/focus/timer_dial.dart';
import '../../widgets/focus/timer_primary_button.dart';

/// Focus timer for one [profile].
///
/// Before the session: pick a duration (preset or custom) and press Start.
/// During the session: the dial counts down, apps are blocked, and the user
/// can take a limited number of short breaks or stop early.
///
/// All timer logic lives in [SessionController]; this screen only shows it.
class CountdownTimerPage extends StatefulWidget {
  const CountdownTimerPage({super.key, required this.profile});

  final BlockProfile profile;

  @override
  State<CountdownTimerPage> createState() => _CountdownTimerPageState();
}

class _CountdownTimerPageState extends State<CountdownTimerPage>
    with WidgetsBindingObserver {
  /// Presets that are always shown, before the user's own ones.
  static const _defaultPresets = [15, 30, 45];

  late final SessionController _controller;
  final _blocking = BlockingService();

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = SessionController(profile: widget.profile);
    _controller.onFinished = _showFinishedDialog;
    _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Saves the timer when the app goes to the background and
  /// catches up on the time that passed when it comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.save();
    } else if (state == AppLifecycleState.resumed) {
      _controller.onResumed();
    }
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _showFinishedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Timer finished'),
        content: Text('Your ${widget.profile.name} session is complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    await TimerNotificationService.instance.cancelAll();
  }

  /// Asks for the blocking permission if needed, then starts the session.
  Future<void> _onStartPressed() async {
    if (_controller.remainingMillis <= 0) return;

    final granted = await _blocking.ensurePermission(context);
    if (!granted || !mounted) return;

    final started = await _controller.start();

    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't start the session. Try again.")),
      );
    }
  }

  /// Ends the session after a confirm dialog. Not possible during a break.
  Future<void> _onStopPressed() async {
    if (_controller.isOnBreak) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("You can't stop the session during a break."),
          ),
        );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'End session?',
      message:
          'Your ${widget.profile.name} session will end and your apps will be unblocked.',
      confirmLabel: 'End session',
      cancelLabel: 'Keep going',
    );

    // The page may be gone, or the timer may have finished, while the dialog was open.
    if (!confirmed || !mounted || !_controller.hasStarted) return;
    _controller.stop();
  }

  /// Opens the custom time page and saves the presets it returns.
  Future<void> _openCustomTime() async {
    final updatedPresets = await context.push<List<int>>(
      '/custom-time',
      extra: _controller.customPresets,
    );
    if (!mounted) return;
    if (updatedPresets != null) {
      _controller.updateCustomPresets(updatedPresets);
    }
  }

  // ------------------------------------------------------------------
  // Values for the UI
  // ------------------------------------------------------------------

  /// How full the dial is: break time left during a break, otherwise session time left.
  double get _progress {
    if (_controller.isOnBreak) {
      return (_controller.breakLeftMillis / (kBreakMinutes * 60 * 1000)).clamp(
        0.0,
        1.0,
      );
    }
    if (_controller.totalMillis <= 0) return 0.0;
    return (_controller.remainingMillis / _controller.totalMillis).clamp(
      0.0,
      1.0,
    );
  }

  /// Default presets first, then the user's own (without duplicates).
  List<int> get _allPresets => [
    ..._defaultPresets,
    ..._controller.customPresets.where((p) => !_defaultPresets.contains(p)),
  ];

  String get _pauseLabel {
    if (_controller.isOnBreak) return 'Break in progress';
    if (_controller.pausesAllowed == 0) return 'Pause not available';
    if (_controller.pausesLeft <= 0) return 'No pauses left';
    return 'Pause (${_controller.pausesLeft} left)';
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final onBreak = _controller.isOnBreak;

        return Scaffold(
          backgroundColor: context.palette.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildIntro(),
                Expanded(
                  child: Center(
                    child: TimerDial(
                      progress: _progress,
                      millisLeft: onBreak
                          ? _controller.breakLeftMillis
                          : _controller.remainingMillis,
                      onBreak: onBreak,
                    ),
                  ),
                ),
                // Durations can only be picked before the session starts.
                if (!_controller.hasStarted) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: DurationPresetGrid(
                      presets: _allPresets,
                      selectedMillis: _controller.totalMillis,
                      onSelected: _controller.selectPreset,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: AddPresetButton(onTap: _openCustomTime),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _buildButtons(onBreak),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Back arrow, profile name and logo.

  /// Back arrow, profile name and logo.
  Widget _buildHeader() {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          InkWell(
            // Opened from the notification there is nothing underneath,
            // so go Home instead of popping (pop would do nothing).
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, size: 25, color: palette.accent),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.profile.name,
            style: AppFonts.montserrat(size: 15, color: palette.accent),
          ),
          const Spacer(),
          RfmLogo(textColor: context.palette.muted),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long do you want to focus?',
            style: AppFonts.cormorant(
              size: 26,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'You can always pause or stop the timer along the way',
            style: AppFonts.cormorant(size: 15, color: palette.muted),
          ),
        ],
      ),
    );
  }

  /// "Start" before the session; "Pause" + "Stop" while it runs.
  Widget _buildButtons(bool onBreak) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_controller.hasStarted)
              TimerPrimaryButton(label: 'Start', onPressed: _onStartPressed)
            else ...[
              TimerPrimaryButton(
                label: _pauseLabel,
                onPressed: _controller.canPause ? _controller.startBreak : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _onStopPressed,
                  child: Text(
                    'Stop',
                    style: AppFonts.manrope(
                      size: 16,
                      weight: FontWeight.w600,
                      // Greyed out during a break (stopping isn't allowed then).
                      color: onBreak ? palette.muted : palette.accent,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
