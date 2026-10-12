import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Cormorant Garamond: titles and big numbers
/// Manrope: body text and buttons
/// Montserrat: small labels, chips, navigation
class AppFonts {
  static TextStyle cormorant({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.darkbrown,
  }) => GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  static TextStyle manrope({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.darkbrown,
  }) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

  static TextStyle montserrat({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.darkbrown,
  }) =>
      GoogleFonts.montserrat(fontSize: size, fontWeight: weight, color: color);
}
