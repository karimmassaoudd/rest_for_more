import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../common/rfm_logo.dart';

/// Top of the Home screen: greeting (+ first name) on the left, RFM logo on the right.
///
/// With a [firstName], the greeting is a small uppercase label above the name.
/// Without one (guest, offline, no name set), the greeting itself is the big title.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.firstName});

  final String? firstName;

  /// "Good morning" 05:00–11:59, "Good afternoon" 12:00–17:59, else "Good evening".
  static String greetingFor(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final greeting = greetingFor(DateTime.now());
    final name = firstName;
    final titleStyle = AppFonts.cormorant(
      size: 34,
      weight: FontWeight.w600,
      color: palette.text,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null) ...[
                Text(
                  greeting.toUpperCase(),
                  style: AppFonts.montserrat(
                    size: 12,
                    weight: FontWeight.w600,
                    color: palette.accent,
                  ).copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(name, style: titleStyle),
              ] else
                Text(greeting, style: titleStyle),
            ],
          ),
        ),
        RfmLogo(textColor: context.palette.muted),
      ],
    );
  }
}
