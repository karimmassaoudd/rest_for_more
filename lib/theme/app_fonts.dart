import 'package:flutter/material.dart';

/// The three app fonts, bundled in assets/fonts (see pubspec.yaml), so
/// they show from the first frame and work offline.
///
/// - Cormorant Garamond: titles and big numbers.
/// - Manrope: body text and buttons.
/// - Montserrat: small labels, chips and navigation.
///
/// Without a `color`, text takes the theme's text colour, so it follows
/// light/dark mode by itself. Pass a colour only when it should differ.
class AppFonts {
  AppFonts._();

  static TextStyle cormorant({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  static TextStyle manrope({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  static TextStyle montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Montserrat',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}
