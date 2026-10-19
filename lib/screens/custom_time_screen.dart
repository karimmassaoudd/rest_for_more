import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class CustomTimePage extends StatefulWidget {
  final List<int> customPresets;

  const CustomTimePage({super.key, required this.customPresets});

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

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 40,
        scrollController: controller,
        onSelectedItemChanged: onChanged,
        children: List.generate(
          count,
          (index) => Center(
            child: Text(
              '$index $suffix',
              style: AppFonts.manrope(size: 20, weight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The system back gesture/button also returns the presets.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _presets);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 25,
              color: AppColors.mediumbrown,
            ),
            onPressed: () => Navigator.pop(context, _presets),
          ),
          title: Text(
            'Custom Timer',
            style: AppFonts.montserrat(size: 15, color: AppColors.mediumbrown),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scroll to set time:',
                        style: AppFonts.montserrat(
                          size: 14,
                          color: AppColors.lightbrown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 180,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _buildWheel(
                              controller: _hoursController,
                              count: 24,
                              suffix: 'h',
                              onChanged: (i) =>
                                  setState(() => _selectedHours = i),
                            ),
                            _buildWheel(
                              controller: _minutesController,
                              count: 60,
                              suffix: 'min',
                              onChanged: (i) =>
                                  setState(() => _selectedMinutes = i),
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
                            icon: const Icon(
                              Icons.add,
                              color: AppColors.background,
                            ),
                            label: Text(
                              'Add Preset',
                              style: AppFonts.manrope(
                                size: 16,
                                weight: FontWeight.w600,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                color: AppColors.lightbrown,
                indent: 24,
                endIndent: 24,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your Custom Presets:',
                    style: AppFonts.montserrat(
                      size: 14,
                      color: AppColors.lightbrown,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _presets.isEmpty
                    ? Center(
                        child: Text(
                          'No custom presets added yet.',
                          style: AppFonts.montserrat(
                            size: 13,
                            color: AppColors.lightbrown,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        itemCount: _presets.length,
                        itemBuilder: (context, index) {
                          final mins = _presets[index];
                          final hours = mins ~/ 60;
                          final rest = mins % 60;
                          final label = hours > 0
                              ? '${hours}h ${rest}m'
                              : '$mins Min';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label,
                                  style: AppFonts.manrope(
                                    size: 16,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.mediumbrown,
                                  ),
                                  onPressed: () => _removePreset(mins),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
