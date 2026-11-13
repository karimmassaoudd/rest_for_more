import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// Six boxes for the email code on the "Check your email" screen.
///
/// One invisible TextField does the actual typing, so pasting a code and
/// Android's one-time-code autofill both work. [onCompleted] is called
/// as soon as all six digits are in.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onCompleted,
    this.enabled = true,
  });

  final TextEditingController controller;

  /// Turns every box border red.
  final bool hasError;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  static const length = 6;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Redraw so the active box shows or hides its highlight.
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final code = widget.controller.text;
    if (code.length == CodeInput.length) widget.onCompleted?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final code = widget.controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          // Invisible field that receives the keyboard input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: CodeInput.length,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
          Semantics(
            label: '6-digit code, ${code.length} of 6 entered',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(CodeInput.length, (i) {
                final filled = i < code.length;
                // The box where the next digit will go.
                final active = _focus.hasFocus && i == code.length;

                return Container(
                  width: 46,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.hasError
                          ? AppColors.error
                          : active
                          ? palette.accent
                          : palette.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? code[i] : '',
                    style: AppFonts.manrope(
                      size: 20,
                      weight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
