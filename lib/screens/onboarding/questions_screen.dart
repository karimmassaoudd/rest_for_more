import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/auth/auth_widgets.dart';

/// Onboarding step 2: a few optional questions for general statistics.
/// Every question can be left empty, and the whole screen can be skipped.
/// (The 14-day plan questionnaire is a separate flow, started later.)
///
/// TODO: store the answers locally or later in database (age band, goal, RestNest). Only these
/// choices, no date of birth or free text, to keep personal data minimal.
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  /// Age bands instead of a date of birth.
  static const _ages = ['Under 16', '16–24', '25–39', '40–59', '60+'];

  /// The three main goals the app supports.
  static const _goals = [
    'Put my phone away earlier',
    'Build a calm routine',
    'Use less social media',
  ];
  static const _restNest = ['Yes', 'Not yet'];

  String? _age;
  String? _goal;
  String? _hasRestNest;

  /// Continue and Skip do the same for now, because nothing is saved yet.
  void _next() => context.push('/onboarding/tutorial');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AuthScaffold(
      title: 'A few questions',
      subtitle: const Text('All optional. Skip any you like.'),
      primaryLabel: 'Continue',
      onPrimary: _next,
      footer: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _next,
          style: TextButton.styleFrom(
            foregroundColor: palette.text,
            textStyle: AppFonts.manrope(size: 14, weight: FontWeight.w600),
          ),
          child: const Text('Skip'),
        ),
      ),
      children: [
        _Question(
          title: 'How old are you?',
          options: _ages,
          selected: _age,
          onSelected: (v) => setState(() => _age = v),
        ),
        _Question(
          title: 'What would you like to change first?',
          options: _goals,
          selected: _goal,
          onSelected: (v) => setState(() => _goal = v),
        ),
        _Question(
          title: 'Do you have a RestNest?',
          options: _restNest,
          selected: _hasRestNest,
          onSelected: (v) => setState(() => _hasRestNest = v),
        ),
      ],
    );
  }
}

/// One question with tappable answer chips. Tapping the chosen answer
/// again clears it, so every question stays optional.
class _Question extends StatelessWidget {
  const _Question({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String? selected;

  /// Called with the tapped answer, or null when it was unselected.
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.cormorant(
              size: 22,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: selected == option,
                  showCheckmark: false,
                  onSelected: (on) => onSelected(on ? option : null),
                  labelStyle: AppFonts.manrope(
                    size: 14,
                    weight: FontWeight.w600,
                    color: selected == option ? palette.onAccent : palette.text,
                  ),
                  backgroundColor: palette.surface,
                  selectedColor: palette.accent,
                  side: BorderSide(
                    color: selected == option ? palette.accent : palette.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
