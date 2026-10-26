import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/timer_notification_service.dart';

import '../services/blocking_service.dart';
import '../services/session_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/sunburst_timer_painter.dart';
import '../models/pause_rules.dart';
import '../widgets/confirm_dialog.dart';

class CountdownTimerPage extends StatefulWidget {
  const CountdownTimerPage({super.key, required this.profile});

  final BlockProfile profile;

  @override
  State<CountdownTimerPage> createState() => _CountdownTimerPageState();
}

class _CountdownTimerPageState extends State<CountdownTimerPage>
    with WidgetsBindingObserver {
  late final SessionController _controller;
  final _blocking = BlockingService();

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.save();
    } else if (state == AppLifecycleState.resumed) {
      _controller.onResumed();
    }
  }

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

  Future<void> _navigateToCustomTimePage() async {
    final updatedPresets = await context.push<List<int>>(
      '/custom-time',
      extra: _controller.customPresets,
    );
    if (!mounted) return;
    if (updatedPresets != null) {
      _controller.updateCustomPresets(updatedPresets);
    }
  }

  String _convertToTimeFormat(int millis) {
    final safeMillis = millis < 0 ? 0 : millis;
    final totalSeconds = (safeMillis / 1000).ceil();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _pauseLabel {
    if (_controller.isOnBreak) return 'Break in progress';
    if (_controller.pausesAllowed == 0) return 'Pause not available';
    if (_controller.pausesLeft <= 0) return 'No pauses left';
    return 'Pause (${_controller.pausesLeft} left)';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back,
                size: 25,
                color: AppColors.mediumbrown,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            widget.profile.name,
            style: AppFonts.montserrat(size: 15, color: AppColors.mediumbrown),
          ),
          const Spacer(),
          Image.asset(
            'assets/images/rfm_logo.png',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final onBreak = _controller.isOnBreak;
        final progress = onBreak
            ? (_controller.breakLeftMillis / (kBreakMinutes * 60 * 1000)).clamp(
                0.0,
                1.0,
              )
            : (_controller.totalMillis > 0
                  ? (_controller.remainingMillis / _controller.totalMillis)
                        .clamp(0.0, 1.0)
                  : 0.0);
        final allPresets = <int>[
          15,
          30,
          45,
          ..._controller.customPresets.where((p) => ![15, 30, 45].contains(p)),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How long do you want to focus?',
                        style: AppFonts.cormorant(
                          size: 26,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You can always pause or stop the timer along the way',
                        style: AppFonts.cormorant(
                          size: 15,
                          color: AppColors.lightbrown,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 310,
                        height: 310,
                        child: CustomPaint(
                          painter: SunburstTimerPainter(
                            progress: progress,
                            tickCount: 72,
                            activeColorStart: AppColors.yellowhighlight,
                            activeColorEnd: AppColors.darkbrown,
                            inactiveColor: AppColors.surface,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (onBreak)
                                  Text(
                                    'Break',
                                    style: AppFonts.montserrat(
                                      size: 14,
                                      color: AppColors.lightbrown,
                                    ),
                                  ),
                                Text(
                                  _convertToTimeFormat(
                                    onBreak
                                        ? _controller.breakLeftMillis
                                        : _controller.remainingMillis,
                                  ),
                                  style: AppFonts.cormorant(
                                    size: 64,
                                    weight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_controller.hasStarted) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _buildPresetGrid(allPresets),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: _buildPlusButton(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_controller.hasStarted)
                          _buildPrimaryButton('Start', _onStartPressed)
                        else ...[
                          _buildPrimaryButton(
                            _pauseLabel,
                            _controller.canPause
                                ? _controller.startBreak
                                : null,
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
                                  color: onBreak
                                      ? AppColors.lightbrown
                                      : AppColors.mediumbrown,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mediumbrown,
          disabledBackgroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppFonts.manrope(
            size: 15,
            color: onPressed == null
                ? AppColors.lightbrown
                : AppColors.background,
          ),
        ),
      ),
    );
  }

  Widget _buildPlusButton() {
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: AppColors.darkbrown.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _navigateToCustomTimePage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightbrown, width: 1),
          ),
          child: const Icon(Icons.add, size: 28, color: AppColors.mediumbrown),
        ),
      ),
    );
  }

  Widget _buildPresetGrid(List<int> presets) {
    const perRow = 3;
    const gap = 12.0;
    final rows = <Widget>[];

    for (var start = 0; start < presets.length; start += perRow) {
      final cells = <Widget>[];
      for (var c = 0; c < perRow; c++) {
        final index = start + c;
        if (c > 0) cells.add(const SizedBox(width: gap));
        cells.add(
          Expanded(
            child: index < presets.length
                ? _buildPresetButton(presets[index])
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(Row(children: cells));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 152),
      child: SingleChildScrollView(child: Column(children: rows)),
    );
  }

  Widget _buildPresetButton(int minutes) {
    final isSelected = _controller.totalMillis == minutes * 60 * 1000;
    final label = minutes >= 60
        ? '${minutes ~/ 60}h${minutes % 60 > 0 ? " ${minutes % 60}m" : ""}'
        : '$minutes min';

    return Material(
      color: isSelected ? AppColors.mediumbrown : AppColors.surface,
      elevation: isSelected ? 0 : 3,
      shadowColor: AppColors.darkbrown.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _controller.selectPreset(minutes),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: AppColors.lightbrown, width: 1),
          ),
          child: Text(
            label,
            style: AppFonts.manrope(
              size: 13,
              color: isSelected ? AppColors.background : AppColors.mediumbrown,
            ),
          ),
        ),
      ),
    );
  }
}
