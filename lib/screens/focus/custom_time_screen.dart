import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/focus/custom_preset_tile.dart';
import '../../widgets/focus/time_wheel.dart';

/// Lets the user add and remove their own timer presets,
/// using an hours / minutes scroll wheel.
///
/// Receives the current custom presets from the timer screen and always
/// returns the (possibly edited) list when closed, whether through the
/// back arrow or the system back gesture.
class CustomTimePage extends StatefulWidget {
  const CustomTimePage({super.key, required this.customPresets});

  /// Durations in minutes.
  final List<int> customPresets;

  @override
  State<CustomTimePage> createState() => _CustomTimePageState();
}

class _CustomTimePageState extends State<CustomTimePage> {
  int _selectedHours = 0;
  int _selectedMinutes = 15;
  late List<int> _presets;
  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;

  @override
  void initState() {
    super.initState();
    _presets = List.from(widget.customPresets);
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  /// Adds the time on the wheels as a preset (skips 0 and duplicates).
  void _addCurrentSelectedTime() {
    final totalMinutes = (_selectedHours * 60) + _selectedMinutes;
    if (totalMinutes == 0) return;

    if (!_presets.contains(totalMinutes)) {
      setState(() {
        _presets.add(totalMinutes);
        _presets.sort();
      });
    }
  }

  void _removePreset(int minutes) {
    setState(() => _presets.remove(minutes));
  }

  /// Closes the page and hands the presets back to the timer screen.
  void _close() => Navigator.pop(context, _presets);

  @override
  Widget build(BuildContext context) {
    // The system back gesture/button also returns the presets.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 25,
              color: context.palette.accent,
            ),
            onPressed: _close,
          ),
          title: Text(
            'Custom Timer',
            style: AppFonts.montserrat(size: 15, color: context.palette.accent),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(flex: 7, child: Center(child: _buildPicker())),
              Divider(color: context.palette.muted, indent: 24, endIndent: 24),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your Custom Presets:',
                    style: AppFonts.montserrat(
                      size: 14,
                      color: context.palette.muted,
                    ),
                  ),
                ),
              ),
              Expanded(flex: 2, child: _buildPresetList()),
            ],
          ),
        ),
      ),
    );
  }

  /// The hours / minutes wheels and the "Add Preset" button.
  Widget _buildPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Scroll to set time:',
          style: AppFonts.montserrat(size: 14, color: context.palette.muted),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          margin: EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: TimeWheel(
                  controller: _hoursController,
                  count: 24,
                  suffix: 'h',
                  onChanged: (i) => setState(() => _selectedHours = i),
                ),
              ),
              Expanded(
                child: TimeWheel(
                  controller: _minutesController,
                  count: 60,
                  suffix: 'min',
                  onChanged: (i) => setState(() => _selectedMinutes = i),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _addCurrentSelectedTime,
              icon: Icon(Icons.add, color: context.palette.onAccent),
              label: Text(
                'Add Preset',
                style: AppFonts.manrope(
                  size: 16,
                  weight: FontWeight.w600,
                  color: context.palette.onAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetList() {
    if (_presets.isEmpty) {
      return Center(
        child: Text(
          'No custom presets added yet.',
          style: AppFonts.montserrat(size: 13, color: context.palette.muted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: _presets.length,
      itemBuilder: (context, index) {
        final minutes = _presets[index];
        return CustomPresetTile(
          minutes: minutes,
          onDelete: () => _removePreset(minutes),
        );
      },
    );
  }
}
