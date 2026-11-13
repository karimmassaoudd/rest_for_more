import 'package:flutter/material.dart';

/// Content and colours for one card in the Home carousel.
///
/// Built in `home_carousel_cards.dart` from the current theme, so the
/// colours follow light/dark mode; drawn by `HomeCarouselCard`.
class HomeCard {
  const HomeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    required this.iconColor,
    required this.background,
    required this.textColor,
    required this.buttonColor,
    required this.buttonTextColor,
    this.iconSize = 24,
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

  /// Optional outline around the button.
  final Color? buttonBorder;
}
