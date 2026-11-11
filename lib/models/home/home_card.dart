import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Content and colours for one card in the Home carousel.
///
/// The default colours give the light card (sand background, brown button).
/// Pass other colours for variants such as the dark evening card.
class HomeCard {
  const HomeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.iconColor = AppColors.lightbrown,
    this.iconSize = 24,
    this.background = AppColors.surface,
    this.textColor = AppColors.darkbrown,
    this.buttonColor = AppColors.mediumbrown,
    this.buttonTextColor = AppColors.buttonText,
    this.buttonBorder,
  });

  /// Small icon in the top-left corner.
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  /// Small line above the title, e.g. "Ready to start the day?".
  final String eyebrow;

  /// Big serif title (max. 2 lines).
  final String title;

  final String buttonLabel;
  final VoidCallback onPressed;

  final Color background;
  final Color textColor;
  final Color buttonColor;
  final Color buttonTextColor;

  /// Optional outline around the button (used on the dark card).
  final Color? buttonBorder;
}
