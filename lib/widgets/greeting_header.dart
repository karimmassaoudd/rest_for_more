import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';
import 'metadata_chip.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.period,
    required this.palette,
  });

  final RoutinePeriod period;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final isMorning = period == RoutinePeriod.morning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THURSDAY, SEPTEMBER 15',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text.rich(
                      key: ValueKey(period),
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${isMorning ? 'Good morning' : 'Good evening'},\n',
                          ),
                          const TextSpan(
                            text: 'Elena',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: palette.text,
                        fontFamily: 'serif',
                        fontSize: 37,
                        height: 1.03,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _WeatherPill(isMorning: isMorning, palette: palette),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetadataChip(
              icon: Icons.local_fire_department_rounded,
              label: '5-day streak',
              palette: palette,
            ),
            MetadataChip(
              icon: Icons.schedule_rounded,
              label: 'Total routine: 35 min',
              palette: palette,
            ),
          ],
        ),
      ],
    );
  }
}

class _WeatherPill extends StatelessWidget {
  const _WeatherPill({required this.isMorning, required this.palette});
  final bool isMorning;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
        boxShadow: isMorning
            ? const [
                BoxShadow(
                  color: Color(0x20D8A35F),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            size: 16,
            color: isMorning ? AppColors.amber : AppColors.eveningAmber,
          ),
          const SizedBox(width: 6),
          Text(
            isMorning ? '68°' : '62°',
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
