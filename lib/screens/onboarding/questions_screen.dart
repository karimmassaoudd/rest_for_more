import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_fonts.dart';
import '../../../../widgets/auth/auth_widgets.dart';

/// Onboarding part 1: a few optional questions for general statistics.
/// Every question can be left empty, and the whole screen can be skipped.
/// (The 14-day plan questionnaire is a separate flow, started later.)
///
/// TODO: store the answers locally (age band, goal, RestNest) — no date of
/// birth or free text (client doc 05: minimal data).
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  // Age bands, no date of birth (client doc 03).
  static const _ages = ['Under 16', '16–24', '25–39', '40–59', '60+'];
  // The three primary goals from client doc 03.
  static const _goals = [
    'Put my phone away earlier',
    'Build a calm routine',
    'Use less social media',
  ];
  static const _restNest = ['Yes', 'Not yet'];

  String? _age;
  String? _goal;
  String? _hasRestNest;

  void _next() => context.push('/onboarding/tutorial');

  @override
  Widget build(BuildContext context) {
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
            foregroundColor: AppColors.darkbrown,
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
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.cormorant(size: 22, weight: FontWeight.w600),
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
                    color: selected == option
                        ? AppColors.background
                        : AppColors.darkbrown,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.mediumbrown,
                  side: BorderSide(
                    color: selected == option
                        ? AppColors.mediumbrown
                        : AppColors.surface,
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
