import 'package:flutter/material.dart';

/// One page of the onboarding tutorial: a big icon, a title and a short text.
class TutorialPage {
  const TutorialPage({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;
}
