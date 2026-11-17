import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import 'rfm_logo.dart';

/// Top bar for full-screen pages: back arrow + title on the left,
/// the RFM logo on the right.
///
/// The arrow and title use the main text colour (white in dark mode,
/// dark brown in light mode) unless [color] is given.
class RfmAppBar extends StatelessWidget {
  const RfmAppBar({
    super.key,
    required this.title,
    this.color,
    this.logoColor,
    this.onBack,
  });

  final String title;

  /// Back arrow + title. Defaults to `palette.text`.
  final Color? color;

  /// "RFM" text under the moon. Defaults to `palette.muted`.
  final Color? logoColor;

  /// Defaults to going back, or Home when there is nothing to go back to
  /// (for example when the page was opened from a notification).
  final VoidCallback? onBack;

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = color ?? palette.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkWell(
              key: const Key('rfm-app-bar-back'),
              onTap: onBack ?? () => _goBack(context),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.arrow_back, size: 25, color: foreground),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.montserrat(size: 15, color: foreground),
            ),
          ),
          RfmLogo(textColor: logoColor ?? palette.muted),
        ],
      ),
    );
  }
}

/// [RfmAppBar] for a Scaffold's `appBar:` slot.
PreferredSizeWidget rfmScaffoldAppBar({
  required String title,
  Color? color,
  Color? logoColor,
  VoidCallback? onBack,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(64),
    child: SafeArea(
      bottom: false,
      child: RfmAppBar(
        title: title,
        color: color,
        logoColor: logoColor,
        onBack: onBack,
      ),
    ),
  );
}
